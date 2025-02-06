#!/bin/bash
set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Display custom logo
curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash
echo -e "${CYAN}Starting Docker and Capfizz installation...${NC}"
sleep 2

# Function to log messages with different levels
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

# Update package list and install basic packages
log "INFO" "Updating package list and installing basic packages..."
apt update
log "SUCCESS" "Package list updated."

apt upgrade -y
log "SUCCESS" "Basic packages installed."

# Download the Capfizz extension zip file
log "INFO" "Downloading Capfizz extension zip file..."
curl -L -o "$HOME/Capfizz-sentry-node-Chrome-Web-Store.zip" "https://github.com/zidanaetrna/capfizz-ai/raw/refs/heads/capfizz-ai/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "SUCCESS" "Capfizz extension zip file downloaded."

# Create directory for Capfizz and extract the zip file
log "INFO" "Creating directory for Capfizz and extracting zip file..."
mkdir -p $HOME/Capfizz && cd $HOME/Capfizz

if ! command -v unzip &> /dev/null; then
    log "INFO" "Unzip not installed. Installing unzip..."
    apt install unzip -y
    log "SUCCESS" "Unzip installed."
fi

unzip "$HOME/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "SUCCESS" "Capfizz extension extracted."

# Remove the zip file after extraction
rm "$HOME/Capfizz-sentry-node-Chrome-Web-Store.zip"
log "INFO" "Removed Capfizz extension zip file after extraction."

# Prompt for web listening port
read -p "Enter port for web listening (default 7700): " WEB_LISTENING_PORT
WEB_LISTENING_PORT=${WEB_LISTENING_PORT:-7700}

# Build and run Docker container for Capfizz
log "INFO" "Building Docker container for Capfizz..."
docker build -t winsnip/capfizz:latest . && \
docker run -d \
   --restart unless-stopped \
   --name capfizz \
   --network host \
   -v "$HOME/appdata/capfizz:/config" \
   -e USER_ID="$(id -u)" \
   -e GROUP_ID="$(id -g)" \
   -e WEB_LISTENING_PORT="$WEB_LISTENING_PORT" \
   winsnip/capfizz:latest
log "SUCCESS" "Capfizz container running with name 'capfizz'."

# Configure firewall
log "INFO" "Configuring firewall..."
sudo ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured to allow access to port $WEB_LISTENING_PORT."

# Display setup completion message
IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="https://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup complete! Browser opened at $URL."
