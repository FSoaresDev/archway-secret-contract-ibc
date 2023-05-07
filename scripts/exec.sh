#!/bin/bash
function archwayd() {
  export docker_name=archway-localnet
  docker exec --interactive "$docker_name" archwayd "$@";
}

function secretd() {
  export docker_name=secret-localnet
  docker exec --interactive "$docker_name" secretd "$@";
}

export deployer_name=acc0
export wasm_path=/root/code/contracts/cosmwasm_contract/target/wasm32-unknown-unknown/release

export deployer_address=$(archwayd keys show -a $deployer_name --keyring-backend test)
echo "Deployer address: '$deployer_address'"

cd contracts/cosmwasm_contract
RUSTFLAGS='-C link-arg=-s' cargo build --release --target wasm32-unknown-unknown

# archway store, instantiate, and get port id for IBC
stored_info=$(archwayd tx wasm store "${wasm_path}/cosmwasm_contract.wasm" --from "$deployer_name" --keyring-backend test --gas 6000000 -b block -y --chain-id arch-local -o json)
code_id=$(echo $stored_info | jq -r '.logs[0].events[1].attributes[] | select(.key=="code_id") | .value')
echo "Stored: '$code_id'"

archwayd tx wasm instantiate $code_id '{}' --label test --from "$deployer_name" -b block -y --keyring-backend test --chain-id arch-local --no-admin -o json --gas 6000000
arch_contract=$(archwayd query wasm list-contract-by-code $code_id --chain-id arch-local -o json | jq -r '.contracts[-1]')
echo "arch_contract: '$arch_contract'"
ARCH_PORT_ID=$(archwayd q wasm  contract-state smart $arch_contract '{"port":{}}' --chain-id arch-local -o json | jq -r .data.port_id)
echo "ARCH_PORT_ID: '$ARCH_PORT_ID'"

#######################
# secret store, instantiate, and get port id for IBC
export deployer_name=a
export wasm_path=/root/code/contracts/secret_cosmwasm_contract/target/wasm32-unknown-unknown/release

export deployer_address=$(secretd keys show -a $deployer_name --keyring-backend test)
echo "Deployer address: '$deployer_address'"

cd ../secret_cosmwasm_contract
RUSTFLAGS='-C link-arg=-s' cargo build --release --target wasm32-unknown-unknown

stored_info=$(secretd tx wasm store "${wasm_path}/secret_cosmwasm_contract.wasm" --from "$deployer_name" --keyring-backend test --gas 6000000 -b block -y --chain-id  secret-local -o json)
code_id=$(echo $stored_info | jq -r '.logs[0].events[0].attributes[] | select(.key=="code_id") | .value')
echo "Stored: '$code_id'"

secretd tx wasm instantiate $code_id '{}' --label test$(date +"%s") --from "$deployer_name" -b block -y --keyring-backend test --chain-id secret-local -o json --gas 6000000
secret_contract=$(secretd query wasm list-contract-by-code $code_id --chain-id secret-local -o json | jq -r '.[-1].contract_address')
echo "secret_contract: '$secret_contract'"
SECRET_PORT_ID=$(secretd query wasm list-contract-by-code $code_id --chain-id secret-local -o json | jq -r '.[-1].ibc_port_id')
echo "SECRET_PORT_ID: '$SECRET_PORT_ID'"

docker exec --interactive relayer bash -c "hermes create channel --a-chain secret-local --b-chain arch-local --a-port ${SECRET_PORT_ID} --b-port ${ARCH_PORT_ID} --channel-version archway-secret-0 --new-client-connection  --yes";
archwayd q wasm contract-state smart $arch_contract '{"list_channels":{}}' --chain-id arch-local -o json
#secretd q compute query $secret_contract '{"list_channels":{}}' --chain-id secret-local -o json

# archwayd tx ibc-transfer transfer transfer channel-0 cosmos14d2q6k4ptf8mht7w3jggtyc5np7d599wjnle87 7uarch  --from "$deployer_name" --keyring-backend test --chain-id arch-local -b block -y -o json --gas 6000000
# archwayd tx bank send "$deployer_address" "$contract" 1000000uarch --from "$deployer_name" --keyring-backend test --chain-id arch-local -b block -y -o json --gas 6000000
# archwayd tx wasm execute $contract '{"transfer": {}}' --from "$deployer_name" --keyring-backend test --chain-id arch-local -b block -y -o json --gas 6000000
