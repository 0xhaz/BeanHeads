// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsView} from "src/interfaces/IBeanHeadsView.sol";
import {IBeanHeadsAdmin} from "src/interfaces/IBeanHeadsAdmin.sol";
import {IBeanHeadsMarketplace} from "src/interfaces/IBeanHeadsMarketplace.sol";
import {IBeanHeadsMarketplaceSig} from "src/interfaces/IBeanHeadsMarketplaceSig.sol";
import {IBeanHeadsMint} from "src/interfaces/IBeanHeadsMint.sol";
import {IBeanHeadsBreeding} from "src/interfaces/IBeanHeadsBreeding.sol";
import {IERC721Permit} from "src/interfaces/IERC721Permit.sol";

interface IBeanHeads is
    IBeanHeadsView,
    IBeanHeadsAdmin,
    IBeanHeadsMarketplace,
    IBeanHeadsMarketplaceSig,
    IBeanHeadsMint,
    IBeanHeadsBreeding,
    IERC721Permit
{}
