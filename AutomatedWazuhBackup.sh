#!/bin/bash

# Set variables for current date and destination folder
current_date=$(date +%Y-%m)
destination_folder="/mnt/wasabi/$current_date"

# Create the destination folder if it doesn't exist
mkdir -p "$destination_folder"

# Find all files with the specified extensions
find . -type f \( -name "*.sum" -or -name "*.gz" \) -exec mv -t "$destination_folder" {} \;

echo "Files moved successfully to $destination_folder"
