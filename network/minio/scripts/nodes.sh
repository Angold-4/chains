#!/bin/bash

. env.sh

docker-compose -f ../cert/compose.yaml -d up 2>&1
docker ps -a

