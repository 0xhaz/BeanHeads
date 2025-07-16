// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2Plus} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {ConfirmedOwner} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFCoordinatorV2_5} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IERC721A} from "ERC721A/IERC721A.sol";
import {ConfirmedOwner} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {IBeanHeadsBreeder} from "src/interfaces/IBeanHeadsBreeder.sol";
import {Genesis} from "src/types/Genesis.sol";

/**
 * @title BeanHeadsBreeder
 * @notice This contract allows users to breed BeanHeads by requesting random attributes from Chainlink VRF.
 * It extends the VRFConsumerBaseV2 to handle randomness requests and fulfillments.
 * Only user that has Gen1 BeanHeads can breed new BeanHeads.
 */
contract BeanHeadsBreeder is VRFConsumerBaseV2Plus, IBeanHeadsBreeder {
    /*//////////////////////////////////////////////////////////////
                              GLOBAL STATE
    //////////////////////////////////////////////////////////////*/
    IBeanHeads private immutable i_beanHeads;
    // Chainlink VRF parameters
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private constant GAS_LIMIT = 500_000; // Gas limit for the VRF callback
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations for the VRF request
    uint256 private BREED_COOL_DOWN = 50; // Cool down period for breeding requests
    uint256 private constant MAX_BREED_REQUESTS = 5; // Maximum number of breed requests per user
    uint256 private constant MINT_PRICE = 0.01 ether; // Minting price for breeding

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    /// @notice Mapping to store the breed requests
    mapping(uint256 requestId => BreedRequest) public s_breedRequests;

    /// @notice Mapping of parent tokenId => owner that will be sent to the contract
    mapping(uint256 tokenId => address owner) public s_escrowedTokens;

    /// @notice Mapping of rarity points to the Mutated BeanHead
    mapping(uint256 tokenId => uint256 rarityPoints) public s_mutatedRarityPoints;

    /// @notice Mapping of the last breeding block
    mapping(address owner => uint256 lastBreedingBlock) public s_lastBreedingBlock;

    /// @notice Mapping of each parent used in breeding
    mapping(uint256 tokenId => uint256 count) public s_parentBreedingCount;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _owner, address _beanHeads, address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        i_beanHeads = IBeanHeads(_beanHeads);
        s_vrfCoordinator = VRFCoordinatorV2_5(_vrfCoordinator);
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
        transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Inherits from IBeanHeadsBreeder
    function depositBeanHeads(uint256 tokenId) public override {
        // Ensure the token is a valid BeanHead
        if (!i_beanHeads.exists(tokenId)) {
            revert IBeanHeadsBreeder__InvalidTokenId();
        }
        // Ensure the sender is the owner of the token
        if (i_beanHeads.getOwnerOf(tokenId) != msg.sender) {
            revert IBeanHeadsBreeder__NotOwner();
        }

        // Transfer the BeanHeads to this contract
        i_beanHeads.safeTransferFrom(msg.sender, address(this), tokenId);

        // Save ownership information
        s_escrowedTokens[tokenId] = msg.sender;

        // Emit an event for the deposit
        emit BeanHeadsDeposited(msg.sender, tokenId);
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function withdrawBeanHeads(uint256 tokenId) public override {
        address owner = s_escrowedTokens[tokenId];
        if (owner != msg.sender) {
            revert IBeanHeadsBreeder__TokensNotEscrowedBySender();
        }

        // Clear the ownership mapping
        delete s_escrowedTokens[tokenId];

        // Transfer the BeanHead back to the owner
        i_beanHeads.safeTransferFrom(address(this), msg.sender, tokenId);

        emit BeanHeadsWithdrawn(msg.sender, tokenId);
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function requestBreed(uint256 parent1Id, uint256 parent2Id, BreedingMode mode)
        public
        payable
        override
        returns (uint256 requestId)
    {
        if (mode == BreedingMode.Ascension) {
            // For Ascension, only parent1Id is used, parent2Id is ignored
            if (parent2Id != 0) revert IBeanHeadsBreeder__InvalidRequestId();
            if (s_escrowedTokens[parent1Id] != msg.sender) revert IBeanHeadsBreeder__TokensNotEscrowedBySender();
        } else {
            if (parent1Id == parent2Id) revert IBeanHeadsBreeder__CannotBreedSameBeanHead();
            if (s_escrowedTokens[parent1Id] != msg.sender || s_escrowedTokens[parent2Id] != msg.sender) {
                revert IBeanHeadsBreeder__TokensNotEscrowedBySender();
            }
        }

        if (msg.value < MINT_PRICE) {
            revert IBeanHeadsBreeder__InsufficientPayment();
        }

        // Check if the pairing parents have already been used in breeding
        if (
            s_parentBreedingCount[parent1Id] >= MAX_BREED_REQUESTS
                || s_parentBreedingCount[parent2Id] >= MAX_BREED_REQUESTS
        ) {
            revert IBeanHeadsBreeder__BreedLimitReached();
        }

        // Check if the user has already requested a breed in the last BREED_COOL_DOWN blocks
        if (s_lastBreedingBlock[msg.sender] + BREED_COOL_DOWN > block.number) {
            revert IBeanHeadsBreeder__CoolDownNotPassed();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: GAS_LIMIT,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        s_breedRequests[requestId] =
            BreedRequest({owner: msg.sender, parent1Id: parent1Id, parent2Id: parent2Id, mode: mode});

        // Update the last breeding block for the user
        s_lastBreedingBlock[msg.sender] = block.number;

        // Increment the breeding count for the parents
        s_parentBreedingCount[parent1Id]++;
        s_parentBreedingCount[parent2Id]++;

        emit RequestBreed(msg.sender, parent1Id, parent2Id, requestId, mode);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setCoolDown(uint256 coolDown) external onlyOwner {
        BREED_COOL_DOWN = coolDown;
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function getRarityPoints(uint256 tokenId) external view override returns (uint256) {
        return s_mutatedRarityPoints[tokenId];
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function getBreedRequest(uint256 requestId) external view override returns (BreedRequest memory request) {
        request = s_breedRequests[requestId];
        if (request.owner == address(0)) revert IBeanHeadsBreeder__InvalidRequestId();
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function getEscrowedTokenOwner(uint256 tokenId) external view override returns (address owner) {
        owner = s_escrowedTokens[tokenId];
        if (owner == address(0)) revert IBeanHeadsBreeder__InvalidRequestId();
    }

    /// @notice Inherits from IBeanHeadsBreeder
    function getParentBreedingCount(uint256 tokenId) external view override returns (uint256 count) {
        count = s_parentBreedingCount[tokenId];
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = payable(msg.sender).call{value: balance}("");
            if (!success) revert IBeanHeadsBreeder__TransferFailed();
        }
    }

    receive() external payable {}
    fallback() external payable {}

    /*//////////////////////////////////////////////////////////////
                           CALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Callback function that is called when a BeanHead is transferred to this contract.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Callback function that is called by Chainlink VRF to fulfill the random words request.
     * @param requestId The ID of the request.
     * @param randomWords The array of random words returned by Chainlink VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        BreedRequest memory request = s_breedRequests[requestId];
        if (request.owner == address(0)) revert IBeanHeadsBreeder__InvalidRequestId();

        Genesis.SVGParams memory childParams = _randomizeAttributes(randomWords[0]);

        delete s_breedRequests[requestId];

        uint256 newTokenId;
        if (request.mode == BreedingMode.NewBreed) {
            newTokenId = _handleNewBreed(request, requestId, childParams, randomWords[0]);
        }

        if (request.mode == BreedingMode.Mutation) {
            newTokenId = _handleMutation(request, requestId, childParams, randomWords[0]);
        }

        if (request.mode == BreedingMode.Fusion) {
            newTokenId = _handleFusion(request, requestId, childParams, randomWords[0]);
        }

        if (request.mode == BreedingMode.Ascension) {
            newTokenId = _handleAscension(request, requestId, childParams, randomWords[0]);
        }

        emit BreedRequestFulfilled(request.owner, requestId, request.mode, newTokenId);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint new Generation of BeanHead with randomized attributes.
     * @param request The breed request containing the parent IDs and owner address.
     * @param requestId The Chainlink VRF request ID.
     * @param childParams The randomized SVG parameters for the new BeanHead.
     * @param randomWords The random words returned by Chainlink VRF.
     */
    function _handleNewBreed(
        BreedRequest memory request,
        uint256 requestId,
        Genesis.SVGParams memory childParams,
        uint256 randomWords
    ) private returns (uint256) {
        // Non-destructive breeding, both parents remain intact
        uint256 gen1 = i_beanHeads.getGeneration(request.parent1Id);
        uint256 gen2 = i_beanHeads.getGeneration(request.parent2Id);
        uint256 childGen = (gen1 > gen2 ? gen1 : gen2) + 1;

        // Mint the new BeanHead with the randomized attributes
        uint256 newTokenId = i_beanHeads.mintFromBreeders(request.owner, childParams, childGen);

        // Store the rarity points for the new BeanHead
        uint256 rarityPoints =
            _calculateRarity(request.parent1Id, request.parent2Id, gen1, gen2, randomWords, request.mode);
        s_mutatedRarityPoints[newTokenId] = rarityPoints;

        // Return parents to the owner
        i_beanHeads.safeTransferFrom(address(this), request.owner, request.parent1Id);
        i_beanHeads.safeTransferFrom(address(this), request.owner, request.parent2Id);

        emit NewBreedCompleted(
            request.owner, requestId, request.parent1Id, request.parent2Id, newTokenId, childGen, rarityPoints
        );

        return newTokenId;
    }

    /**
     * @notice Handles the mutation breeding mode.
     * In this mode, one parent is mutated into a new BeanHead, and the other parent is returned to the owner.
     * @param request The breed request containing the parent IDs and owner address.
     * @param requestId The Chainlink VRF request ID.
     * @param childParams The randomized SVG parameters for the new BeanHead.
     * @param randomWords The random words returned by Chainlink VRF.
     */
    function _handleMutation(
        BreedRequest memory request,
        uint256 requestId,
        Genesis.SVGParams memory childParams,
        uint256 randomWords
    ) private returns (uint256) {
        // Destructive breeding, one parent is mutated into a new BeanHead
        uint256 childGen = i_beanHeads.getGeneration(request.parent1Id) + 1;

        // Mint the new BeanHead with the randomized attributes
        uint256 newTokenId = i_beanHeads.mintFromBreeders(request.owner, childParams, childGen);

        // Get the generation of the parents
        uint256 gen1 = i_beanHeads.getGeneration(request.parent1Id);
        uint256 gen2 = i_beanHeads.getGeneration(request.parent2Id);

        // Store the rarity points for the mutated BeanHead
        uint256 rarityPoints =
            _calculateRarity(request.parent1Id, request.parent2Id, gen1, gen2, randomWords, request.mode);

        // Store the rarity points for the mutated BeanHead
        s_mutatedRarityPoints[newTokenId] = rarityPoints;

        // Return the second parent to the owner
        i_beanHeads.safeTransferFrom(address(this), request.owner, request.parent2Id);

        // Burn the first parent
        i_beanHeads.burn(request.parent1Id);

        emit MutationCompleted(
            request.owner, requestId, request.parent1Id, request.parent2Id, newTokenId, childGen, rarityPoints
        );

        return newTokenId;
    }

    /**
     * @notice Handles the fusion breeding mode.
     * In this mode, both parents are burned, and a new BeanHead is created with randomized attributes.
     * @param request The breed request containing the parent IDs and owner address.
     * @param requestId The Chainlink VRF request ID.
     * @param childParams The randomized SVG parameters for the new BeanHead.
     * @param randomWords The random words returned by Chainlink VRF.
     */
    function _handleFusion(
        BreedRequest memory request,
        uint256 requestId,
        Genesis.SVGParams memory childParams,
        uint256 randomWords
    ) private returns (uint256) {
        // Fusion breeding, both parents are burned and a new BeanHead is created
        uint256 gen1 = i_beanHeads.getGeneration(request.parent1Id);
        uint256 gen2 = i_beanHeads.getGeneration(request.parent2Id);
        uint256 childGen = (gen1 > gen2 ? gen1 : gen2) + 1;

        // Mint the new BeanHead with the randomized attributes
        uint256 newTokenId = i_beanHeads.mintFromBreeders(request.owner, childParams, childGen);

        // Store the rarity points for the mutated BeanHead
        uint256 rarityPoints =
            _calculateRarity(request.parent1Id, request.parent2Id, gen1, gen2, randomWords, request.mode);

        s_mutatedRarityPoints[newTokenId] = rarityPoints;

        // Burn both parents
        i_beanHeads.burn(request.parent1Id);
        i_beanHeads.burn(request.parent2Id);

        emit FusionCompleted(
            request.owner, requestId, request.parent1Id, request.parent2Id, newTokenId, childGen, rarityPoints
        );

        return newTokenId;
    }

    /**
     * @notice Handles the ascension breeding mode.
     * In this mode, the first parent is burned, and a new BeanHead is created with randomized attributes.
     * @param request The breed request containing the parent IDs and owner address.
     * @param requestId The Chainlink VRF request ID.
     * @param childParams The randomized SVG parameters for the new BeanHead.
     * @param randomWords The random words returned by Chainlink VRF.
     */
    function _handleAscension(
        BreedRequest memory request,
        uint256 requestId,
        Genesis.SVGParams memory childParams,
        uint256 randomWords
    ) private returns (uint256) {
        // Ascension breeding, only parent1Id is used
        uint256 gen1 = i_beanHeads.getGeneration(request.parent1Id);
        uint256 childGen = gen1 + 1;

        // Mint the new BeanHead with the randomized attributes
        uint256 newTokenId = i_beanHeads.mintFromBreeders(request.owner, childParams, childGen);

        // Store the rarity points for the ascended BeanHead
        uint256 rarityPoints = _calculateRarity(request.parent1Id, 0, gen1, 0, randomWords, request.mode);
        s_mutatedRarityPoints[newTokenId] = rarityPoints;

        // Burn the parent
        i_beanHeads.burn(request.parent1Id);

        emit AscensionCompleted(request.owner, requestId, request.parent1Id, newTokenId, childGen, rarityPoints);

        // Return the new token ID
        return newTokenId;
    }

    /**
     * @notice Calculates the rarity points for a mutated BeanHead based on the parent IDs and randomness.
     * @param parent1Id The token ID of the first parent BeanHead.
     * @param parent2Id The token ID of the second parent BeanHead.
     * @param gen1 The generation of the first parent BeanHead.
     * @param gen2 The generation of the second parent BeanHead.
     * @param randomness The random number provided by Chainlink VRF.
     * @return rarityPoints The calculated rarity points for the new BeanHead.
     */
    function _calculateRarity(
        uint256 parent1Id,
        uint256 parent2Id,
        uint256 gen1,
        uint256 gen2,
        uint256 randomness,
        BreedingMode mode
    ) private pure returns (uint256 rarityPoints) {
        if (mode == BreedingMode.NewBreed) {
            uint256 baseGeneration = (gen1 + gen2) * 10; // Base rarity points based on the generation of the parents

            uint256 generationGapBonus;

            if (gen1 != gen2) {
                generationGapBonus = 20; // Bonus for different generations
            }

            uint256 uniquePairing = uint256(keccak256(abi.encodePacked(parent1Id, parent2Id))) % 30; // Unique pairing bonus based on the parent IDs
            uint256 randomLuck = randomness % 30; // Random luck factor

            rarityPoints = baseGeneration + generationGapBonus + uniquePairing + randomLuck + 10;
        }

        if (mode == BreedingMode.Mutation) {
            uint256 baseGeneration = (gen1 * 30) + (gen2 * 20) + (gen1 * gen2 * 10);
            uint256 uniquePairing = uint256(keccak256(abi.encodePacked(parent1Id, parent2Id))) % 40;
            uint256 randomLuck = randomness % 40;
            rarityPoints = baseGeneration + uniquePairing + randomLuck + 20;
        }

        if (mode == BreedingMode.Fusion) {
            uint256 baseGeneration = (gen1 * 30) + (gen2 * 20) + (gen1 * gen2 * 10);
            uint256 uniquePairing = uint256(keccak256(abi.encodePacked(parent1Id, parent2Id))) % 50; // Unique pairing bonus based on the parent IDs
            uint256 randomLuck = randomness % 50; // Random luck factor
            rarityPoints = baseGeneration + uniquePairing + randomLuck + 100;
        }

        if (mode == BreedingMode.Ascension) {
            uint256 baseGeneration = gen1 * 40;
            uint256 randomLuck = randomness % 40;
            rarityPoints = baseGeneration + randomLuck + 50; // Ascension rarity points
        }

        return rarityPoints;
    }

    /**
     * @notice Randomizes the attributes of the new BeanHead based on the provided randomness.
     * @param randomness The random number provided by Chainlink VRF.
     * @return SVGParams The randomized attributes for the new BeanHead.
     */
    function _randomizeAttributes(uint256 randomness) private pure returns (Genesis.SVGParams memory) {
        // Logic to randomize attributes based on the randomness value
        Genesis.HairParams memory hair =
            Genesis.HairParams({hairStyle: uint8(randomness % 10), hairColor: uint8(randomness % 5)});
        Genesis.BodyParams memory body =
            Genesis.BodyParams({bodyType: uint8(randomness % 10), skinColor: uint8(randomness % 5)});
        Genesis.ClothingParams memory clothing = Genesis.ClothingParams({
            clothes: uint8(randomness % 10),
            clothingColor: uint8(randomness % 5),
            clothesGraphic: uint8(randomness % 10)
        });
        Genesis.FacialFeaturesParams memory facialFeatures = Genesis.FacialFeaturesParams({
            eyebrowShape: uint8(randomness % 10),
            eyeShape: uint8(randomness % 10),
            facialHairType: uint8(randomness % 10),
            mouthStyle: uint8(randomness % 10),
            lipColor: uint8(randomness % 5)
        });
        Genesis.AccessoryParams memory accessory = Genesis.AccessoryParams({
            accessoryId: uint8(randomness % 10),
            hatStyle: uint8(randomness % 10),
            hatColor: uint8(randomness % 5)
        });
        Genesis.OtherParams memory other = Genesis.OtherParams({
            faceMask: randomness % 2 == 0,
            faceMaskColor: uint8(randomness % 5),
            shapes: randomness % 2 == 0,
            shapeColor: uint8(randomness % 5),
            lashes: randomness % 2 == 0
        });

        return Genesis.SVGParams(hair, body, clothing, facialFeatures, accessory, other);
    }
}
