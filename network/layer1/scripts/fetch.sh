#!/bin/bash

. scripts/env.sh

function fetchBlock() {
    ORGNAME=$1
    PORT=$2
    BLOCKNO=$3

    setGlobals $ORGNAME $PORT
    peer channel fetch $BLOCKNO block.pb -o orderer1.layer1.chains:7001 --ordererTLSHostnameOverride orderer1.layer1.chains -c chains --tls --cafile "$ORDERER_CA"
    configtxlator proto_decode --input block.pb --type common.Block --output block.json

}

ORGNAME=$1
PORT=$2
BLOCKNO=$3

fetchBlock $ORGNAME $PORT $BLOCKNO

