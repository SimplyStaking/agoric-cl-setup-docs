# Setup Guide

This is a step-by-step guide explaining how to set up a Chainlink node and an oracle on Agoric

## Requirements

Make sure you have the following requirements before starting:
1. node (Minimum version 16.17.0)
2. docker
3. docker-compose
4. jq

## Step 1: Installing Agoric CLI (use master branch)

``` bash
cd ~
node --version # 16.17.0 or higher
npm install --global yarn
git clone https://github.com/jacquesvcritien/agoric-sdk
cd agoric-sdk
yarn install
yarn build
yarn link-cli ~/bin/agoric
cd packages/cosmic-swingset && make
echo "export PATH=$PATH:$HOME/bin" >> ~/.profile
source ~/.profile
agoric --version
```

## Step 2: Clone dapp-oracle and install dependencies

Before the setup, we have to run the following

```bash
cd ~
git clone https://github.com/Agoric/dapp-oracle.git
cd dapp-oracle
git checkout main
agoric install
```

## Step 3: Create a key

Create an agoric key

```
WALLET_NAME=test
agd keys add $WALLET_NAME --keyring-backend=test
```

## Step 4: Start a local chain

Start a local chain

```bash
cd ~/agoric-sdk/packages/inter-protocol/scripts
./start-local-chain.sh test
```

## Step 5: Accepting the oracle invitation

The next step involves accepting the oracle invitation

```bash
cd agoric-sdk/packages/agoric-cli
ORACLE_OFFER=$(mktemp -t agops.XXX)
bin/agops oracle accept >|"$ORACLE_OFFER"
jq ".body | fromjson" <"$ORACLE_OFFER"
bin/agoric wallet send --from "$WALLET_ADDR" --keyring-backend test --offer "$ORACLE_OFFER"
bin/agoric wallet show --from "$WALLET_ADDR"
ORACLE_OFFER_ID=$(jq ".body | fromjson | .offer.id" <"$ORACLE_OFFER")
echo "ORACLE_OFFER_ID: $ORACLE_OFFER_ID"
```

## Step 6: Run setup script

The next step involves running the script found at <b>dapp-oracle/chainlink-agoric/setup</b>.

```bash
#run this in the root directory of dapp-oracle
cd chainlink-agoric
docker-compose pull
./setup
```

This setup script does the following:
1. Starts docker containers via <b>chainlink-agoric/internal-scripts/common.sh</b> for:
    - Postgres DB Instance
    - Chainlink Node
2. Adds the external initiator built inside the middleware to the Chainlink node via <b>chainlink-agoric/internal-scripts/add-ei.sh</b>
3. Adds the external adapter built inside the middleware to the bridges section of the Chainlink node via <b>chainlink-agoric/internal-scripts/add-bridge.sh</b>
