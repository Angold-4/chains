#!/bin/bash

# Enable the environment variable
. env.sh

# If you want to create the certificates for peers and orderers of layer1, using create.sh inside cert/ folder.

# Bring up the docker containers of peers and orders
function nodesUp() {
  # warning if artifacts don't exist
  if [ ! -d "../cert/chains/peerOrganizations" ]; then
    fatalln "Please generate the certificates for your organizations before bring the nodes up."
  fi

  # Two compose files
  COMPOSE_FILES="-f ../cert/compose/compose.yaml -f ../cert/compose/docker/docker-compose.yaml"

  # start the docker container
  # docker-compose ${COMPOSE_FILES} up -d --build > log.txt
  DOCKER_SOCK="${DOCKER_SOCK}" docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

nodesUp



