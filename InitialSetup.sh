#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [-u <username>] [-p <password>] [-g <groupname>] [-m <manager_ip>] [-h <hostname>]" 1>&2 
    exit 1
}

# Initialize variables
username=""
password=""
groupname=""
manager=""
hostname=""

# Parse arguments
while getopts ":u:p:g:m:h:" opt; do
    case ${opt} in
        u )
            username=$OPTARG
            ;;
        p )
            password=$OPTARG
            ;;
        g )
            groupname=$OPTARG
            ;;
        m )
            manager=$OPTARG
            ;;
        h )
            hostname=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Update package lists
echo "Updating package lists..."
sudo apt-get update
echo "Package lists updated."

# Upgrade installed packages
echo "Upgrading installed packages..."
sudo apt-get upgrade -y
echo "Packages upgraded."

# Perform distribution upgrade
echo "Performing distribution upgrade..."
sudo apt-get dist-upgrade -y
echo "Distribution upgraded."

# Change hostname if provided
if [ -n "$hostname" ]; then
    echo "Changing hostname to $hostname..."
    sudo hostnamectl set-hostname $hostname
    echo "Hostname changed."
fi

# Reboot if necessary
if [ -f /var/run/reboot-required ]; then
    echo "Reboot is required."
    read -p "Do you want to reboot now? (y/n): " choice
    case "$choice" in 
      y|Y ) sudo reboot;;
      n|N ) echo "You chose not to reboot."; exit;;
      * ) echo "Invalid choice. You chose not to reboot."; exit;;
    esac
fi

# Add user if username and password provided
if [ -n "$username" ] && [ -n "$password" ]; then
    echo "Adding user $username with password $password..."
    sudo useradd -m $username
    echo "$username:$password" | sudo chpasswd
    echo "User $username added."

    echo "Granting sudo permissions to $username..."
    sudo usermod -aG sudo $username
    echo "Sudo permissions granted to $username."

    # Modify SSH configuration
    echo "Modifying SSH configuration..."
    sudo sed -i 's/^Port .*/Port 1101/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "SSH configuration modified."

    echo "Restarting SSH service..."
    sudo systemctl restart sshd
    echo "SSH service restarted."

    # Install and configure Wazuh agent if groupname provided
    if [ -n "$groupname" ] && [ -n "$manager" ]; then
        echo "Downloading Wazuh agent..."
        wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.2-1_amd64.deb
        echo "Installing Wazuh agent..."
        sudo WAZUH_MANAGER="$manager" WAZUH_AGENT_GROUP="$groupname" dpkg -i ./wazuh-agent_4.7.2-1_amd64.deb
        echo "Reloading daemon..."
        sudo systemctl daemon-reload
        echo "Enabling Wazuh agent..."
        sudo systemctl enable wazuh-agent
        echo "Starting Wazuh agent..."
        sudo systemctl start wazuh-agent
    else
        echo "No group name or manager IP provided. Not installing Wazuh agent."
    fi
else
    echo "No username and password provided. Not modifying SSH configuration or installing Wazuh agent."
fi
