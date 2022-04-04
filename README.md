# Setup Guide

This is a step-by-step guide explaining how to set up a Chainlink node and an oracle on Agoric

## Requirements

Make sure you have the following requirements before starting:
1. node (Minimum version 14.15.0)
2. docker
3. docker-compose

## Step 1: Installing Agoric CLI (use mfig-oracle-management branch)

``` bash
node --version # 14.15.0 or higher
npm install --global yarn
git clone https://github.com/Agoric/agoric-sdk
cd agoric-sdk
git checkout mfig-oracle-management
yarn install
yarn build
yarn link-cli ~/bin/agoric
cd packages/cosmic-swingset && make
echo "export PATH=$PATH:$HOME/bin" >> ~/.profile
source ~/.profile
agoric --version
```

## Step 2: Change Network Config File

Change the IP in the file found in <b>chainlink-agoric/etc/network-config.json</b>.
<b>This has to be pointed to a node on Agoric Devnet</b>

```json
{
  "chainName": "agoric",
  "gci": "http://<ip>:26657/genesis",
  "rpcAddrs": [
    "<ip>:26657"
  ]
}
```

## Step 3: Install dependencies

Before the setup, we have to run the following

```bash
#run this in the root directory of dapp-oracle
git checkout mfig-oracle-bootstrap
agoric install
```

## Step 4: Run setup script

The next step involves running the script found at <b>chainlink-agoric/setup</b>.

```bash
#run this in the root directory of this project
cd chainlink-agoric
docker-compose pull
./setup
```

This setup script does the following:
1. Starts docker containers via <b>chainlink-agoric/internal-scripts/common.sh</b> for:
    - Postgres DB Instance
    - Chainlink Node
    - Agoric local solo node
    - Chainlink Agoric External Adapter
    - Chainlink Agoric External Initiator
2. Adds the external initiator to the Chainlin knode via <b>chainlink-agoric/internal-scripts/add-ei.sh</b>
3. Adds the external adapter to the bridges section of the Chainlink node via <b>chainlink-agoric/internal-scripts/add-bridge.sh</b>

#### Troubleshooting 

If on running the script, you encounter such error:
```
Cannot find module '@agoric/zoe/exported'
```

Do the following:
1. Remove yarn.lock in /dapp-oracle
2. Run the following in /dapp-oracle
```bash
yarn install
```

## Step 5: Get AG Solo's address

Run the following

```bash
docker exec chainlink-agoric_ag-solo-node_1 /bin/cat chainlink/ag-cosmos-helper-address
```

## Step 6: Send the address to the network administrators

This step involves the following:
1) Once all the node operators send in their addresses, network administrators create a governance proposal
2) Once it passes, the network administrators send a job spec in JSON format to each node operator

## Step 7: Get details from network administrators

The network administartors will rpovide the following:

1. JSON job spec file
2. JS Flux Params file
3. Command to run

## Step 8: Create the Job + Set Flux Params

Run the following command in the dapp/chainlink-agoric directory:

<b> Note: </b> You have to replace <b> \<path-to-json-job-spec> </b> and <b>\<path-to-js-flux-params></b>

```bash
./add-new-job <path-to-json-job-spec> <path-to-js-flux-params>
```

This will:
1. Create the job on your Chainlink Node
2. Prepare the flux parameter file for the next command

## Step 9: Run the given command

Run the given command from Step 7 in the root directory of dapp-oracle

<b>Example: </b>

```bash
NO_AGGREGATOR_INSTANCE_LOOKUP='["agoricNames","instance","BLD-USD priceAggregator"]' \
IN_BRAND_LOOKUP='["agoricNames","brand","BLD"]' \
OUT_BRAND_LOOKUP='["agoricNames","brand","RUN"]' \
FEE_ISSUER_LOOKUP='["agoricNames","issuer","RUN"]' \
agoric deploy api/flux-notifier.js --hostname=127.0.0.1:6891
```
