// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.24;

// import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
// import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
// import {CCIPLocalSimulatorFork, Register} from "chainlink-local/ccip/CCIPLocalSimulatorFork.sol";
// import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
// import {RegistryModuleOwnerCustom} from
//     "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
// import {TokenPool, IERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
// import {RateLimiter} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
// import {TokenAdminRegistry} from
//     "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {Ownable as OwnableOZ} from "@openzeppelin/contracts/access/Ownable.sol";

// import {MockTokenPool} from "src/mocks/MockTokenPool.sol";
// import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
// import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
// import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
// import {DeployBeanHeadsBridge} from "script/DeployBeanHeadsBridge.s.sol";
// import {BeanHeads} from "src/core/BeanHeads.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {Genesis} from "src/types/Genesis.sol";
// import {Helpers} from "test/Helpers.sol";

// contract BeanHeadsBridgeTest is Test, Helpers {
//     BeanHeadsBridge public sepoliaBeanHeadsBridge;
//     BeanHeadsBridge public baseBeanHeadsBridge;

//     HelperConfig public helperConfigSepolia;
//     HelperConfig public helperConfigBase;

//     Helpers public sepoliaHelpers;
//     Helpers public baseHelpers;

//     BeanHeads public sepoliaBeanHeads;
//     BeanHeads public baseBeanHeads;

//     CCIPLocalSimulatorFork public ccipSimulatorSepolia;
//     CCIPLocalSimulatorFork public ccipSimulatorBase;

//     Register.NetworkDetails public sepoliaNetworkDetails;
//     Register.NetworkDetails public baseNetworkDetails;

//     MockTokenPool public sepoliaTokenPool;
//     MockTokenPool public baseTokenPool;

//     uint64 public constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;
//     uint64 public constant BASE_CHAIN_SELECTOR = 10344971235874465080;

//     uint256 public constant MINT_PRICE = 0.01 ether;
//     address public constant NATIVE_TOKEN = address(0);

//     address public USER = makeAddr("user");

//     uint256 sepoliaFork;
//     uint256 baseFork;

//     address public owner;
//     address[] public allowList;

//     function setUp() public {
//         // create fork
//         sepoliaFork = vm.createSelectFork("sepolia-eth");
//         baseFork = vm.createSelectFork("base-sepolia");

//         // Deploy on Sepolia
//         vm.selectFork(sepoliaFork);
//         ccipSimulatorSepolia = new CCIPLocalSimulatorFork();
//         vm.makePersistent(address(ccipSimulatorSepolia));

//         sepoliaNetworkDetails = ccipSimulatorSepolia.getNetworkDetails(block.chainid);
//         console.log("Sepolia Network Details: ", block.chainid);

//         helperConfigSepolia = new HelperConfig();
//         sepoliaHelpers = new Helpers();
//         address deployerSepoliaAddress = vm.addr(helperConfigSepolia.getActiveNetworkConfig().deployerKey);
//         owner = deployerSepoliaAddress;
//         DeployBeanHeadsBridge deploySepoliaBeanHeadsBridge = new DeployBeanHeadsBridge();
//         (address sepoliaBeanHeadsBridgeAddr, address sepoliaBeanHeadsAddress) = deploySepoliaBeanHeadsBridge.run();
//         sepoliaBeanHeadsBridge = BeanHeadsBridge(payable(sepoliaBeanHeadsBridgeAddr));
//         sepoliaBeanHeads = BeanHeads(payable(sepoliaBeanHeadsAddress));

//         // Deploy on Base
//         vm.selectFork(baseFork);
//         ccipSimulatorBase = new CCIPLocalSimulatorFork();
//         vm.makePersistent(address(ccipSimulatorBase));

//         baseNetworkDetails = ccipSimulatorBase.getNetworkDetails(block.chainid);
//         console.log("Base Network Details: ", block.chainid);

//         helperConfigBase = new HelperConfig();
//         baseHelpers = new Helpers();
//         address deployerBaseAddress = vm.addr(helperConfigBase.getActiveNetworkConfig().deployerKey);
//         owner = deployerBaseAddress;
//         DeployBeanHeadsBridge deployBaseBeanHeadsBridge = new DeployBeanHeadsBridge();
//         (address baseBeanHeadsBridgeAddr, address baseBeanHeadsAddress) = deployBaseBeanHeadsBridge.run();
//         baseBeanHeadsBridge = BeanHeadsBridge(payable(baseBeanHeadsBridgeAddr));
//         baseBeanHeads = BeanHeads(payable(baseBeanHeadsAddress));

//         vm.selectFork(sepoliaFork);
//         vm.startPrank(owner);
//         vm.deal(USER, 100 ether);
//         sepoliaBeanHeadsBridge.setRemoteBridge(address(baseBeanHeadsBridge));
//         ccipSimulatorSepolia.requestLinkFromFaucet(address(sepoliaBeanHeadsBridge), 100 ether);
//         assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(baseBeanHeadsBridge)), true);
//         vm.stopPrank();

//         vm.selectFork(baseFork);
//         vm.startPrank(owner);
//         vm.deal(USER, 100 ether);
//         baseBeanHeadsBridge.setRemoteBridge(address(sepoliaBeanHeadsBridge));
//         ccipSimulatorBase.requestLinkFromFaucet(address(baseBeanHeadsBridge), 100 ether);
//         assertEq(baseBeanHeadsBridge.remoteBridgeAddresses(address(sepoliaBeanHeadsBridge)), true);
//         vm.stopPrank();
//     }

//     function test_sendMintTokenRequest() public {
//         vm.selectFork(baseFork);
//         vm.startPrank(USER);
//         uint256 tokenAmount = 1;
//         uint256 mintPayment = MINT_PRICE * tokenAmount;

//         bytes32 messageId = baseBeanHeadsBridge.sendMintTokenRequest{value: mintPayment}(
//             SEPOLIA_CHAIN_SELECTOR, USER, params, tokenAmount
//         );

//         vm.stopPrank();

//         vm.selectFork(sepoliaFork);

//         Client.Any2EVMMessage memory receivedMessage = Client.Any2EVMMessage({
//             messageId: messageId,
//             sourceChainSelector: BASE_CHAIN_SELECTOR,
//             sender: abi.encode(address(baseBeanHeadsBridge)),
//             data: abi.encode(IBeanHeadsBridge.ActionType.MINT, USER, params, tokenAmount),
//             destTokenAmounts: new Client.EVMTokenAmount[](1)
//         });
//         receivedMessage.destTokenAmounts[0] = Client.EVMTokenAmount({token: address(0), amount: mintPayment});

//         vm.prank(sepoliaNetworkDetails.routerAddress);
//         sepoliaBeanHeadsBridge.ccipReceive(receivedMessage);

//         uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
//         assertEq(userTokenBalance, tokenAmount);
//     }
// }
