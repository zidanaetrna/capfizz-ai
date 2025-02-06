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

# Update dan upgrade sistem
log "INFO" "Memperbarui dan mengupgrade sistem..."
apt update -y && apt upgrade -y
log "SUCCESS" "Sistem berhasil diperbarui."

# Instalasi utilitas dasar
log "INFO" "Menginstal utilitas dasar..."
apt install -y curl ufw sudo gnupg lsb-release
log "SUCCESS" "Utilitas dasar berhasil diinstal."

# Periksa dan instal Docker jika belum ada
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

# Periksa status Docker
log "INFO" "Memeriksa status Docker..."
systemctl is-active --quiet docker && log "SUCCESS" "Docker service berjalan." || log "ERROR" "Docker service tidak berjalan."

# Buat direktori untuk project
log "INFO" "Mempersiapkan direktori Capfizz AI..."
mkdir -p $HOME/capfizz-ai && cd $HOME/capfizz-ai

# Unduh Dockerfile dari GitHub
log "INFO" "Mengunduh Dockerfile dari GitHub..."
curl -o Dockerfile https://raw.githubusercontent.com/zidanaetrna/capfizz-ai/capfizz-ai/DockerFile

log "SUCCESS" "Dockerfile berhasil diunduh."

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

# Konfigurasi firewall
log "INFO" "Mengizinkan port 20320 di firewall..."
ufw allow 20320/tcp
ufw enable
log "SUCCESS" "Firewall dikonfigurasi untuk port 20320."

# Tampilkan URL akses
IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="http://$IP_ADDRESS:20320/"
log "SUCCESS" "Setup selesai! Buka browser dan akses: $URL"

# Optional: Set timezone to UTC (can be customized for your region)
log "INFO" "Mengatur zona waktu ke UTC..."
timedatectl set-timezone UTC
log "SUCCESS" "Zona waktu diatur ke UTC."
