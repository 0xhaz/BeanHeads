// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";

/**
 * @title BeanHeadsBreeder
 * @notice This contract allows users to breed BeanHeads by requesting random attributes from Chainlink VRF.
 * It extends the VRFConsumerBaseV2 to handle randomness requests and fulfillments.
 * Only user that has Gen1 BeanHeads can breed new BeanHeads.
 */
contract BeanHeadsBreeder is VRFConsumerBaseV2 {
    error BeanHeadsBreeder__InvalidRequestId();
    error BeanHeadsBreeder__CannotBreedSameBeanHead();

    IBeanHeads private immutable i_beanHeads;

    // Chainlink VRF parameters
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private constant GAS_LIMIT = 200_000; // Gas limit for the VRF callback
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations for the VRF request

    // Event emitted when a breed request is made
    event RequestBreed(address indexed owner, uint256 parent1Id, uint256 parent2Id, uint256 requestId);

    struct BreedRequest {
        address owner;
        uint256 parent1Id;
        uint256 parent2Id;
    }

    // Mapping to store the breed requests
    mapping(uint256 requestId => BreedRequest) private s_breedRequests;

    constructor(address _beanHeads, address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_beanHeads = IBeanHeads(_beanHeads);
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
    }

    /**
     * @notice Initiates breeding of two generation 1 BeanHeads.
     * @param parent1Id The token ID of the first parent BeanHead.
     * @param parent2Id The token ID of the second parent BeanHead.
     * returns The request ID for the breeding request.
     */
    function requestBreed(uint256 parent1Id, uint256 parent2Id) external returns (uint256 requestId) {
        if (parent1Id == parent2Id) revert BeanHeadsBreeder__CannotBreedSameBeanHead();

        if (i_beanHeads.getOwnerOf(parent1Id) != msg.sender || i_beanHeads.getOwnerOf(parent2Id) != msg.sender) {
            revert IBeanHeads.IBeanHeads__NotOwner();
        }

        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS, // Number of confirmations
            GAS_LIMIT, // Gas limit for the callback
            1 // Number of random words
        );

        s_breedRequests[requestId] = BreedRequest({owner: msg.sender, parent1Id: parent1Id, parent2Id: parent2Id});

        emit RequestBreed(msg.sender, parent1Id, parent2Id, requestId);
    }

    /**
     * @notice Callback function that is called by Chainlink VRF to fulfill the random words request.
     * @param requestId The ID of the request.
     * @param randomWords The array of random words returned by Chainlink VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        BreedRequest memory request = s_breedRequests[requestId];
        if (request.owner == address(0)) revert BeanHeadsBreeder__InvalidRequestId();

        Genesis.SVGParams memory childParams = _randomizeAttributes(randomWords[0]);

        uint256 gen1 = i_beanHeads.getGeneration(request.parent1Id);
        uint256 gen2 = i_beanHeads.getGeneration(request.parent2Id);
        uint256 childGeneration = (gen1 > gen2 ? gen1 : gen2) + 1;

        i_beanHeads.mintFromBreeders(request.owner, childParams, childGeneration);

        delete s_breedRequests[requestId];
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
