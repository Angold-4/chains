#!/bin/bash

# Directory containing the files
folder_path="vegeta/bins"

# Base URL for the MinIO servers without the port
base_url="http://192.168.50.29"

repeat_count=10

# Ports for the MinIO servers
ports=(10001 10002 10003 10004 10005 10006 10007 10008)

# File to store the targets
targets_file="vegeta/targets.txt"

# Clear the targets file
> $targets_file

# Helper function to get a random port
get_random_port() {
  echo ${ports[$RANDOM % ${#ports[@]}]}
}

for (( i=1; i<=repeat_count; i++ ))
do
  # Iterate over each file in the folder
  for file in "$folder_path"/*
  do
    if [ -f "$file" ]; then
      # Extract filename
      filename=$(basename "$file")

    # Randomly select a port for the MinIO server
    port=$(get_random_port)

    # Append PUT request with a random port to targets file
    echo "PUT $base_url:$port/bench/$filename" >> $targets_file
    echo "@$file" >> $targets_file
    echo "" >> $targets_file

    # Append DELETE request with the same random port to targets file
    echo "DELETE $base_url:$port/bench/$filename" >> $targets_file
    echo "" >> $targets_file
    fi
  done
done

echo "targets.txt has been created."

