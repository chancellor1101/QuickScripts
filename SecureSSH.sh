#!/bin/bash

# Function to prompt for a new username if the script is run as root
prompt_for_username() {
    read -p "Enter a new username for SSH access: " NEW_USERNAME
    if [ -z "$NEW_USERNAME" ]; then
        echo "Username cannot be empty. Please try again."
        prompt_for_username
    fi
}

# Ensure script is run as root or non-root user
if [ "$(id -u)" -eq 0 ]; then
    prompt_for_username
else
    CURRENT_USERNAME=$USER
fi

# Backup SSH config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Allow only specific users
echo "AllowUsers $CURRENT_USERNAME" >> /etc/ssh/sshd_config

# Change default SSH port
sed -i 's/^#Port 22/Port 1101/' /etc/ssh/sshd_config

# Use SSH key authentication
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Use protocol version 2 only
sed -i 's/^#Protocol 2/Protocol 2/' /etc/ssh/sshd_config

# Disable empty passwords
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Restrict SSH protocol to specified IP addresses (optional)
# echo "AllowUsers $CURRENT_USERNAME@your_ip_address" >> /etc/ssh/sshd_config

# Limit SSH login attempts
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

echo "SSH has been secured. Make sure to keep your private key secure and accessible only to authorized users."
