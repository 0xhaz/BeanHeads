-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account testnetKey --sender $(OWNER) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network arbitrum-sepolia,$(ARGS)),--network arbitrum-sepolia)
	NETWORK_ARGS := --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --account testnetKey --sender $(OWNER) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network optimism-sepolia,$(ARGS)),--network optimism-sepolia)
	NETWORK_ARGS := --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --account testnetKey --sender $(OWNER) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployBeanHeads.s.sol:DeployBeanHeads $(NETWORK_ARGS)

deploy-bridge:
	@forge script script/DeployBeanHeadsBridge.s.sol:DeployBeanHeadsBridge $(NETWORK_ARGS)

deploy-breeder:
	@forge script script/DeployBeanHeadsBreeder.s.sol:DeployBeanHeadsBreeder $(NETWORK_ARGS)

zkdeploy: 
	@forge create src/OurToken.sol:OurToken --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --legacy --zksync