#!/bin/bash

# Just for creating the scripts for benchmarking environment
# The execution environment
export PATH="$PWD/../../fabric-bin:$PATH"

# generate key materials for layer 1 peers
rm -rf chains/*
cryptogen generate --config=layer1.yaml --output="chains"
cryptogen generate --config=orderers.yaml --output="chains"
 
