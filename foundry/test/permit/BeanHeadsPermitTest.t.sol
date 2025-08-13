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

    uint256 constant TOKEN_ID = 0;
    uint256 constant PRICE = 10 ether;

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
        bytes32 domain = beanHeads.DOMAIN_SEPARATOR();

        uint256 listingNonce = 0;
        uint256 permitNonce = beanHeads.nonces(TOKEN_ID) + 1;

        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        uint64 permitDeadline = uint64(block.timestamp + 1 hours);

        PermitTypes.Sell memory S = PermitTypes.Sell({
            owner: alice,
            tokenId: TOKEN_ID,
            price: PRICE,
            nonce: listingNonce,
            deadline: sellDeadline
        });

        bytes memory sellSig = _signSell(alicePk, domain, S);
        bytes memory permitSig =
            _signPermit4494(alicePk, domain, address(beanHeads), TOKEN_ID, permitNonce, permitDeadline);

        assertEq(beanHeads.getOwnerOf(TOKEN_ID), alice);

        address relayer = address(0x456);
        vm.startPrank(relayer);
        beanHeads.sellTokenWithPermit(S, sellSig, permitDeadline, permitSig);
        vm.stopPrank();

        assertEq(beanHeads.getOwnerOf(TOKEN_ID), address(beanHeads));

        (address seller, uint256 p, bool isActive) = beanHeads.getTokenSaleInfo(TOKEN_ID);
        assertEq(seller, alice);
        assertEq(p, PRICE);
        assertTrue(isActive);
    }

    function test_buyTokenWithPermit() public {
        // list first (isolated stack)
        _listWithPermit(alicePk, alice, TOKEN_ID, PRICE);

        // prepare buyer (isolated stack)
        (uint256 bobPk, address bob) = _newSigner("bob");
        mockERC20.mint(bob, 100 ether);
        vm.startPrank(bob);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        vm.stopPrank();

        // snap balances (keep locals minimal)
        (address royaltyReceiver, uint256 royaltyUsd) = royalty.royaltyInfo(TOKEN_ID, PRICE);
        uint256 buyerBefore = mockERC20.balanceOf(bob);
        uint256 sellerBefore = mockERC20.balanceOf(alice);

        // buy (isolated stack)
        _buyWithPermit(bobPk, bob, TOKEN_ID, PRICE);

        // post checks (isolated stack)
        assertEq(beanHeads.getOwnerOf(TOKEN_ID), bob);

        (address seller, uint256 p, bool isActive) = beanHeads.getTokenSaleInfo(TOKEN_ID);
        assertEq(seller, address(0));
        assertEq(p, 0);
        assertFalse(isActive);

        uint256 buyerAfter = mockERC20.balanceOf(bob);
        uint256 sellerAfter = mockERC20.balanceOf(alice);

        uint256 spent = buyerBefore - buyerAfter;
        uint256 sellerGain = sellerAfter - sellerBefore;

        uint256 receiverBalance = mockERC20.balanceOf(royaltyReceiver);

        // 6% royalty
        assertEq(spent, PRICE);
        assertEq(sellerGain, (PRICE * 9400) / 10000);
        assertEq(royaltyUsd, (PRICE * 600) / 10000);
        assertEq(receiverBalance, (PRICE * 600) / 10000);
    }

    function test_cancelTokenSaleWithPermit() public {
        bytes32 domain = beanHeads.DOMAIN_SEPARATOR();

        {
            uint256 listingNonce = 0;
            uint256 permitNonce = beanHeads.nonces(TOKEN_ID) + 1;
            uint64 sellDeadline = uint64(block.timestamp + 1 hours);
            uint64 permitDeadline = uint64(block.timestamp + 1 hours);

            PermitTypes.Sell memory S = PermitTypes.Sell({
                owner: alice,
                tokenId: TOKEN_ID,
                price: PRICE,
                nonce: listingNonce,
                deadline: sellDeadline
            });

            bytes memory sellSig = _signSell(alicePk, domain, S);
            bytes memory permitSig =
                _signPermit4494(alicePk, domain, address(beanHeads), TOKEN_ID, permitNonce, permitDeadline);

            vm.prank(address(0xAAA)); // Simulate a relayer
            beanHeads.sellTokenWithPermit(S, sellSig, permitDeadline, permitSig);

            (address seller, uint256 p, bool isActive) = beanHeads.getTokenSaleInfo(TOKEN_ID);
            assertEq(seller, alice);
            assertEq(p, PRICE);
            assertTrue(isActive);
            assertEq(beanHeads.getOwnerOf(TOKEN_ID), address(beanHeads)); // escrowed to the contract
        }

        // Now cancel the sale with permit
        {
            uint256 currentListingNonce = beanHeads.nonces(TOKEN_ID);
            uint64 cancelDeadline = uint64(block.timestamp + 1 hours);

            PermitTypes.Cancel memory C = PermitTypes.Cancel({
                seller: alice,
                tokenId: TOKEN_ID,
                listingNonce: currentListingNonce,
                deadline: cancelDeadline
            });

            bytes memory cancelSig = _signCancel(alicePk, domain, C);

            vm.prank(address(0xBBB)); // Simulate a relayer
            beanHeads.cancelTokenSaleWithPermit(C, cancelSig);

            (address sellerAfter, uint256 pAfter, bool isActiveAfter) = beanHeads.getTokenSaleInfo(TOKEN_ID);
            assertEq(sellerAfter, address(0));
            assertEq(pAfter, 0);
            assertFalse(isActiveAfter);
            assertEq(beanHeads.getOwnerOf(TOKEN_ID), alice); // ownership returned to Alice
        }
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    function _newSigner(string memory label) internal pure returns (uint256 pk, address addr) {
        pk = uint256(keccak256(abi.encodePacked(label)));
        addr = vm.addr(pk);
    }

    function _sign(uint256 pk, bytes32 digest) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        sig = abi.encodePacked(r, s, v);
    }

    // Helpers
    function _signSell(uint256 pk, bytes32 domain, PermitTypes.Sell memory S) internal pure returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain,
                keccak256(abi.encode(PermitTypes.SELL_TYPEHASH, S.owner, S.tokenId, S.price, S.nonce, S.deadline))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signBuy(uint256 pk, bytes32 domain, PermitTypes.Buy memory B) internal pure returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain,
                keccak256(
                    abi.encode(
                        PermitTypes.BUY_TYPEHASH,
                        B.buyer,
                        B.paymentToken,
                        B.recipient,
                        B.tokenId,
                        B.maxPriceUsd,
                        B.listingNonce,
                        B.deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signPermit4494(
        uint256 pk,
        bytes32 domain,
        address spender,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain,
                keccak256(
                    abi.encode(
                        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                        spender,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signCancel(uint256 pk, bytes32 domain, PermitTypes.Cancel memory C)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain,
                keccak256(abi.encode(PermitTypes.CANCEL_TYPEHASH, C.seller, C.tokenId, C.listingNonce, C.deadline))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _listWithPermit(uint256 userPk, address owner, uint256 tokenId, uint256 price) internal {
        bytes32 domain = beanHeads.DOMAIN_SEPARATOR();

        uint256 listingNonce = 0;
        uint256 permitNonce = beanHeads.nonces(tokenId) + 1;
        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        uint64 permitDeadline = uint64(block.timestamp + 1 hours);

        PermitTypes.Sell memory S = PermitTypes.Sell({
            owner: owner,
            tokenId: tokenId,
            price: price,
            nonce: listingNonce,
            deadline: sellDeadline
        });

        bytes memory sellSig = _signSell(userPk, domain, S);
        bytes memory permitSig =
            _signPermit4494(userPk, domain, address(beanHeads), tokenId, permitNonce, permitDeadline);

        vm.prank(address(0x456));
        beanHeads.sellTokenWithPermit(S, sellSig, permitDeadline, permitSig);

        (address sellerAddr, uint256 sellerPrice, bool active) = beanHeads.getTokenSaleInfo(tokenId);
        assertEq(sellerAddr, owner);
        assertEq(sellerPrice, price);
        assertTrue(active);
        assertEq(beanHeads.getOwnerOf(tokenId), address(beanHeads));
    }

    function _buyWithPermit(uint256 bobPk, address bob, uint256 tokenId, uint256 price) internal {
        bytes32 domain = beanHeads.DOMAIN_SEPARATOR();

        uint256 listingNonceForBuy = beanHeads.nonces(tokenId);
        uint64 buyDeadline = uint64(block.timestamp + 1 hours);

        PermitTypes.Buy memory B = PermitTypes.Buy({
            buyer: bob,
            paymentToken: address(mockERC20),
            recipient: bob,
            tokenId: tokenId,
            maxPriceUsd: price,
            listingNonce: listingNonceForBuy,
            deadline: buyDeadline
        });

        bytes memory buySig = _signBuy(bobPk, domain, B);

        vm.prank(address(0x999)); // relayer
        beanHeads.buyTokenWithPermit(B, buySig, type(uint256).max, buyDeadline, 0, bytes32(0), bytes32(0));
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }
}
