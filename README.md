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
WALLET_NAME=test
cd ~/agoric-sdk/packages/inter-protocol/scripts
./start-local-chain.sh WALLET_NAME
```

## Step 5: Accepting the oracle invitation

The next step involves accepting the oracle invitation

```bash
WALLET_NAME=test
ASSET_IN=ATOM
ASSET_OUT=USD
cd agoric-sdk/packages/agoric-cl-middleware/scripts
chmod +x accept-oracle-invitation.sh $WALLET_NAME $ASSET_IN $ASSET_OUT
```

OR

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

## Step 7: Starting the middleware

To start the middleware, run the following command

```
cd agoric-sdk/packages/agoric-cl-middleware/src
WALLET_ADDR="agoric...."
FROM=$WALLET_ADDR EI_CHAINLINKURL=http://IP:6691 ./bin-middleware.js
```


## Step 8: Adding Job to CL node


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

## Step 9: Query updated price

Run the following

```bash
agd query vstorage data published.priceFeed.ATOM-USD_price_feed
```
