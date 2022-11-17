# Setup Guide

This is a step-by-step guide explaining how to set up a Chainlink node and an oracle on Agoric

## Requirements

Make sure you have the following requirements before starting:
1. node (Minimum version 16.17.0)
2. docker
3. docker-compose
4. jq

## Step 1: Installing Agoric CLI (use smart-wallet-local branch)

``` bash
cd ~
node --version # 16.17.0 or higher
npm install --global yarn
git clone https://github.com/jacquesvcritien/agoric-sdk
cd agoric-sdk
git checkout smart-wallet-local
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
git clone https://github.com/jacquesvcritien/dapp-oracle.git
cd dapp-oracle
git checkout smart-wallet-local
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
./start-local-chain.sh $WALLET_NAME
```

## Step 5: Clone the middleware's repository

Clone the repository containing the code for the middleware

```bash
cd ~
git clone https://github.com/jacquesvcritien/agoric-cl-middleware.git
cd agoric-cl-middleware
yarn install
```

## Step 6: Accepting the oracle invitation

The next step involves accepting the oracle invitation

```bash
ASSET_IN=ATOM
ASSET_OUT=USD
cd ~/agoric-cl-middleware/scripts
./accept-oracle-invitation.sh $WALLET_NAME $ASSET_IN $ASSET_OUT
```

## Step 7: Run setup script

The next step involves running the script found at <b>dapp-oracle/chainlink-agoric/setup</b>.

```bash
cd ~/dapp-oracle/chainlink-agoric
docker-compose pull
./setup
```

This setup script does the following:
1. Starts docker containers via <b>chainlink-agoric/internal-scripts/common.sh</b> for:
    - Postgres DB Instance
    - Chainlink Node
2. Adds the external initiator built inside the middleware to the Chainlink node via <b>chainlink-agoric/internal-scripts/add-ei.sh</b>
3. Adds the external adapter built inside the middleware to the bridges section of the Chainlink node via <b>chainlink-agoric/internal-scripts/add-bridge.sh</b>

## Step 8: Starting the middleware

To start the middleware, run the following commands

```
cd ~/agoric-cl-middleware
THIS_VM_IP=$(hostname -I | sed 's/ *$//g')
THIS_VM_IP=$(echo ${THIS_VM_IP%% *})
WALLET_ADDR=$(agd keys show "$WALLET_NAME" --keyring-backend test --output json | jq -r .address)
echo "THIS_VM_IP=$THIS_VM_IP" > .env
echo "WALLET_ADDR=$WALLET_ADDR" >> .env

#build the images
docker build --tag ag-oracle-middleware -f Dockerfile.middleware .
docker build --tag ag-oracle-monitor -f Dockerfile.monitor .

docker-compose up -d
```


## Step 9: Adding Job to CL node


1. Go to http://IP:6691
2. Log in with the following credentials
```
notreal@fakeemail.ch
twochains
```
3. Add the following 3 bridges
```
bridge-nomics
bridge-coinmetrics
bridge-tiingo
```
4. Add the following job
```toml
name            = "ATOM-USD"
type            = "webhook"
schemaVersion   = 1
maxTaskDuration = "30s"
externalInitiators = [
  { name = "test-ei", spec = "{\"endpoint\":\"agoric-node\", \"name\":\"ATOM-USD\"}" },
]
observationSource   = """
    payment [type="jsonparse" data="$(jobRun.requestBody)" path="payment"]
    request_id [type="jsonparse" data="$(jobRun.requestBody)" path="request_id"]

   // data source 1
   ds1          [type=bridge name="bridge-nomics" requestData="{\\"data\\": {\\"from\\":\\"ATOM\\",\\"to\\":\\"USD\\"}}"];
   ds1_parse    [type=jsonparse path="result"];
   ds1_multiply [type=multiply times=1000000];
   ds1 -> ds1_parse -> ds1_multiply -> answer;

   // data source 2
   ds2          [type=bridge name="bridge-coinmetrics" requestData="{\\"data\\": {\\"endpoint\\":\\"crypto\\",\\"from\\":\\"ATOM\\",\\"to\\":\\"USD\\"}}"];
   ds2_parse    [type=jsonparse path="result"];
   ds2_multiply [type=multiply times=1000000];
   ds2 -> ds2_parse -> ds2_multiply -> answer;

   // data source 3
   ds3          [type=bridge name="bridge-tiingo" requestData="{\\"data\\": {\\"from\\":\\"ATOM\\",\\"to\\":\\"USD\\"}}"];
   ds3_parse    [type=jsonparse path="result"];
   ds3_multiply [type=multiply times=1000000];
   ds3 -> ds3_parse -> ds3_multiply -> answer;

    answer [type=median                      index=0]
    send_to_bridge [type="bridge" name="agoric" requestData="{ \\"data\\": {\\"result\\": $(answer), \\"request_id\\": $(request_id), \\"payment\\":$(payment), \\"job\\": $(jobSpec.externalJobID), \\"name\\": $(jobSpec.name) }}"]
    answer -> payment-> request_id -> send_to_bridge
"""
```

## Step 10: Query updated price

Run the following

```bash
agd query vstorage data published.priceFeed.ATOM-USD_price_feed
```
