#!/bin/bash

# The execution environment
export PATH="$PWD/../../fabric-bin:$PATH"
# create genesis block using configtxgen
export FABRIC_CFG_PATH=${PWD}/../cert/config
# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"
export ORDERER_CA=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
export CHANNEL_NAME=chains

# Set environment variables for the peer org
function setGlobals() {
    export CORE_PEER_TLS_ENABLED=true # enable TLS
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
    export CORE_PEER_LOCALMSPID="layer1MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../cert/chains/peerOrganizations/layer1.chains/users/Admin@layer1.chains/msp
    export CORE_PEER_ADDRESS=localhost:$1
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
    # single organization setup
    setGlobals 6001
    export CORE_PEER_ADDRESS=peer1.layer1.chains:6001
}
