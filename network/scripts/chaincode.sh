#!/bin/bash

. env.sh

# Enable the environment variable
export pkg=$1
export id=$2
export FABRIC_CFG_PATH=${PWD}/../cert/config/
export PEER_CONN_PARMS=()

export TLS_ROOT_CERT=${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt
export PACKAGE="basic_1.0:e4de097efb5be42d96aebc4bde18eea848aad0f5453453ba2aad97f2e41e0d57"

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  ORGNAME=""
  PORT=""
  TLS_ROOTCERT_FILE=""

  while [ "$#" -gt 0 ]; do

    # Check if organization number is a single digit or has multiple digits
    if [ ${#1} -eq 1 ]; then
        PEER="peer1.org0$1" # For single digit, e.g., org1 becomes org01
	ORGNAME="org0$1"
	PORT="600$1"
    else
        PEER="peer1.org$1"  # For multiple digits, e.g., org12 remains org12
	ORGNAME="org$1"
	PORT="60$1"
    fi

    TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/${ORGNAME}.chains/tlsca/tlsca.${ORGNAME}.chains-cert.pem

    setGlobals $ORGNAME $PORT

    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi

    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/${ORGNAME}.chains/tlsca/tlsca.${ORGNAME}.chains-cert.pem
    TLSINFO=(--tlsRootCertFiles "${TLS_ROOTCERT_FILE}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
  echo $PEER_CONN_PARMS
}

function packageChaincode() {
    rm -rf basic.tar.gz
    # peer lifecycle chaincode package basic.tar.gz --path ${PWD}/../../chaincode/atcc/ --lang golang --label basic_1.0
    peer lifecycle chaincode package basic.tar.gz --path ${PWD}/../../../thrprojs/fabric/fabric-samples/asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0
}

# Install the chaincode for peers inside chains
function installChaincode() {
    setGlobals $1 $2
    peer lifecycle chaincode install $pkg
}

function queryInstalled() {
    setGlobals $1 $2
    peer lifecycle chaincode queryinstalled
}

function approveChaincode() {
    setGlobals $1 $2
    local packageID=$3
    peer lifecycle chaincode approveformyorg -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID chains --name basic --version 1.0 --package-id $packageID --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem"
    peer lifecycle chaincode checkcommitreadiness --channelID chains --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --output json
}

function commitChaincode() {
    parsePeerConnectionParameters $@
    # TODO: Hardcoded 7001
    peer lifecycle chaincode commit -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID chains --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" "${PEER_CONN_PARMS[@]}" 
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function queryCommitted() {
    setGlobals $1 $2
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function invokeChaincode() {
    parsePeerConnectionParameters $@
    FABRIC_CFG_PATH=$PWD/../cert/config/
    setGlobals org01 6001
    peer lifecycle chaincode querycommitted --channelID chains --name basic

    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic "${PEER_CONN_PARMS[@]}" -c '{"function":"InitLedger","Args":[]}'

    sleep 3
    echo "GetAllAssets:"
    peer chaincode query -C chains -n basic -c '{"Args":["GetAllAssets"]}'

    sleep 3
    echo "ReadAsset asset6:(peer1)"
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
    sleep 2

    echo "TransferAsset asset6 Christopher"

    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic "${PEER_CONN_PARMS[@]}" -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'

    sleep 2

    echo "ReadAsset asset6:(peer2)"
    setGlobals org02 6002
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'

    sleep 2
    echo "ReadAsset asset6:(peer6)"
    setGlobals org06 6006
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
}

function changeAsset() {
    parsePeerConnectionParameters $@
    FABRIC_CFG_PATH=$PWD/../cert/config/
    setGlobals org01 6001
    peer lifecycle chaincode querycommitted --channelID chains --name basic

    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic "${PEER_CONN_PARMS[@]}" -c '{"function":"TransferAsset","Args":["asset6","AWANG"]}'

    sleep 3

    echo "ReadAsset asset6:(peer2)"
    setGlobals org02 6002
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
}

packageChaincode

function install() {
    installChaincode org01 6001
    installChaincode org02 6002
    installChaincode org03 6003
    installChaincode org04 6004
    installChaincode org05 6005
    installChaincode org06 6006
    installChaincode org07 6007
    installChaincode org08 6008

    queryInstalled org01 6001
    queryInstalled org02 6002
    queryInstalled org03 6003
    queryInstalled org04 6004
    queryInstalled org05 6005
    queryInstalled org06 6006
    queryInstalled org07 6007
    queryInstalled org08 6008
}

function approve() {
    approveChaincode org01 6001 $PACKAGE 7001
    approveChaincode org02 6002 $PACKAGE 7001
    approveChaincode org03 6003 $PACKAGE 7001
    approveChaincode org04 6004 $PACKAGE 7001
    approveChaincode org05 6005 $PACKAGE 7001
    approveChaincode org06 6006 $PACKAGE 7001
    approveChaincode org07 6007 $PACKAGE 7001
    approveChaincode org08 6008 $PACKAGE 7001
}

function commit() {
    commitChaincode 1 2 3 4 5 6 7 8

    queryCommitted org02 6002
    queryCommitted org04 6004
    queryCommitted org06 6006
    queryCommitted org08 6008
}


# install

# approve

# commit

# invokeChaincode 1 2 3 4 5 6 

changeAsset 1 2 3 4 5 6
