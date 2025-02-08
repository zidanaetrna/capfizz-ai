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
apt install -y curl unzip wget ca-certificates libnss3 libxss1 libatk-bridge2.0-0 nodejs npm 
log "SUCCESS" "System updated and dependencies installed."

log "INFO" "Creating directory for Docker build context..."
mkdir -p ~/capfizz-docker
cd ~/capfizz-docker

log "INFO" "Downloading Capfizz extension zip file..."
curl -L -o ./Capfizz-extension.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip"
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
    chromium-driver chromium-browser \\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Puppeteer and Express.js
RUN npm install -g puppeteer express

# Create working directory
WORKDIR /app

# Extract Capfizz extension
RUN mkdir -p /app/extensions/capfizz && \\
    curl -L -o /app/extensions/capfizz.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip" && \\
    unzip /app/extensions/capfizz.zip -d /app/extensions/capfizz && \\
    rm /app/extensions/capfizz.zip

# Create an Express.js web server to serve the extension
RUN echo "const express = require('express'); \\
const puppeteer = require('puppeteer'); \\
const app = express(); \\
const PORT = 20320; \\
app.use(express.static('/app/extensions/capfizz')); \\
app.get('/', (req, res) => res.sendFile('/app/extensions/capfizz/index.html')); \\
app.listen(PORT, () => console.log(\`Capfizz extension running at http://localhost:\${PORT}\`)); \\
(async () => { \\
    const browser = await puppeteer.launch({ \\
        headless: false, \\
        args: ['--no-sandbox', '--disable-setuid-sandbox', \\
               '--disable-extensions-except=/app/extensions/capfizz', \\
               '--load-extension=/app/extensions/capfizz'], \\
        executablePath: '/usr/bin/chromium-browser' \\
    }); \\
    console.log('Capfizz extension loaded in Chromium!'); \\
})();" > /app/start.js

# Expose port
EXPOSE 20320

# Run Express.js server with Puppeteer
CMD ["node", "start.js"]
EOF
log "SUCCESS" "Dockerfile created."

log "INFO" "Building Docker container for Capfizz..."
docker build -t capfizz-new-image . 
log "SUCCESS" "Capfizz container built."

WEB_LISTENING_PORT="${WEB_LISTENING_PORT:-20320}"

log "INFO" "Running Docker container for Capfizz on port $WEB_LISTENING_PORT..."
docker run -d --restart unless-stopped --name capfizz-new-container -p ${WEB_LISTENING_PORT}:${WEB_LISTENING_PORT} capfizz-new-image
log "SUCCESS" "Capfizz container is now running."

log "INFO" "Configuring firewall..."
ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="http://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup complete! Open your browser at $URL."
