#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash
echo -e "${CYAN}Starting Docker and Capfizz setup...${NC}"
sleep 2

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}" ;;
    esac
    echo -e "-----------------------------------------------------\n"
}

log "INFO" "Updating package list and installing basic packages..."
apt update
log "SUCCESS" "Package list updated."

apt upgrade -y
log "SUCCESS" "Basic packages installed."

log "INFO" "Installing dependencies for Dockerfile build..."
apt install -y \
    curl \
    unzip \
    wget \
    ca-certificates \
    libnss3 \
    libxss1 \
    libatk-bridge2.0-0 \
    libasound2 \
    && apt clean
log "SUCCESS" "Dependencies installed."

log "INFO" "Creating directory for Docker build context..."
mkdir -p ~/capfizz-docker
cd ~/capfizz-docker

log "INFO" "Downloading Capfizz extension zip file..."
curl -L -o "$HOME/Capfizz-sentry-node-Chrome-Web-Store.zip" "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "SUCCESS" "Capfizz extension zip file downloaded."

log "INFO" "Creating Dockerfile..."
cat <<EOF > Dockerfile
# Use the official Ubuntu base image
FROM ubuntu:20.04

# Set the user to root
USER root

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and utilities
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    unzip \
    libnss3 \
    libxss1 \
    libatk-bridge2.0-0 \
    libasound2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install Capfizz Chrome Web Store extension
RUN mkdir -p /app/extensions && \
    curl -L -o /app/extensions/capfizz.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip" && \
    unzip /app/extensions/capfizz.zip -d /app/extensions && \
    rm /app/extensions/capfizz.zip

# Set the working directory
WORKDIR /app

# Expose the desired port (20320)
EXPOSE 20320

# Run the necessary command to start the service (without Chromium)
CMD ["node", "app.js"]
EOF
log "SUCCESS" "Dockerfile created."

log "INFO" "Building Docker container for Capfizz..."
docker build -t capfizz-new-image ~/capfizz-docker
log "SUCCESS" "Capfizz container built with image name 'capfizz-new-image'."

read -p "Enter port for web listening (default 20320): " WEB_LISTENING_PORT
WEB_LISTENING_PORT=${WEB_LISTENING_PORT:-20320}

log "INFO" "Running Docker container for Capfizz on port $WEB_LISTENING_PORT..."
docker run -d \
   --restart unless-stopped \
   --name capfizz \
   -p $WEB_LISTENING_PORT:$WEB_LISTENING_PORT \
   capfizz-new-image
log "SUCCESS" "Capfizz container running with name 'capfizz' on port $WEB_LISTENING_PORT."

log "INFO" "Configuring firewall..."
sudo ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured to allow access to port $WEB_LISTENING_PORT."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="https://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup complete! Browser opened at $URL."
