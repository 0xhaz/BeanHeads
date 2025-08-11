// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {BeanHeadsRoyalty} from "src/core/BeanHeadsRoyalty.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {DeployBeanHeads, HelperConfig} from "script/DeployBeanHeads.s.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {IBeanHeadsMarketplace} from "src/interfaces/IBeanHeadsMarketplace.sol";
import {IBeanHeadsMint} from "src/interfaces/IBeanHeadsMint.sol";
import {IBeanHeadsView} from "src/interfaces/IBeanHeadsView.sol";
import {IBeanHeadsBreeding} from "src/interfaces/IBeanHeadsBreeding.sol";
import {IBeanHeadsAdmin} from "src/interfaces/IBeanHeadsAdmin.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {ERC721PermitBase, IERC721Permit, ECDSA} from "src/abstracts/ERC721PermitBase.sol";
import {Vm} from "forge-std/Vm.sol";

contract BeanHeadsPermitTest is Test, ERC721PermitBase, Helpers {
    IBeanHeads beanHeads;
    BeanHeadsRoyalty royalty;
    MockERC20 mockERC20;
    DeployBeanHeads deployBeanHeads;
    HelperConfig helperConfig;

    Helpers helpers;

    address alice;
    uint256 alicePk;
    uint256 public MINT_PRICE;
    AggregatorV3Interface priceFeed;
    uint8 tokenDecimals;
    address deployerAddress;

    bytes32 SELL_TYPEHASH;

    function setUp() public {
        helpers = new Helpers();
        helperConfig = new HelperConfig();
        mockERC20 = new MockERC20(1000000 ether);

        address usdcPriceFeed = helperConfig.getActiveNetworkConfig().usdPriceFeed;
        priceFeed = AggregatorV3Interface(usdcPriceFeed);
        tokenDecimals = mockERC20.decimals();

        (alicePk, alice) = _newSigner("alice");
        SELL_TYPEHASH = PermitTypes.SELL_TYPEHASH;

        // vm.startPrank(DEPLOYER);
        deployBeanHeads = new DeployBeanHeads();
        (address beanHeadsAddress,) = deployBeanHeads.run();
        beanHeads = IBeanHeads(beanHeadsAddress);

        mockERC20.approve(address(beanHeads), type(uint256).max); // Approve BeanHeads to spend mock ERC20 tokens

        deployerAddress = vm.addr(helperConfig.getActiveNetworkConfig().deployerKey);
        vm.startPrank(deployerAddress);
        beanHeads.setAllowedToken(address(mockERC20), true); // Allow mock ERC20 token for minting
        beanHeads.setMintPrice(1 * 1e18); // Set mint price to 0.01 ether
        beanHeads.addPriceFeed(address(mockERC20), usdcPriceFeed); // Add mock ERC20 price feed

        royalty = deployBeanHeads.royalty();
        royalty.setRoyaltyInfo(600); // Set royalty to 6%
        vm.stopPrank();

        MINT_PRICE = beanHeads.getMintPrice();

        vm.startPrank(alice);
        mockERC20.mint(alice, 100 ether);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        beanHeads.mintGenesis(alice, params, 1, address(mockERC20)); // Mint 1 token for Alice
        vm.stopPrank();
    }

    function test_sellTokenWithPermit() public {
        uint256 tokenId = 0;
        uint256 price = 10 ether;

        uint256 listingNonce = 0;
        uint256 permitNonce = beanHeads.nonces(tokenId) + 1;

        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        uint64 permitDeadline = uint64(block.timestamp + 1 hours);

        PermitTypes.Sell memory S = PermitTypes.Sell({
            owner: alice,
            tokenId: tokenId,
            price: price,
            nonce: listingNonce,
            deadline: sellDeadline
        });

        bytes32 domain = beanHeads.DOMAIN_SEPARATOR();

        // --- sellSig (SELL_TYPEHASH) ---
        bytes32 sellStructHash = keccak256(abi.encode(SELL_TYPEHASH, S.owner, S.tokenId, S.price, S.nonce, S.deadline));
        bytes32 sellDigest = keccak256(abi.encodePacked("\x19\x01", domain, sellStructHash));
        (uint8 sv, bytes32 sr, bytes32 ss) = vm.sign(alicePk, sellDigest);
        bytes memory sellSig = abi.encodePacked(sr, ss, sv);

        // --- permitSig (ERC-4494) ---
        bytes32 permitStructHash = keccak256(
            abi.encode(
                keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                address(beanHeads), // spender is this contract
                tokenId,
                permitNonce,
                permitDeadline
            )
        );
        bytes32 permitDigest = keccak256(abi.encodePacked("\x19\x01", domain, permitStructHash));
        (uint8 pv, bytes32 pr, bytes32 ps) = vm.sign(alicePk, permitDigest);
        bytes memory permitSig = abi.encodePacked(pr, ps, pv);

        assertEq(beanHeads.getOwnerOf(tokenId), alice);

        address relayer = address(0x456);
        vm.startPrank(relayer);
        beanHeads.sellTokenWithPermit(S, sellSig, permitDeadline, permitSig);
        vm.stopPrank();

        assertEq(beanHeads.getOwnerOf(tokenId), address(beanHeads));

        (address seller, uint256 p, bool isActive) = beanHeads.getTokenSaleInfo(tokenId);
        assertEq(seller, alice);
        assertEq(p, price);
        assertTrue(isActive);
    }

    // -------------------
    // Helpers
    // -------------------
    function _newSigner(string memory label) internal pure returns (uint256 pk, address addr) {
        pk = uint256(keccak256(abi.encodePacked(label)));
        addr = vm.addr(pk);
    }

    function _sign(uint256 pk, bytes32 digest) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        sig = abi.encodePacked(r, s, v);
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }
}
