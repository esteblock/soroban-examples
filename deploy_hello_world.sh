#!/bin/bash

set -e

NETWORK="$1"
SOROBAN_RPC_HOST="http://stellar:8000"
SOROBAN_RPC_URL="$SOROBAN_RPC_HOST/soroban/rpc"

case "$1" in
standalone)
  echo "Using standalone network"
  SOROBAN_NETWORK_PASSPHRASE="Standalone Network ; February 2017"
  FRIENDBOT_URL="$SOROBAN_RPC_HOST/friendbot"
  ;;
futurenet)
  echo "Using Futurenet network"
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Future Network ; October 2022"
  FRIENDBOT_URL="https://friendbot-futurenet.stellar.org/"
  ;;
*)
  echo "Usage: $0 standalone|futurenet"
  exit 1
  ;;
esac


echo Add the $NETWORK network to cli client
soroban config network add "$NETWORK" \
  --rpc-url "$SOROBAN_RPC_URL" \
  --network-passphrase "$SOROBAN_NETWORK_PASSPHRASE"

if !(soroban config identity ls | grep token-admin 2>&1 >/dev/null); then
  echo Create the token-admin identity
  soroban config identity generate token-admin
fi
TOKEN_ADMIN_SECRET="$(soroban config identity show token-admin)"
TOKEN_ADMIN_ADDRESS="$(soroban config identity address token-admin)"

echo "We are using the following TOKEN_ADMIN_ADDRESS: $TOKEN_ADMIN_ADDRESS"
echo "--"
echo "--"
echo "$TOKEN_ADMIN_SECRET" > .soroban/token_admin_secret
echo "$TOKEN_ADMIN_ADDRESS" > .soroban/token_admin_address

echo Fund token-admin account from friendbot
echo This will fail if the account already exists, but it\' still be fine.
curl  -X POST "$FRIENDBOT_URL?addr=$TOKEN_ADMIN_ADDRESS"

ARGS="--network $NETWORK --source token-admin"
echo "Using ARGS: $ARGS"
echo "--" 
echo "--"

mkdir -p .soroban

echo Build the Hello World contract
cd hello_world
make build
cd  ..
HELLO_WASM="hello_world/target/wasm32-unknown-unknown/release/soroban_hello_world_contract.wasm"

echo "--"
echo "--"

echo Deploy the Hello World contract 
HELLO_ID="$(
soroban contract deploy $ARGS \
  --wasm $HELLO_WASM
)"
echo "$HELLO_ID" > .soroban/hello_wasm_hash
echo "Hello World contract deployed succesfully with HELLO_ID: $HELLO_ID"
echo "--"
echo "--"

echo "Call with HODLER argument"
soroban contract invoke \
  $ARGS \
  --wasm $HELLO_WASM\
  --id $HELLO_ID \
  -- \
  hello\
  --to "HODLER" 