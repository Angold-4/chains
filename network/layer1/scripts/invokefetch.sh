#!/bin/bash

. env.sh

docker exec cli ./scripts/fetch.sh $1 $2 $3
docker exec cli cat block.json
