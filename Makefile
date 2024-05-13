-include .env

build:; forge build

#Anvil
deploy-localchain:; forge script script/DeployEtherBank.s.sol --rpc-url http://localhost:8545 --private-key $(PRIVATE_KEY) --broadcast

deploy-sepolia:; forge script script/DeployEtherBank.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE-KEY) --broadcast
