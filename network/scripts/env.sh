#!/bin/bash

# The execution environment
export PATH="$PWD/../../fabric-bin:$PATH"
# create genesis block using configtxgen
export FABRIC_CFG_PATH=${PWD}/../cert/configtx
export SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
export DOCKER_SOCK="${SOCK##unix://}"
export ORDERER_CA=${PWD}/../cert/chains/ordererOrganizations/layer1.chains/tlsca/tlsca.layer1.chains-cert.pem
# export CORE_PEER_GOSSIP_BOOTSTRAP="127.0.0.1:6001 127.0.0.1:6002"
export CORE_PEER_GOSSIP_BOOTSTRAP="peer1.layer1.chains:6001"

