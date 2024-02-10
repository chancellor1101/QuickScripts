#!/bin/bash

# Set the source directory where Wazuh archive files are stored
source_base_dir="/var/ossec/logs/archives/"

# Set the destination directory
destination_base_dir="/mnt/wasabi/"

# Calculate the year for the archive folder based on today's date minus 24 hours
year=$(date -d "-24 hours" +"%Y")

# Construct the source directory path with the calculated year
source_dir="${source_base_dir}${year}/"

#Update destination folder to match current
destination_dir="${destination_base_dir}${year}"

# Move archive files to the destination directory
mv "$source_dir"* "$destination_dir"

# Optional: You may want to add logging to keep track of the script's execution.
# Example: 
echo "Wazuh archive files for year $year moved to $destination_dir at $(date)" >> /var/log/wazuh_archive.log

# Optional: You may want to add error handling in case the move operation fails.
# Example:
if [ $? -eq 0 ]; then
    echo "Move operation completed successfully."
else
    echo "Error: Move operation failed." >&2
fi

