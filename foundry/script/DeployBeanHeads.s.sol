// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsDiamond} from "src/BeanHeadsDiamond.sol";
import {DiamondInit} from "src/updateInitializers/DiamondInit.sol";
import {DiamondCutFacet, IDiamondCut} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet, IDiamondLoupe} from "src/facets/DiamondLoupeFacet.sol";
import {BeanHeadsMintFacet} from "src/facets/BeanHeads/BeanHeadsMintFacet.sol";
import {BeanHeadsViewFacet} from "src/facets/BeanHeads/BeanHeadsViewFacet.sol";
import {BeanHeadsBreedingFacet} from "src/facets/BeanHeads/BeanHeadsBreedingFacet.sol";
import {BeanHeadsMarketplaceFacet} from "src/facets/BeanHeads/BeanHeadsMarketplaceFacet.sol";
import {BeanHeadsMarketplaceSigFacet} from "src/facets/BeanHeads/BeanHeadsMarketplaceSigFacet.sol";
import {BeanHeadsAdminFacet} from "src/facets/BeanHeads/BeanHeadsAdminFacet.sol";
import {OwnershipFacet, IERC173} from "src/facets/OwnershipFacet.sol";
import {IERC165} from "src/interfaces/IERC165.sol";
import {BeanHeadsRoyalty} from "src/core/BeanHeadsRoyalty.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBeanHeads is Script {
    uint96 public ROYALTY_FEE_BPS = 500; // 5% royalty fee in basis points
    BeanHeadsRoyalty public royalty;

    function run() public returns (address, address) {
        HelperConfig helperConfig = new HelperConfig();
        (HelperConfig.NetworkConfig memory config,,) = helperConfig.getActiveNetworkConfig();

        address deployerAddress = vm.addr(config.deployerKey);
        address priceFeed = config.usdPriceFeed;

        vm.startBroadcast(config.deployerKey);
        royalty = new BeanHeadsRoyalty(deployerAddress, ROYALTY_FEE_BPS);

        //    Deploy the DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        // Deploy base Diamond with the DiamondCutFacet
        BeanHeadsDiamond diamond = new BeanHeadsDiamond(deployerAddress, address(diamondCutFacet));

        // Prepare the facets to be added
        /// 1. BeanHeadsAdminFacet
        /// 2. BeanHeadsBreedingFacet
        /// 3. BeanHeadsMarketplaceFacet
        /// 4. BeanHeadsMarketplaceSigFacet
        /// 5. BeanHeadsMintFacet
        /// 6. BeanHeadsViewFacet
        /// 7. DiamondLoupeFacet
        /// 8. OwnershipFacet
        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](8);
        uint256 i = 0;
        // ---------------------- Admin Facet ----------------------
        {
            BeanHeadsAdminFacet facet = new BeanHeadsAdminFacet();
            bytes4[] memory selectors = new bytes4[](6);
            selectors[0] = facet.setAllowedToken.selector;
            selectors[1] = facet.addPriceFeed.selector;
            selectors[2] = facet.withdraw.selector;
            selectors[3] = facet.authorizeBreeder.selector;
            selectors[4] = facet.setMintPrice.selector;
            selectors[5] = facet.setRemoteBridge.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- Breeding Facet ----------------------
        {
            BeanHeadsBreedingFacet facet = new BeanHeadsBreedingFacet();
            bytes4[] memory selectors = new bytes4[](7);
            selectors[0] = facet.mintFromBreeders.selector;
            selectors[1] = facet.getAuthorizedBreeders.selector;
            selectors[2] = facet.getMintPrice.selector;
            selectors[3] = facet.burn.selector;
            selectors[4] = facet.getGeneration.selector;
            selectors[5] = facet.getOwnerTokens.selector;
            selectors[6] = facet.getPriceFeed.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- Marketplace Facet ----------------------
        {
            BeanHeadsMarketplaceFacet facet = new BeanHeadsMarketplaceFacet();
            bytes4[] memory selectors = new bytes4[](12);
            selectors[0] = facet.sellToken.selector;
            selectors[1] = facet.buyToken.selector;
            selectors[2] = facet.cancelTokenSale.selector;
            selectors[3] = facet.onERC721Received.selector;
            selectors[4] = facet.getTokenSalePrice.selector;
            selectors[5] = facet.isTokenForSale.selector;
            selectors[6] = facet.isTokenAllowed.selector;
            selectors[7] = facet.getTokenSaleInfo.selector;
            selectors[8] = facet.batchBuyTokens.selector;
            selectors[9] = facet.batchSellTokens.selector;
            selectors[10] = facet.batchCancelTokenSales.selector;
            selectors[11] = facet.getAllActiveSaleTokens.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- Marketplace With Signature Facet ----------------------
        {
            BeanHeadsMarketplaceSigFacet facet = new BeanHeadsMarketplaceSigFacet();
            bytes4[] memory selectors = new bytes4[](9);
            selectors[0] = facet.sellTokenWithPermit.selector;
            selectors[1] = facet.buyTokenWithPermit.selector;
            selectors[2] = facet.cancelTokenSaleWithPermit.selector;
            selectors[3] = facet.permit.selector;
            selectors[4] = facet.nonces.selector;
            selectors[5] = facet.eip712Domain.selector;
            selectors[6] = facet.DOMAIN_SEPARATOR.selector;
            selectors[7] = facet.batchSellTokensWithPermit.selector;
            selectors[8] = facet.batchCancelTokenSalesWithPermit.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }

        // ---------------------- Mint Facet ----------------------
        {
            BeanHeadsMintFacet facet = new BeanHeadsMintFacet();
            bytes4[] memory selectors = new bytes4[](14);
            selectors[0] = facet.mintGenesis.selector;
            selectors[1] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
            selectors[2] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
            selectors[3] = facet.approve.selector;
            selectors[4] = facet.name.selector;
            selectors[5] = facet.symbol.selector;
            selectors[6] = facet.balanceOf.selector;
            selectors[7] = facet.getNextTokenId.selector;
            selectors[8] = facet.getOwnerOf.selector;
            selectors[9] = facet.mintBridgeToken.selector;
            selectors[10] = facet.unlockToken.selector;
            selectors[11] = facet.lockToken.selector;
            selectors[12] = facet.burnToken.selector;
            selectors[13] = facet.getTotalSupply.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- View Facet ----------------------
        {
            BeanHeadsViewFacet facet = new BeanHeadsViewFacet();
            bytes4[] memory selectors = new bytes4[](10);
            selectors[0] = facet.tokenURI.selector;
            selectors[1] = facet.getAttributesByTokenId.selector;
            selectors[2] = facet.getAttributesByOwner.selector;
            selectors[3] = facet.getAttributes.selector;
            selectors[4] = facet.exists.selector;
            selectors[5] = facet.getOwnerTokensCount.selector;
            selectors[6] = facet.isBridgeAuthorized.selector;
            selectors[7] = facet.isTokenLocked.selector;
            selectors[8] = facet.getOriginChainId.selector;
            selectors[9] = facet.getOwnedTokenIds.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- Diamond Loupe Facet ----------------------
        {
            DiamondLoupeFacet facet = new DiamondLoupeFacet();
            bytes4[] memory selectors = new bytes4[](5);
            selectors[0] = IDiamondLoupe.facets.selector;
            selectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
            selectors[2] = IDiamondLoupe.facetAddresses.selector;
            selectors[3] = IDiamondLoupe.facetAddress.selector;
            selectors[4] = IERC165.supportsInterface.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }
        // ---------------------- Ownership Facet ----------------------
        {
            OwnershipFacet facet = new OwnershipFacet();
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = IERC173.transferOwnership.selector;
            selectors[1] = IERC173.owner.selector;
            diamondCut[i++] = IDiamondCut.FacetCut(address(facet), IDiamondCut.FacetCutAction.Add, selectors);
        }

        DiamondInit diamondInit = new DiamondInit();
        bytes memory initCallData = abi.encodeWithSelector(
            diamondInit.init.selector,
            address(royalty), // Royalty contract address
            priceFeed // Price feed address
        );

        IDiamondCut(address(diamond)).diamondCut(
            diamondCut,
            address(diamondInit), // Address of the init contract
            initCallData // Call data to initialize the diamond
        );

        vm.stopBroadcast();

        console.log("BeanHeads Diamond deployed at:", address(diamond));
        console.log("Royalty contract deployed at:", address(royalty));

        vm.startBroadcast(deployerAddress);

        BeanHeadsAdminFacet adminFacet = BeanHeadsAdminFacet(address(diamond));

        if (block.chainid == helperConfig.ETH_SEPOLIA_CHAIN_ID()) {
            adminFacet.setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            adminFacet.setAllowedToken(helperConfig.SEPOLIA_USDC(), true);
            console.log("Sepolia USDC allowed:", helperConfig.SEPOLIA_USDC());
            adminFacet.addPriceFeed(helperConfig.SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Sepolia USDC price feed added:", config.usdPriceFeed);
        } else if (block.chainid == helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID()) {
            adminFacet.setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            adminFacet.setAllowedToken(helperConfig.OP_SEPOLIA_USDC(), true);
            console.log("Optimism Sepolia USDC allowed:", helperConfig.OP_SEPOLIA_USDC());
            adminFacet.addPriceFeed(helperConfig.OP_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Optimism Sepolia USDC price feed added:", config.usdPriceFeed);
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            adminFacet.setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            adminFacet.setAllowedToken(helperConfig.ARBITRUM_SEPOLIA_USDC(), true);
            console.log("Arbitrum Sepolia USDC allowed:", helperConfig.ARBITRUM_SEPOLIA_USDC());
            adminFacet.addPriceFeed(helperConfig.ARBITRUM_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Arbitrum Sepolia USDC price feed added:", config.usdPriceFeed);
        }

        vm.stopBroadcast();

        return (address(diamond), address(royalty));
    }
}
