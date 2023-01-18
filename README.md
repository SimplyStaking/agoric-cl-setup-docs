# Setup Guide

This is a step-by-step guide explaining how to set up a Chainlink node and an oracle on Agoric

## Requirements

Make sure you have the following requirements before starting:
1. node (Use version 16.17.0)
2. docker
3. docker-compose
4. jq

## Step 1: Installing Agoric CLI

``` bash
cd ~
node --version # 16.17.0 or higher
sudo npm install --global yarn
git clone https://github.com/agoric/agoric-sdk
cd agoric-sdk
yarn install
yarn build
yarn link-cli ~/bin/agoric
cd packages/cosmic-swingset && make
echo "export PATH=$PATH:$HOME/bin" >> ~/.profile
source ~/.profile
agoric --version
agd version
```

## Step 2: Clone dapp-oracle and install dependencies

Before the setup, we have to run the following

```bash
cd ~
git clone https://github.com/jacquesvcritien/dapp-oracle.git
cd dapp-oracle
git checkout testnet-1
agoric install
```

## Step 3: Clone the middleware's repository

Clone the repository containing the code for the middleware

```bash
cd ~
git clone https://github.com/jacquesvcritien/agoric-cl-middleware.git
cd agoric-cl-middleware
yarn install
```

## Step 4: Create a key and send the address to the chain management team

1. Create an agoric key

REPLACE WALLET_NAME WITH YOUR PREFERRED NAME

```bash
WALLET_NAME=test
agd keys add $WALLET_NAME --keyring-backend=test
```

2. Get the address

```bash
WALLET_ADDR=$(agd keys show "$WALLET_NAME" --keyring-backend test --output json | jq -r .address)
echo "Address: $WALLET_ADDR"
```

3. Send the address to the oracle team

## Step 5: Start a node

1. Download data

```bash
cd ~
wget https://agoric-oracle-snapshot.simplystaking.xyz/snapshot.tar.gz
tar -xvf snapshot.tar.gz
```

2. Create a service file

```bash
sudo tee /etc/systemd/system/agoric-node.service > /dev/null <<EOF  
[Unit]
Description     = agoric node service
Wants           = network-online.target beacon-chain.service
After           = network-online.target 

[Service]
User            = $USER
Environment="DEBUG=SwingSet:ls,SwingSet:vat"
ExecStart       = /home/agoric/go/bin/agd start --log_level=info --home /home/$USER/agoric-node-home --log_level=warn
Restart         = always

[Install]
WantedBy= multi-user.target
EOF
```

3. Start node

```bash
systemctl daemon-reload
systemctl start agoric-node
```

4. Check if the node is still catching up

```bash
echo $(agd status) | jq ".SyncInfo.catching_up"
```

<b>Make sure the above is FALSE before going to the next step</b>

## Step 6: Provision the smart wallet

Once the node is synced, you need to provision the smart wallet

1. Provision the smart wallet

REPLACE WALLET_NAME WITH THE CHOSEN NAME IN STEP 4.1

```bash
cd ~/agoric-cl-middleware
WALLET_NAME=test
./scripts/provision-wallet.sh $WALLET_NAME
```

2. Confirm the smart wallet provision

```bash
agoric wallet show --from "$WALLET_ADDR"
```
## Step 7: Wait a minute or two to ensure that the provisioning is finished

## Step 8: Accepting the oracle invitation

The next step involves accepting the oracle invitation

REPLACE WALLET_NAME WITH THE CHOSEN NAME IN STEP 4.1

```bash
WALLET_NAME=test
ASSET_IN=ATOM
ASSET_OUT=USD
cd ~/agoric-cl-middleware/scripts
./accept-oracle-invitation.sh $WALLET_NAME $ASSET_IN $ASSET_OUT
```

## Step 9: Prepare configs for middleware and monitoring tool

REPLACE ORACLE_NAME WITH YOUR PREFERRED NAME

```bash
cd ~/agoric-cl-middleware
THIS_VM_IP=$(hostname -I | sed 's/ *$//g')
THIS_VM_IP=$(echo ${THIS_VM_IP%% *})
WALLET_ADDR=$(agd keys show "$WALLET_NAME" --keyring-backend test --output json | jq -r .address)
echo "THIS_VM_IP=$THIS_VM_IP" > .env
echo "WALLET_ADDR=$WALLET_ADDR" >> .env

#create config
mkdir -p ~/config
ORACLE_NAME="ORACLE1"
echo "{ \"$WALLET_ADDR\" : { \"oracleName\": \"$ORACLE_NAME\" }}" > ~/config/oracles.json
```

## Step 10: Run setup script

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

## Step 11: Starting the middleware

To start the middleware, run the following commands

```
cd ~/agoric-cl-middleware

#build the images
docker build --tag ag-oracle-middleware -f Dockerfile.middleware .
docker build --tag ag-oracle-monitor -f Dockerfile.monitor .

docker-compose up -d
```


## Step 12: Adding Job to CL node


1. Go to http://IP:6691
2. Log in with the following credentials
```
notreal@fakeemail.ch
twochains
```
3. Add the required bridges and job spec given out by the Simply Staking team

## Step 13: Query updated price

Run the following

```bash
agoric follow :published.priceFeed.ATOM-USD_price_feed
```
