// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";

contract BeanHeadsDiamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        BHStorage.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        BHStorage.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute
    // the function if a facet is found and return any value
    fallback() external payable {
        BHStorage.BeanHeadsStorage storage ds;

        bytes32 position = BHStorage.BH_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }

        // get facet from function selector
        address facet = ds.selectorToFacetPosition[msg.sig].facetAddress;
        // Execute external function from facet using delegatecall and return any value
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
