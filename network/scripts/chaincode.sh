#!/bin/bash

source env.sh

# Enable the environment variable
export pkg=$1
export id=$2
export FABRIC_CFG_PATH=${PWD}/../cert/config/

function setChaincodeLayer1() {
    local name=$1
    local port=$2
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="layer1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../cert/chains/peerOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../cert/chains/peerOrganizations/layer1.chains/users/Admin@layer1.chains/msp
    export CORE_PEER_ADDRESS=localhost:$port
}

function packageChaincode() {
    rm -rf basic.tar.gz
    peer lifecycle chaincode package basic.tar.gz --path ${PWD}/../../../thrprojs/fabric/fabric-samples/asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0
}

# Install the chaincode for peers inside layer1
function installChaincodeLayer1() {
    setChaincodeLayer1 $1 $2
    peer lifecycle chaincode install $pkg
}

function queryInstalled() {
    setChaincodeLayer1 $1 $2
    peer lifecycle chaincode queryinstalled
}

function approveChaincode() {
    setChaincodeLayer1 $1 $2
    local packageID=$3
    peer lifecycle chaincode approveformyorg -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID layer1 --name basic --version 1.0 --package-id $packageID --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem"
    peer lifecycle chaincode checkcommitreadiness --channelID layer1 --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --output json
}

function commitChaincode() {
    setChaincodeLayer1 $1 $2
    peer lifecycle chaincode commit -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID layer1 --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt"
    peer lifecycle chaincode querycommitted --channelID layer1 --name basic
}

function invokeChaincode() {
    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C layer1 -n basic --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt" --peerAddresses localhost:6002 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer2.layer1.chains/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'
    peer chaincode query -C layer1 -n basic -c '{"Args":["GetAllAssets"]}'
}

packageChaincode
installChaincodeLayer1 1 6001
installChaincodeLayer1 2 6002
queryInstalled 1 6001
queryInstalled 2 6002
approveChaincode 1 6001 basic_1.0:e4de097efb5be42d96aebc4bde18eea848aad0f5453453ba2aad97f2e41e0d57 7001
commitChaincode 1 6001 x 7001
invokeChaincode





