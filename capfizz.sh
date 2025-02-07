#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash

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

log "INFO" "Checking Docker installation..."
if ! command -v docker &> /dev/null
then
    log "ERROR" "Docker is not installed. Please install Docker first."
    exit 1
fi
log "SUCCESS" "Docker is already installed."

log "INFO" "Updating package list and installing dependencies..."
apt update && apt upgrade -y
apt install -y curl unzip wget ca-certificates libnss3 libxss1 libatk-bridge2.0-0 nodejs npm chromium-browser
log "SUCCESS" "System updated and dependencies installed."

log "INFO" "Creating directory for Docker build context..."
mkdir -p ~/capfizz-docker
cd ~/capfizz-docker

log "INFO" "Downloading Capfizz extension zip file..."
curl -L -o ./Capfizz-sentry-node-Chrome-Web-Store.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "SUCCESS" "Capfizz extension zip file downloaded."

log "INFO" "Creating Dockerfile..."
cat <<EOF > Dockerfile
# Use Ubuntu as the base image
FROM ubuntu:20.04

# Set environment variables to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including Node.js and headless Chromium
RUN apt-get update && apt-get install -y \\
    curl wget ca-certificates unzip libnss3 libxss1 libatk-bridge2.0-0 nodejs npm \\
    libasound2 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 \\
    libnss3 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 libgbm1 \\
    chromium-browser \\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Download and install Capfizz extension
RUN mkdir -p /app/extensions && \\
    curl -L -o /app/extensions/capfizz.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip" && \\
    unzip /app/extensions/capfizz.zip -d /app/extensions && \\
    rm /app/extensions/capfizz.zip

# Create a script to launch Chromium with the Capfizz extension
RUN echo "chromium-browser --no-sandbox --disable-dev-shm-usage --load-extension=/app/extensions --remote-debugging-port=9222" > /app/start.sh
RUN chmod +x /app/start.sh

# Expose port
EXPOSE 9222

# Run Chromium with Capfizz extension
CMD ["/app/start.sh"]
EOF
log "SUCCESS" "Dockerfile created."

log "INFO" "Building Docker container for Capfizz..."
docker build -t capfizz-chromium-image .
log "SUCCESS" "Capfizz container built."

WEB_LISTENING_PORT="${WEB_LISTENING_PORT:-9222}"

log "INFO" "Running Docker container for Capfizz on port $WEB_LISTENING_PORT..."
docker run -d --restart unless-stopped --name capfizz -p ${WEB_LISTENING_PORT}:${WEB_LISTENING_PORT} capfizz-chromium-image
log "SUCCESS" "Capfizz container is now running."

log "INFO" "Configuring firewall..."
ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="https://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup complete! Open your browser at $URL."
