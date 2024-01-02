#!/bin/bash

# The execution environment
export PATH="$PWD/../../fabric-bin:$PATH"
# create genesis block using configtxgen
export FABRIC_CFG_PATH=${PWD}/../cert/config
# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

export ORDERER1_CA=${PWD}/../cert/chains/ordererOrganizations/ord01.chains/tlsca/tlsca.ord01.chains-cert.pem
export ORDERER2_CA=${PWD}/../cert/chains/ordererOrganizations/ord02.chains/tlsca/tlsca.ord02.chains-cert.pem
export ORDERER3_CA=${PWD}/../cert/chains/ordererOrganizations/ord03.chains/tlsca/tlsca.ord03.chains-cert.pem

export CHANNEL_NAME=chains

# Set environment variables for the peer org
function setGlobals() {
    # setGlobals orgname, port
    local orgname=$1
    local port=$2
    export CORE_PEER_TLS_ENABLED=true # enable TLS
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/${orgname}.chains/tlsca/tlsca.${orgname}.chains-cert.pem
    export CORE_PEER_LOCALMSPID="${orgname}MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../cert/chains/peerOrganizations/${orgname}.chains/users/Admin@${orgname}.chains/msp
    export CORE_PEER_ADDRESS=localhost:${port}
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
    # single organization setup
    setGlobals $1 $2
}
