#!/bin/bash

. env.sh

# Enable the environment variable
export pkg=$1
export id=$2
export FABRIC_CFG_PATH=${PWD}/../cert/config/

export TLS_ROOT_CERT=${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt


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
    setGlobals $1 $2
    peer lifecycle chaincode commit -o localhost:$4 --ordererTLSHostnameOverride orderer1.layer1.chains --channelID chains --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" --peerAddresses localhost:6001 --tlsRootCertFiles "${PWD}/../cert/chains/peerOrganizations/layer1.chains/peers/peer1.layer1.chains/tls/ca.crt"
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function queryCommitted() {
    setGlobals $1 $2
    peer lifecycle chaincode querycommitted --channelID chains --name basic
}

function invokeChaincode() {
    FABRIC_CFG_PATH=$PWD/../cert/config/
    setGlobals org01 6001
    peer lifecycle chaincode querycommitted --channelID chains --name basic
    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic --peerAddresses localhost:6001 --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --peerAddresses localhost:6002 --peerAddresses localhost:6003 --peerAddresses localhost:6004 --peerAddresses localhost:6005 --peerAddresses localhost:6006 --peerAddresses localhost:6007 --peerAddresses localhost:6008 -c '{"function":"InitLedger","Args":[]}'
    sleep 2
    echo "GetAllAssets:"
    peer chaincode query -C chains -n basic -c '{"Args":["GetAllAssets"]}'
    sleep 2

    echo "ReadAsset asset6:(peer1)"
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
    sleep 2

    echo "TransferAsset asset6 Christopher"
    peer chaincode invoke -o localhost:7001 --ordererTLSHostnameOverride orderer1.layer1.chains --tls --cafile "${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem" -C chains -n basic --peerAddresses localhost:6001 --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --tlsRootCertFiles $TLS_ROOT_CERT --peerAddresses localhost:6002 --peerAddresses localhost:6003 --peerAddresses localhost:6004 --peerAddresses localhost:6005 --peerAddresses localhost:6006 --peerAddresses localhost:6007 --peerAddresses localhost:6008 -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'

    sleep 2

    echo "ReadAsset asset6:(peer2)"
    setGlobals org02 6002
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'

    sleep 2
    echo "ReadAsset asset6:(peer6)"
    setGlobals org06 6006
    peer chaincode query -C chains -n basic -c '{"Args":["ReadAsset","asset6"]}'
}

packageChaincode

function installChaincodes() {
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

function approveChaincode() {
    approveChaincode 1 6001 basic_1.0:e4de097efb5be42d96aebc4bde18eea848aad0f5453453ba2aad97f2e41e0d57 7001
    commitChaincode 1 6001 x 7001

    queryCommitted 2 6002
    queryCommitted 4 6004
    queryCommitted 6 6006
    queryCommitted 8 6008

    invokeChaincode
}


installChaincodes
