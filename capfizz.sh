#!/bin/bash
set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Tampilkan Logo
curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash

echo -e "${CYAN}Starting Docker and Capfizz AI Web Generator...${NC}"
sleep 2

# Fungsi log untuk output berwarna
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

# Update sistem dan install dependensi
log "INFO" "Memperbarui daftar paket dan menginstal paket dasar..."
sudo apt update && sudo apt upgrade -y
log "SUCCESS" "Sistem diperbarui."

# Install Docker jika belum ada
if ! command -v docker &> /dev/null; then
    log "INFO" "Docker tidak ditemukan, menginstal Docker..."
    sudo apt install -y docker.io
    log "SUCCESS" "Docker berhasil diinstal."
fi

# Download Capfizz AI
log "INFO" "Mengunduh Capfizz AI dari repository..."
mkdir -p $HOME/capfizz && cd $HOME/capfizz
git clone https://github.com/zidanaetrna/capfizz-ai.git .
log "SUCCESS" "Capfizz AI berhasil diunduh."

# Build dan Run Docker Container untuk Capfizz AI
log "INFO" "Membangun dan menjalankan container Capfizz AI..."
docker build -t capfizz/ai:latest .
docker run -d \
   --restart unless-stopped \
   --name capfizz-ai \
   --network host \
   -v "$HOME/appdata/capfizz:/config" \
   -e USER_ID="$(id -u)" \
   -e GROUP_ID="$(id -g)" \
   -e WEB_LISTENING_PORT="20320" \
   capfizz/ai:latest
log "SUCCESS" "Capfizz AI berjalan di port 20320."

# Konfigurasi Firewall
log "INFO" "Mengonfigurasi firewall untuk Capfizz AI..."
sudo ufw allow 20320/tcp
log "SUCCESS" "Firewall dikonfigurasi."

# Dapatkan IP VPS
IP_ADDRESS=$(hostname -I | awk '{print $1}')
REGISTER_URL="https://mainnet.capfizz.com/register?ref=GFMNDF&server=$IP_ADDRESS"

# Menampilkan informasi akhir
log "SUCCESS" "Setup selesai! Akses website di:"
echo -e "${GREEN}http://$IP_ADDRESS:20320/${NC}"
echo -e "${YELLOW}Daftar dengan referal: $REGISTER_URL${NC}"
