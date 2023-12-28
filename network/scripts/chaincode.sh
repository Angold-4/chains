#!/bin/bash

. env.sh

# Enable the environment variable
export pkg=$1
export id=$2
export FABRIC_CFG_PATH=${PWD}/../cert/config/

function setChaincode() {
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
    # peer lifecycle chaincode package basic.tar.gz --path ${PWD}/../../chaincode/atcc/ --lang golang --label basic_1.0
    peer lifecycle chaincode package basic.tar.gz --path ${PWD}/../../../thrprojs/fabric/fabric-samples/asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0
}

# Install the chaincode for peers inside chains
function installChaincode() {
    setChaincode $1 $2
    peer lifecycle chaincode install $pkg
}

function queryInstalled() {
    setChaincode $1 $2
    peer lifecycle chaincode queryinstalled
}

function approveChaincode() {
    setChaincode $1 $2
    local packageID=$3
    peer lifecycle chaincode approveformyorg -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID chains --name basic --version 1.0 --package-id $packageID --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem"
    peer lifecycle chaincode checkcommitreadiness --channelID chains --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --output json
}

function commitChaincode() {
    setChaincode $1 $2
    peer lifecycle chaincode commit -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID chains --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt"
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function queryCommitted() {
    setChaincode $1 $2
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function invokeChaincode() {
    FABRIC_CFG_PATH=$PWD/../cert/config/
    setChaincode 1 6001
    peer lifecycle chaincode querycommitted --channelID chains --name basic
    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt" --peerAddresses localhost:6002 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer2.layer1.chains/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'
    sleep 2
    echo "GetAllAssets:"
    peer chaincode query -C chains -n basic -c '{"Args":["GetAllAssets"]}'
    sleep 2

    echo "ReadAsset asset6:(peer1)"
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
    sleep 2

    echo "TransferAsset asset6 Christopher"
    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt" --peerAddresses localhost:6002 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer2.layer1.chains/tls/ca.crt" -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'
    sleep 2

    echo "ReadAsset asset6:(peer2)"
    setChaincode 2 6002
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
}

packageChaincode
installChaincode 1 6001
installChaincode 2 6002
queryInstalled 1 6001
queryInstalled 2 6002
approveChaincode 1 6001 basic_1.0:e4de097efb5be42d96aebc4bde18eea848aad0f5453453ba2aad97f2e41e0d57 7001
commitChaincode 1 6001 x 7001
queryCommitted 2 6002
invokeChaincode





