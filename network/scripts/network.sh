#!/bin/bash

# Enable the environment variable
. env.sh

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

# Create the genesis block in a .block file based on configtx.yaml
function createGenesisBlock() {
    setGlobals 6001 #?
    which configtxgen
    if [ "$?" -ne 0 ]; then
	echo "configtxgen tool not found."
    fi
    configtxgen -profile Raft -outputBlock ../channel-artifacts/chains.block -channelID chains
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
    osnadmin channel join --channelID chains --config-block ${PWD}/../channel-artifacts/chains.block -o localhost:9201 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
    osnadmin channel list --channelID chains -o localhost:9201 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
}

function joinChannel() {
    setGlobals $1 $2
    local rc=1
    local COUNTER=1
    local DELAY=2
    local MAX_RETRY=3
    ## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x # enable detailed logging
    # peer channel
    peer channel join -b ../channel-artifacts/chains.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
    cat log.txt
    verifyResult $res "After $MAX_RETRY attempts, peer${ORG} has failed to join channel"
}

function setAnchorPeer() {
    docker exec cli ./scripts/anchor.sh $1 $2
}

createGenesisBlock
createChannel

function joinChannels() {
    joinChannel org01 6001
    joinChannel org02 6002
    joinChannel org03 6003
    joinChannel org04 6004
    joinChannel org05 6005
    joinChannel org06 6006
    joinChannel org07 6007
    joinChannel org08 6008
}

function setAnchorPeers() {
    setAnchorPeer org01 6001
    setAnchorPeer org02 6002
    setAnchorPeer org03 6003
    setAnchorPeer org04 6004
    setAnchorPeer org05 6005
    setAnchorPeer org06 6006
    setAnchorPeer org07 6007
    setAnchorPeer org08 6008
}

joinChannels
setAnchorPeers
