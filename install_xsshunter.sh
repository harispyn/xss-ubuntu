#!/bin/bash

# ==============================================================================
#                  Script Auto-Install XSSHunter Express
#                       untuk Ubuntu 22.04 (Jammy)
#
# Dibuat oleh: AI Assistant
# Penggunaan:  sudo bash install_xsshunter.sh
# ==============================================================================

# --- Warna untuk output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Fungsi untuk mencetak output berwarna ---
print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Keluar jika ada command yang gagal ---
set -e

# --- Cek apakah dijalankan sebagai root ---
if [[ $EUID -ne 0 ]]; then
   print_error "Script ini harus dijalankan sebagai root (gunakan sudo)."
   exit 1
fi

# --- Input dari User ---
print_info "Mohon masukkan informasi yang dibutuhkan untuk konfigurasi."
read -p "Masukkan nama domain (contoh: xss.yourdomain.com): " DOMAIN_NAME
read -p "Masukkan email untuk Let's Encrypt dan admin: " ADMIN_EMAIL
read -p "Masukkan password untuk akun admin XSSHunter: " ADMIN_PASSWORD

# Validasi input dasar
if [ -z "$DOMAIN_NAME" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    print_error "Semua input harus diisi. Silakan coba lagi."
    exit 1
fi

# --- 1. Update Sistem ---
print_info "Mengupdate sistem..."
apt update && apt upgrade -y

# --- 2. Install Dependencies Awal ---
print_info "Menginstall dependencies awal (git, curl, gnupg, dll)..."
apt install -y git curl wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# --- 3. Install Node.js 18.x (LTS) ---
print_info "Menambahkan repository NodeSource..."
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
print_info "Menginstall Node.js..."
apt update
apt install -y nodejs

# --- 4. Install MongoDB ---
print_info "Menambahkan repository MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
print_info "Menginstall MongoDB..."
apt update
apt install -y mongodb-org
print_info "Mengaktifkan dan menjalankan layanan MongoDB..."
systemctl enable --now mongod

# --- 5. Install Nginx ---
print_info "Menginstall Nginx..."
apt install -y nginx
print_info "Mengaktifkan dan menjalankan layanan Nginx..."
systemctl enable --now nginx

# --- 6. Install PM2 ---
print_info "Menginstall PM2 secara global..."
npm install pm2 -g

# --- 7. Setup XSSHunter Express ---
INSTALL_DIR="/var/www/xsshunter-express"
print_info "Mengkloning XSSHunter Express ke $INSTALL_DIR..."
git clone https://github.com/mandatoryprogrammer/xsshunter-express.git $INSTALL_DIR
cd $INSTALL_DIR

print_info "Menginstall dependencies Node.js untuk aplikasi..."
npm install

# --- 8. Konfigurasi XSSHunter Express ---
print_info "Membuat file konfigurasi .env..."
SESSION_SECRET=$(openssl rand -base64 32)
cat > .env << EOF
NODE_ENV=production
PORT=3000
DOMAIN_NAME=${DOMAIN_NAME}
MONGO_URI=mongodb://localhost:27017/xsshunter
SESSION_SECRET=${SESSION_SECRET}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
EOF
print_success "File .env telah dibuat."

# --- 9. Konfigurasi PM2 ---
print_info "Membuat file ekosistem PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'xsshunter-express',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOF

print_info "Menjalankan aplikasi dengan PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# --- 10. Konfigurasi Nginx Reverse Proxy ---
print_info "Mengkonfigurasi Nginx sebagai reverse proxy..."
cat > /etc/nginx/sites-available/xsshunter << EOF
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

print_info "Mengaktifkan konfigurasi site Nginx..."
ln -s /etc/nginx/sites-available/xsshunter /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_info "Menguji konfigurasi Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    print_success "Konfigurasi Nginx valid. Me-reload Nginx..."
    systemctl reload nginx
else
    print_error "Konfigurasi Nginx bermasalah. Mohon periksa secara manual."
    exit 1
fi

# --- 11. Install SSL dengan Certbot (Let's Encrypt) ---
print_info "Menginstall Certbot untuk SSL..."
apt install -y certbot python3-certbot-nginx

print_info "Meminta sertifikat SSL untuk ${DOMAIN_NAME}..."
certbot --nginx -d ${DOMAIN_NAME} --non-interactive --agree-tos --email ${ADMIN_EMAIL} --redirect

# --- 12. Selesai ---
print_success "-------------------------------------------------"
print_success "Instalasi XSSHunter Express telah SELESAI!"
print_success "-------------------------------------------------"
echo ""
print_info "Detail Instalasi:"
echo "  - Domain Anda: https://${DOMAIN_NAME}"
echo "  - Email Admin: ${ADMIN_EMAIL}"
echo "  - Password Admin: (yang Anda masukkan)"
echo ""
print_info "Aplikasi berjalan di background menggunakan PM2."
print_info "Anda dapat mengelolanya dengan perintah 'pm2 status', 'pm2 logs', 'pm2 restart xsshunter-express'."
echo ""
print_success "Silakan buka https://${DOMAIN_NAME} di browser Anda dan login!"
