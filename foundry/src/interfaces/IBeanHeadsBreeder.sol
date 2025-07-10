// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBeanHeadsBreeder {
    error IBeanHeadsBreeder__InvalidRequestId();
    error IBeanHeadsBreeder__CannotBreedSameBeanHead();
    error IBeanHeadsBreeder__TokensNotEscrowedBySender();

    /**
     * @notice Enum representing the different breeding modes.
     * @dev Used to distinguish between breeding types in requests.
     * NewBreed: Breeds two parents without burning them.
     * Mutation: Burns one parent and returns the other.
     * Fusion: Burns both parents to create a new BeanHead.
     * Ascension: Burns one parent to create a new BeanHead of a higher generation.
     */
    enum BreedingMode {
        NewBreed,
        Mutation,
        Fusion,
        Ascension
    }

    /**
     * @notice Struct representing a breed request.
     * @param owner The address of the owner making the request.
     * @param parent1Id The token ID of the first parent.
     * @param parent2Id The token ID of the second parent.
     * @param mode The breeding mode for this request.
     */
    struct BreedRequest {
        address owner;
        uint256 parent1Id;
        uint256 parent2Id;
        BreedingMode mode;
    }

    // Event emitted when a breed request is made
    event RequestBreed(
        address indexed owner, uint256 parent1Id, uint256 parent2Id, uint256 requestId, BreedingMode mode
    );

    // Event emitted when a breed request is fulfilled
    event BreedRequestFulfilled(address indexed owner, uint256 requestId, BreedingMode mode, uint256 newTokenId);

    /**
     * @notice Emitted when a new BeanHead is bred without burning parents.
     * @param owner The address receiving the new BeanHead.
     * @param requestId The Chainlink VRF request ID.
     * @param parent1Id The first parent token ID.
     * @param parent2Id The second parent token ID.
     * @param newTokenId The newly minted token ID.
     * @param childGeneration The generation of the new BeanHead.
     * @param rarityPoints The assigned rarity points.
     */
    event NewBreedCompleted(
        address indexed owner,
        uint256 indexed requestId,
        uint256 parent1Id,
        uint256 parent2Id,
        uint256 newTokenId,
        uint256 childGeneration,
        uint256 rarityPoints
    );

    /**
     * @notice Emitted when a BeanHead mutates, burning one parent.
     * @param owner The address receiving the new BeanHead.
     * @param requestId The Chainlink VRF request ID.
     * @param burnedTokenId The token ID that was burned.
     * @param survivingTokenId The token ID returned to the owner.
     * @param newTokenId The newly minted token ID.
     * @param childGeneration The generation of the new BeanHead.
     * @param rarityPoints The assigned rarity points.
     */
    event MutationCompleted(
        address indexed owner,
        uint256 indexed requestId,
        uint256 burnedTokenId,
        uint256 survivingTokenId,
        uint256 newTokenId,
        uint256 childGeneration,
        uint256 rarityPoints
    );

    /**
     * @notice Emitted when a Fusion occurs, burning both parents.
     * @param owner The address receiving the new BeanHead.
     * @param requestId The Chainlink VRF request ID.
     * @param burnedParent1Id The first parent token ID burned.
     * @param burnedParent2Id The second parent token ID burned.
     * @param newTokenId The newly minted token ID.
     * @param childGeneration The generation of the new BeanHead.
     * @param rarityPoints The assigned rarity points.
     */
    event FusionCompleted(
        address indexed owner,
        uint256 indexed requestId,
        uint256 burnedParent1Id,
        uint256 burnedParent2Id,
        uint256 newTokenId,
        uint256 childGeneration,
        uint256 rarityPoints
    );

    /**
     * @notice Emitted when a BeanHead ascends to a higher generation.
     * @param owner The address receiving the new BeanHead.
     * @param requestId The Chainlink VRF request ID.
     * @param burnedTokenId The token ID that was burned.
     * @param newTokenId The newly minted token ID.
     * @param childGeneration The generation of the new BeanHead.
     * @param rarityPoints The assigned rarity points.
     */
    event AscensionCompleted(
        address indexed owner,
        uint256 indexed requestId,
        uint256 burnedTokenId,
        uint256 newTokenId,
        uint256 childGeneration,
        uint256 rarityPoints
    );

    /**
     * @notice Deposits a BeanHead token into the breeder contract.
     * @param parent1Id The token ID of the BeanHead to deposit.
     * @param parent2Id The token ID of the second BeanHead to deposit.
     * @dev This function allows the owner of the BeanHead to deposit it into the breeder
     */
    function depositBeanHeads(uint256 parent1Id, uint256 parent2Id) external;

    /**
     * @notice Withdraws a BeanHead token from the breeder contract.
     * @param tokenId The token ID of the BeanHead to withdraw.
     * @dev This function allows the owner of the BeanHead to withdraw it from the breeder
     */
    function withdrawBeanHeads(uint256 tokenId) external;

    /**
     * @notice Initiates breeding of two generation 1 BeanHeads.
     * @param parent1Id The token ID of the first parent BeanHead.
     * @param parent2Id The token ID of the second parent BeanHead.
     * returns The request ID for the breeding request.
     */
    function requestBreed(uint256 parent1Id, uint256 parent2Id, BreedingMode mode)
        external
        returns (uint256 requestId);

    /**
     * @notice Gets the rarity points assigned to a BeanHead token.
     * @param tokenId The token ID of the BeanHead.
     * @return The rarity points assigned to the BeanHead.
     * @dev This function retrieves the rarity points for a specific BeanHead token.
     */
    function getRarityPoints(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Retrieves the breed request details for a given request ID.
     * @param requestId The ID of the breed request.
     * @return request The BreedRequest struct containing details of the request.
     * @dev This function allows querying the details of a specific breed request.
     */
    function getBreedRequest(uint256 requestId) external view returns (BreedRequest memory request);

    /**
     * @notice Gets the owner of a specific escrowed token.
     * @param tokenId The token ID of the escrowed BeanHead.
     * @return owner The address of the owner of the escrowed BeanHead.
     * @dev This function retrieves the owner of a BeanHead that is currently escrowed in the breeder contract.
     */
    function getEscrowedTokenOwner(uint256 tokenId) external view returns (address owner);
}
