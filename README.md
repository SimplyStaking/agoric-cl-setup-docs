# Setup Guide

This is a step-by-step guide explaining how to set up a Chainlink node and an oracle on Agoric

## Requirements

Make sure you have the following requirements before starting:
1. node (Minimum version 14.15.0)
2. docker
3. docker-compose

## Step 1: Installing Agoric CLI (use agoricdev-11 branch)

``` bash
node --version # 14.15.0 or higher
npm install --global yarn
git clone https://github.com/Agoric/agoric-sdk
cd agoric-sdk
git checkout agoricdev-11
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
git clone https://github.com/Agoric/dapp-oracle.git
git checkout main
agoric install
```

## Step 3: Change Network Config File

Change the IP in the file found in <b>dapp-oracle/chainlink-agoric/etc/network-config.json</b>.
<b>This has to be pointed to a node on Agoric Devnet</b>

```json
{
  "chainName": "agoricdev-11",
  "gci": "https://devnet.rpc.agoric.net:443/genesis",
  "rpcAddrs": [
    "https://devnet.rpc.agoric.net:443"
  ]
}
```

## Step 4: Copy the new code files in this directory to the dapp-oracle directory

The next step involves copying the docker-compose.yml file in this directory to the dapp-oracle directory because it contains more recent images

```bash
#run this in the root directory of this project
mv chainlink-agoric/* ../dapp-oracle/chainlink-agoric
chmod +x ../dapp-oracle/chainlink-agoric/add-new-job
```

## Step 5: Run setup script

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

## Step 6: Get AG Solo's address

Run the following

```bash
docker exec chainlink-agoric_ag-solo-node1_1 /bin/cat chainlink/ag-cosmos-helper-address
```

## Step 7: Hit the faucet on Discord

1. Join Agoric's <a href="https://discord.com/invite/qDW8DRes4s">Discord Server</a>
2. in #faucet run the following command and replace <addr-step7> with the address obtained from step 7
  
```bash
!faucet client <addr-step7>
```
  
## Step 8: Spawn the oracle
  
Run the following command
  
```bash
INSTALL_ORACLE="Chainlink oracle" agoric deploy api/spawn.js --hostport=127.0.0.1:6891
```

## Step 9: Send the address to the network administrators

This step involves the following:
1) Once all the node operators send in their addresses, network administrators create a governance proposal
2) Once it passes, the network administrators send a job spec in JSON format to each node operator

## Step 10: Get details from network administrators

The network administartors will provide the following:

1. TOML job spec file
2. List of bridges to add
3. Command to run

## Step 11: Add the required bridges given in Step 10

## Step 12: Create the Job

Run the following command in the dapp/chainlink-agoric directory:

<b> Note: </b> You have to replace <b> \<path-to-toml-job-spec> </b>

```bash
./add-new-job <path-to-toml-job-spec>
```

This will:
1. Create the job on your Chainlink Node
2. Prepare the flux parameter file for the next command

## Step 13: Run the given command

Run the given command from Step 11 in the root directory of dapp-oracle

<b>Example: </b>

```bash
AGGREGATOR_INSTANCE_LOOKUP='["agoricNames","instance","ATOM-USD priceAggregator"]' \
IN_BRAND_LOOKUP='["agoricNames","oracleBrand","ATOM"]' \
OUT_BRAND_LOOKUP='["agoricNames","oracleBrand","USD"]' \
FEE_ISSUER_LOOKUP='["wallet","issuer","RUN"]' \
agoric deploy api/flux-notifier.js --hostname=127.0.0.1:6891
```
