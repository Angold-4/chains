#!/bin/bash

# Enable the environment variable
. scripts/env.sh

createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb --output config_update.pb
  configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  { set +x; } 2>/dev/null
}

fetchChannelConfig() {
    ORG=$1
    CHANNEL=$2
    OUTPUT=$3

    setGlobals $ORG # 6001

    set -x
    peer channel fetch config config_block.pb -o orderer1.layer1.chains:7001 --ordererTLSHostnameOverride orderer1.layer1.chains -c $CHANNEL --tls --cafile "$ORDERER_CA"
    { set +x; } 2>/dev/null

    set -x
    configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
    jq .data.data[0].payload.data.config config_block.json >"${OUTPUT}"
    { set +x; } 2>/dev/null
}

# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
createAnchorPeerUpdate() {
    fetchChannelConfig 6001 $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

    HOST="peer1.layer1.chains"
    PORT=6001

    set -x
    # Modify the configuration to append the anchor peer 
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
    { set +x; } 2>/dev/null

    # Compute a config update, based on the differences between 
    # {orgmsp}config.json and {orgmsp}modified_config.json, write
    # it as a transaction to {orgmsp}anchors.tx
    createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o orderer1.layer1.chains:7001 --ordererTLSHostnameOverride orderer1.layer1.chains -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
}

setGlobalsCLI

createAnchorPeerUpdate

updateAnchorPeer
