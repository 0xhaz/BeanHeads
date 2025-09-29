// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBeanHeadsBreeder {
    /// @notice Error thrown when the request ID is invalid
    error IBeanHeadsBreeder__InvalidRequestId();
    /// @notice Error thrown when user tries to breed the same BeanHead
    error IBeanHeadsBreeder__CannotBreedSameBeanHead();
    /// @notice Error thrown when the token is not escrowed by the sender
    error IBeanHeadsBreeder__TokensNotEscrowedBySender();
    /// @notice Error thrown when the cooldown period has not passed
    error IBeanHeadsBreeder__CoolDownNotPassed();
    /// @notice Error thrown when the payment is insufficient
    error IBeanHeadsBreeder__InsufficientPayment();
    /// @notice Error thrown when the breeding limit is reached
    error IBeanHeadsBreeder__BreedLimitReached();
    /// @notice Error thrown when the token ID is invalid
    error IBeanHeadsBreeder__InvalidTokenId();
    /// @notice Error thrown when the owner is not the caller
    error IBeanHeadsBreeder__NotOwner();
    /// @notice Error thrown when a transfer fails
    error IBeanHeadsBreeder__TransferFailed();
    /// @notice Error thrown when the allowance for the payment token is insufficient
    error IBeanHeadsBreeder__InsufficientAllowance();
    /// @notice Error thrown when the payment token balance is insufficient
    error IBeanHeadsBreeder__InsufficientBalance();
    /// @notice Error thrown when the oracle price is invalid
    error IBeanHeadsBreeder__InvalidOraclePrice();
    /// @notice Error thrown when invalid token is provided
    error IBeanHeadsBreeder__InvalidToken();
    /// @notice Error thrown when the request is already fulfilled
    error IBeanHeadsBreeder__RequestAlreadyFulfilled();
    /// @notice Error thrown when the request is in an invalid state
    error IBeanHeadsBreeder__BadStatus();
    /// @notice Error thrown when there is no refundable amount
    error IBeanHeadsBreeder__NoRefundableAmount();
    /// @notice Error thrown when the status is not pending
    error IBeanHeadsBreeder__StatusNotPending();
    /// @notice Error thrown when the requestor is not the owner
    error IBeanHeadsBreeder__NotRequestor();
    /// @notice Error thrown when the answeredRound is stale
    error IBeanHeadsBreeder__StaleRound();
    /// @notice Error thrown when the price feed is stale
    error IBeanHeadsBreeder__StalePrice();
    /// @notice Error thrown when the caller is not the VRF Coordinator
    error IBeanHeadsBreeder__NotVRFCoordinator();

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
     * @notice Enum representing the different request statuses.
     * @dev Used to track the status of breed requests.
     * - NONE: The request has not been initiated.
     * - PENDING: The request is awaiting fulfillment.
     * - SETTLING: The request is being processed.
     * - SUCCESS: The request has been successfully fulfilled.
     * - FAILED: The request has failed.
     * - EXPIRED: The request has expired.
     */
    enum RequestStatus {
        NONE,
        PENDING,
        SETTLING,
        SUCCESS,
        FAILED,
        EXPIRED
    }

    /**
     * @notice Struct representing a breed request.
     * @param owner The address of the owner making the request.
     * @param parent1Id The token ID of the first parent.
     * @param parent2Id The token ID of the second parent.
     * @param mode The breeding mode for this request.
     * @param paymentToken The address of the ERC20 token used for payment.
     * @param paymentAmount The amount of the payment token to be used.
     * @param requestedAt The timestamp when the request was made.
     * @param status The current status of the request.
     */
    struct BreedRequest {
        address owner;
        uint256 parent1Id;
        uint256 parent2Id;
        BreedingMode mode;
        address paymentToken;
        uint256 paymentAmount;
        uint48 requestedAtBlock;
        RequestStatus status;
    }

    event BreedRequestRefunded(address indexed owner, address indexed paymentToken, uint256 paymentAmount);

    /**
     * @notice Emitted when a breed request is initiated.
     * @param owner The address of the owner who made the request.
     * @param parent1Id The token ID of the first parent BeanHead.
     * @param parent2Id The token ID of the second parent BeanHead.
     * @param requestId The Chainlink VRF request ID.
     * @param mode The breeding mode used for this request.
     */
    event RequestBreed(
        address indexed owner, uint256 parent1Id, uint256 parent2Id, uint256 requestId, BreedingMode mode
    );

    /**
     * @notice Emitted when a breed request is fulfilled.
     * @param owner The address of the owner who made the request.
     * @param requestId The Chainlink VRF request ID.
     * @param mode The breeding mode used for this request.
     * @param newTokenId The token ID of the newly bred BeanHead.
     */
    event BreedRequestFulfilled(address indexed owner, uint256 requestId, BreedingMode mode, uint256 newTokenId);

    /**
     * @notice Emitted when BeanHeads are deposited into the breeder contract.
     * @param owner The address of the owner depositing the BeanHeads.
     * @param parent1Id The token ID of the first parent BeanHead.
     */
    event BeanHeadsDeposited(address indexed owner, uint256 parent1Id);

    /**
     * @notice Emitted when a BeanHead is withdrawn from the breeder contract.
     * @param owner The address of the owner withdrawing the BeanHead.
     * @param tokenId The token ID of the BeanHead being withdrawn.
     */
    event BeanHeadsWithdrawn(address indexed owner, uint256 tokenId);

    /**
     * @notice Emitted when balance is withdrawn from the breeder contract.
     * @param token The address of the token being withdrawn.
     * @param amount The amount of tokens withdrawn.
     * @dev This event is emitted when the owner withdraws funds from the breeder contract.
     */
    event FundsWithdrawn(address indexed token, uint256 amount);

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
     * @notice Emitted when a Chainlink VRF request fails.
     * @param requestId The ID of the failed request.
     * @param user The address of the user who made the request.
     * @param token The address of the ERC20 token used for payment.
     * @param amount The amount of the payment token that was used.
     */
    event RequestFailed(uint256 indexed requestId, address indexed user, address token, uint256 amount);

    /**
     * @notice Emitted when a Chainlink VRF request is refunded.
     * @param user The address of the user who made the request.
     * @param token The address of the ERC20 token used for payment.
     * @param amount The amount of the payment token that was refunded.
     */
    event RequestRefunded(address indexed user, address indexed token, uint256 amount);

    /**
     * @notice Emitted when a Chainlink VRF request expires.
     * @param requestId The ID of the expired request.
     * @param user The address of the user who made the request.
     * @param token The address of the ERC20 token used for payment.
     * @param amount The amount of the payment token that was used.
     */
    event RequestExpired(uint256 indexed requestId, address indexed user, address token, uint256 amount);

    /**
     * @notice Deposits a BeanHead token into the breeder contract.
     * @param parent1Id The token ID of the BeanHead to deposit.
     * @dev This function allows the owner of the BeanHead to deposit it into the breeder
     */
    function depositBeanHeads(uint256 parent1Id) external;

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
     * @param mode The breeding mode to use (NewBreed, Mutation, Fusion, Ascension).
     * @param token The address of the ERC20 token used for payment.
     * returns The request ID for the breeding request.
     */
    function requestBreed(uint256 parent1Id, uint256 parent2Id, BreedingMode mode, address token)
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

    /**
     * @notice Gets the last breeding count for a specific parent token.
     * @param tokenId The token ID of the parent BeanHead.
     * @return count The number of times this parent has been used in breeding.
     * @dev This function retrieves how many times a specific parent BeanHead has been used in
     * breeding requests.
     * It helps to track the breeding history of each parent BeanHead.
     */
    function getParentBreedingCount(uint256 tokenId) external view returns (uint256 count);

    /**
     * @notice Withdraws funds from the breeder contract.
     * @param token The address of the ERC20 token to withdraw.
     * @dev This function allows the owner to withdraw funds from the breeder contract.
     */
    function withdrawFunds(address token) external;

    /**
     * @notice Claims a refund for a failed breed request.
     * @param token The address of the ERC20 token to refund.
     */
    function claimRefund(address token) external;

    /**
     * @notice Timeouts a breed request and refunds the user.
     * @param requestId The ID of the breed request to timeout.
     */
    function timeoutRefund(uint256 requestId) external;
}
