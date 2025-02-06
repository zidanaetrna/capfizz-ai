#!/bin/bash
set -e

# Warna terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fungsi logging
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

# Menyiapkan direktori untuk project
log "INFO" "Menyiapkan direktori Capfizz AI..."
mkdir -p $HOME/capfizz-ai && cd $HOME/capfizz-ai

# Mengunduh Dockerfile dari GitHub
log "INFO" "Mengunduh Dockerfile dari repository..."
curl -o Dockerfile https://raw.githubusercontent.com/zidanaetrna/capfizz-ai/capfizz-ai/DockerFile

# Bangun Docker image dari Dockerfile
log "INFO" "Membangun Docker image..."
docker build -t capfizz-ai .

# Jalankan container Docker
log "INFO" "Menjalankan container Capfizz AI pada port 20320..."
docker run -d \
   --restart unless-stopped \
   --name capfizz-ai \
   -p 20320:80 \
   capfizz-ai

log "SUCCESS" "Capfizz AI telah berjalan di port 20320."

# Konfigurasi firewall untuk izinkan port 20320
log "INFO" "Mengizinkan port 20320 di firewall..."
ufw allow 20320/tcp
log "SUCCESS" "Firewall dikonfigurasi untuk port 20320."

# Tampilkan URL akses
IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="http://$IP_ADDRESS:20320/"
log "SUCCESS" "Setup selesai! Buka browser dan akses: \"$URL\""
