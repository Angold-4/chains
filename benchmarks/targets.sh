#!/bin/bash

# Directory containing the files
folder_path="vegeta/bins"

# Base URL for the MinIO server
base_url="http://192.168.50.29:10001/trial"

# File to store the targets
targets_file="vegeta/targets.txt"

# Clear the targets file
> $targets_file

# Iterate over each file in the folder
for file in "$folder_path"/*
do
    if [ -f "$file" ]; then
        # Extract filename
        filename=$(basename "$file")

        # Append target to targets file
        echo "PUT $base_url/$filename" >> $targets_file
        echo "@$file" >> $targets_file
        echo "" >> $targets_file
    fi
done

echo "targets.txt has been created."
