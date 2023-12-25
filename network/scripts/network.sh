#!/bin/bash

# Enable the environment variable
source env.sh

export ORDERER_CA=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem

# println echos string
function println() {
    echo -e "$1"
}

# errorln echos i red color
function errorln() {
    println "${C_RED}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
    errorln "$1"
    exit 1
}

verifyResult() {
    if [ $1 -ne 0 ]; then
	fatalln "$2"
    fi
}

# Set environment variables for the peer org
function setGlobals() {
    export CORE_PEER_TLS_ENABLED=true # enable TLS
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
    export CORE_PEER_LOCALMSPID="layer1MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../cert/chains/peerOrganizations/layer1.chains/users/Admin@layer1.chains/msp
    export CORE_PEER_ADDRESS=localhost:$1
    echo $CORE_PEER_ADDRESS
}

# Create the genesis block in a .block file based on configtx.yaml
function createGenesisBlock() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
	echo "configtxgen tool not found."
    fi
    configtxgen -profile Raft -outputBlock ../channel-artifacts/layer1.block -channelID layer1
}

function createChannel() {
    which osnadmin
    if [ "$?" -ne 0 ]; then
	fatalln "osnadmin tool not found."
    fi

    export ORDERER_CA=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/orderers/orderer1.layer1.chains/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/orderers/orderer1.layer1.chains/tls/server.key

    # Create the channel and join orderer1.layer1.chains to the channel.
    osnadmin channel join --channelID layer1 --config-block ${PWD}/../channel-artifacts/layer1.block -o localhost:9201 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >> log.txt 2>&1
}

function joinChannel() {
    setGlobals $1
    local rc=1
    local COUNTER=1
    local DELAY=2
    local MAX_RETRY=3
    export FABRIC_CFG_PATH=${PWD}/../cert/config/
    ## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x # enable detailed logging
    # peer channel
    peer channel join -b ../channel-artifacts/layer1.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
    cat log.txt
    verifyResult $res "After $MAX_RETRY attempts, peer${ORG} has failed to join channel"
}

function stopChannel() {
    # This step will also delete all the data in the network
    docker stop $(docker ps -q)
    docker rm $(docker ps -a -q)
    # Clear all the volumes
    docker volume rm $(docker volume ls -q)
}

# stopChannel
createGenesisBlock
createChannel
joinChannel 6001
joinChannel 6002

