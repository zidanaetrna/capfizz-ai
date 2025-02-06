#!/bin/bash
set -e

# Warna terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Tampilkan Logo
curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash

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

# Memeriksa dan menginstal Docker jika belum ada
log "INFO" "Memeriksa dan menginstal Docker jika belum ada..."
if ! command -v docker &> /dev/null; then
    log "INFO" "Docker tidak ditemukan, menginstal..."
    apt update && apt install -y docker.io
    systemctl start docker
    systemctl enable docker
    log "SUCCESS" "Docker berhasil diinstal."
else
    log "SUCCESS" "Docker sudah terinstal."
fi

# Unduh Dockerfile dari GitHub
log "INFO" "Mengunduh Dockerfile dari GitHub..."
curl -o Dockerfile https://raw.githubusercontent.com/zidanaetrna/capfizz-ai/capfizz-ai/DockerFile

log "SUCCESS" "Dockerfile berhasil diunduh."

# Unduh package.json dari GitHub
log "INFO" "Mengunduh package.json dari GitHub..."
curl -o package.json https://raw.githubusercontent.com/zidanaetrna/capfizz-ai/capfizz-ai/package.json

log "SUCCESS" "package.json berhasil diunduh."

# Bangun container Docker
log "INFO" "Membangun container Docker untuk Capfizz AI..."
docker build -t capfizz-ai .

# Jalankan container
log "INFO" "Menjalankan container Capfizz AI pada port 20320..."
docker run -d \
   --restart unless-stopped \
   --name capfizz-ai \
   -p 20320:80 \
   capfizz-ai

log "SUCCESS" "Capfizz AI telah berjalan di port 20320."

# Tampilkan URL akses
IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="http://$IP_ADDRESS:20320/"
log "SUCCESS" "Setup selesai! Buka browser dan akses: $URL"

