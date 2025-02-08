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
apt install -y curl unzip wget ca-certificates libnss3 libxss1 libatk-bridge2.0-0 chromium-browser
log "SUCCESS" "System updated and dependencies installed."

log "INFO" "Creating directory for extension..."
mkdir -p ~/capfizz-extension
cd ~/capfizz-extension

log "INFO" "Downloading Capfizz extension zip file..."
curl -L -o ./Capfizz-sentry-node-Chrome-Web-Store.zip "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "SUCCESS" "Capfizz extension zip file downloaded."

log "INFO" "Extracting Capfizz extension..."
unzip -o ./Capfizz-sentry-node-Chrome-Web-Store.zip -d ~/capfizz-extension
log "SUCCESS" "Capfizz extension extracted."

log "INFO" "Running Chromium with the Capfizz extension..."
chromium-browser --headless --disable-gpu --remote-debugging-port=9222 --load-extension=$HOME/capfizz-extension &
log "SUCCESS" "Chromium is running with the Capfizz extension."

WEB_LISTENING_PORT=20320
log "INFO" "Configuring firewall..."
ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="http://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup complete! Open your browser at $URL."
