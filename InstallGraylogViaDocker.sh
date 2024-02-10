#!/bin/bash
set -e

echo "Updating package index..."
sudo apt update

echo "Installing required dependencies..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git gnupg2

echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

echo "Adding Docker repository to APT sources..."
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

echo "Updating the package index again..."
sudo apt update

echo "Installing Docker CE..."
sudo apt install -y docker-ce

echo "Downloading Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

echo "Applying executable permissions to Docker Compose binary..."
sudo chmod +x /usr/local/bin/docker-compose

echo "Verifying Docker and Docker Compose installation..."
docker --version
docker-compose --version

echo "Installing Git..."
sudo apt install -y git

echo "Cloning the Graylog Docker Compose repository..."
git clone https://github.com/Graylog2/docker-compose.git

echo "Renaming .env.example to .env..."
mv docker-compose/open-core/.env.example docker-compose/open-core/.env

# Generate a random 96-character string for GRAYLOG_PASSWORD_SECRET
random_secret=$(openssl rand -hex 64)

echo "Setting GRAYLOG_PASSWORD_SECRET to a random 96-character string..."
sed -i "s/^GRAYLOG_PASSWORD_SECRET=.*/GRAYLOG_PASSWORD_SECRET=$random_secret/" docker-compose/open-core/.env


# Prompt for password
read -s -p "Enter your password: " password
echo

# Hash password using SHA-256
password_sha256=$(echo -n "$password" | shasum -a 256 | awk '{print $1}')

echo "Setting GRAYLOG_ROOT_PASSWORD_SHA2 to $password_sha256"
sed -i "s/^GRAYLOG_ROOT_PASSWORD_SHA2=.*/GRAYLOG_ROOT_PASSWORD_SHA2=$password_sha256/" docker-compose/open-core/.env

echo "Running docker-compose up -d..."
cd docker-compose/open-core/
docker-compose up -d

echo "Docker and Docker Compose have been successfully installed, and the Graylog Docker Compose repository has been cloned. The .env file has been renamed, GRAYLOG_ROOT_PASSWORD_SHA2 has been set, and docker-compose up -d has been executed."
