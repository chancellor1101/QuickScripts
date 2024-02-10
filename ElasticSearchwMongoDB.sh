#!/bin/bash

# Function to check if a package is installed
package_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to check if a service is running
service_running() {
    systemctl is-active --quiet "$1"
}

# Check if Java is installed
if ! package_installed default-jre; then
    echo "Java not installed. Installing Java..."
    apt-get install default-jre -y
else
    echo "Java is already installed."
fi

# Check Java installation
java -version

# Check if apt-transport-https, uuid-runtime, and pwgen packages are installed
packages=("apt-transport-https" "uuid-runtime" "pwgen")
for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
        echo "$pkg not installed. Installing $pkg..."
        apt-get install "$pkg" -y
    else
        echo "$pkg is already installed."
    fi
done

# Add Elasticsearch GPG key if not added
if ! apt-key list | grep -q "Elasticsearch"; then
    echo "Adding Elasticsearch GPG key..."
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
else
    echo "Elasticsearch GPG key already added."
fi

# Add Elasticsearch repository if not added
if [ ! -f "/etc/apt/sources.list.d/elasticsearch.list" ]; then
    echo "Adding Elasticsearch repository..."
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elasticsearch.list
else
    echo "Elasticsearch repository already added."
fi

# Add MongoDB repository
echo "Adding MongoDB repository..."
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list

# Update package sources
echo "Updating package sources..."
apt-get update -y

# Install Elasticsearch if not installed
if ! package_installed elasticsearch; then
    echo "Installing Elasticsearch..."
    apt-get install elasticsearch -y
else
    echo "Elasticsearch is already installed."
fi

# Install MongoDB
echo "Installing MongoDB..."
apt-get install -y mongodb-org

# Start MongoDB
echo "Starting MongoDB service..."
systemctl start mongod

# Enable MongoDB to start on boot
echo "Enabling MongoDB service to start on boot..."
systemctl enable mongod

# Start and enable Elasticsearch service if not running and enabled
if ! service_running elasticsearch; then
    echo "Starting Elasticsearch service..."
    systemctl start elasticsearch
    systemctl enable elasticsearch
else
    echo "Elasticsearch service is already running and enabled."
fi

# Configuration values for Elasticsearch
cluster_name="graylog"
network_host="127.0.0.1"
ping_timeout="10s"
multicast_enabled="false"
unicast_hosts="[\"127.0.0.1:9300\"]"
script_inline="false"
script_indexed="false"
script_file="false"

# Remove existing elasticsearch.yml file
echo "Removing existing elasticsearch.yml file..."
rm -f /etc/elasticsearch/elasticsearch.yml

# Create a new elasticsearch.yml file with the new configurations
echo "Creating new elasticsearch.yml file..."
cat <<EOF >/etc/elasticsearch/elasticsearch.yml
cluster.name: $cluster_name
network.host: $network_host
discovery.zen.ping.timeout: $ping_timeout
discovery.zen.ping.multicast.enabled: $multicast_enabled
discovery.zen.ping.unicast.hosts: $unicast_hosts
script.inline: $script_inline
script.indexed: $script_indexed
script.file: $script_file
EOF

# Restart Elasticsearch to apply changes
echo "Restarting Elasticsearch service..."
systemctl restart elasticsearch

# Pause for a few seconds to allow Elasticsearch to stabilize
echo "Waiting for Elasticsearch to stabilize..."
sleep 5

echo "Elasticsearch setup completed."
echo "MongoDB setup completed."
