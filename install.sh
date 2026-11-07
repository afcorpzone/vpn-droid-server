#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  VPN-DROID-SERVER: One-Click Installer for Termux Android
#  Repository: https://github.com/afcorpzone/vpn-droid-server
# ==============================================================================

set -e

# Terminal colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[0;36m"
C_BCYAN="\033[1;36m"
C_GREEN="\033[0;32m"
C_BGREEN="\033[1;32m"
C_RED="\033[0;31m"
C_BRED="\033[1;31m"
C_YELLOW="\033[1;33m"
C_WHITE="\033[1;37m"
C_GRAY="\033[0;90m"

REPO_RAW="https://raw.githubusercontent.com/afcorpzone/vpn-droid-server/main"
TARGET_DIR="$HOME/vpn-server"
CONFIG_DIR="$HOME/.config/xray"
SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

clear 2>/dev/null || printf "\033[2J\033[H"
echo -e "${C_BCYAN}╔══════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BCYAN}║${C_WHITE}         VPN-DROID-SERVER AUTO INSTALLER              ${C_BCYAN}║${C_RESET}"
echo -e "${C_BCYAN}║${C_GRAY}        Xray Trojan-WS + Cloudflare Zero Trust        ${C_BCYAN}║${C_RESET}"
echo -e "${C_BCYAN}╚══════════════════════════════════════════════════════╝${C_RESET}"
echo ""

# 1. Environment Check
echo -e "${C_CYAN}[1/6] Memeriksa Lingkungan Sistem...${C_RESET}"
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
    echo -e "${C_RED}Error: Skrip ini dirancang khusus untuk Termux di Android.${C_RESET}"
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        XRAY_ARCH="arm64-v8a"
        ;;
    arm|armv7l|armv8l)
        XRAY_ARCH="arm32-v7a"
        ;;
    x86_64|amd64)
        XRAY_ARCH="64"
        ;;
    *)
        echo -e "${C_RED}Arsitektur CPU tidak didukung: $ARCH${C_RESET}"
        exit 1
        ;;
esac
echo -e "Arsitektur CPU terdeteksi: ${C_GREEN}$ARCH${C_RESET} -> ${C_GREEN}$XRAY_ARCH${C_RESET}"

# 2. Install Dependencies
echo -e "\n${C_CYAN}[2/6] Memasang Dependencies Package Termux...${C_RESET}"
pkg update -y >/dev/null 2>&1 || apt update -y >/dev/null 2>&1
pkg install -y cloudflared libqrencode curl unzip >/dev/null 2>&1 || apt install -y cloudflared libqrencode curl unzip -y

# 3. Install Xray-Core Binary
echo -e "\n${C_CYAN}[3/6] Memasang Xray-Core Native Android...${C_RESET}"
XRAY_TAG=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4)
if [ -z "$XRAY_TAG" ]; then
    XRAY_TAG="v26.10.31"
fi
echo -e "Versi Xray: ${C_YELLOW}$XRAY_TAG${C_RESET}"

TMP_XRAY="$PREFIX/tmp/xray-download"
rm -rf "$TMP_XRAY"
mkdir -p "$TMP_XRAY"
XRAY_ZIP_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_TAG}/Xray-android-${XRAY_ARCH}.zip"

curl -L -s -o "$TMP_XRAY/xray.zip" "$XRAY_ZIP_URL"
unzip -q -o "$TMP_XRAY/xray.zip" -d "$TMP_XRAY"
cp "$TMP_XRAY/xray" "$PREFIX/bin/xray"
chmod +x "$PREFIX/bin/xray"

mkdir -p "$PREFIX/share/xray"
cp "$TMP_XRAY/"*.dat "$PREFIX/share/xray/" 2>/dev/null || true
rm -rf "$TMP_XRAY"
echo -e "${C_BGREEN}✓ Xray-Core berhasil dipasang ke \$PREFIX/bin/xray${C_RESET}"

# 4. Interactive Configuration Wizard
echo -e "\n${C_CYAN}[4/6] Konfigurasi Akun & Cloudflare Tunnel...${C_RESET}"
mkdir -p "$TARGET_DIR" "$CONFIG_DIR"

# Check existing conf
EXISTING_TOKEN=""
EXISTING_DOMAIN=""
if [ -f "$TARGET_DIR/vpn.conf" ]; then
    source "$TARGET_DIR/vpn.conf"
    EXISTING_TOKEN="$CF_TOKEN"
    EXISTING_DOMAIN="$CF_DOMAIN"
fi

if [ -n "$EXISTING_TOKEN" ]; then
    echo -e "Token lama ditemukan: ${C_YELLOW}${EXISTING_TOKEN:0:15}...${C_RESET}"
    echo -ne "Gunakan token lama? (y/n, default: y): "
    read -r USE_OLD_TOKEN
    if [[ "$USE_OLD_TOKEN" =~ ^[Nn]$ ]]; then
        EXISTING_TOKEN=""
    fi
fi

while [ -z "$EXISTING_TOKEN" ]; do
    echo -ne "${C_WHITE}Masukkan Token Cloudflare Tunnel: ${C_RESET}"
    read -r EXISTING_TOKEN
    if [ -z "$EXISTING_TOKEN" ]; then
        echo -e "${C_RED}Token tidak boleh kosong! Dapatkan token dari Cloudflare Zero Trust Dashboard.${C_RESET}"
    fi
done

if [ -n "$EXISTING_DOMAIN" ]; then
    echo -e "Domain lama ditemukan: ${C_YELLOW}${EXISTING_DOMAIN}${C_RESET}"
    echo -ne "Gunakan domain lama? (y/n, default: y): "
    read -r USE_OLD_DOMAIN
    if [[ "$USE_OLD_DOMAIN" =~ ^[Nn]$ ]]; then
        EXISTING_DOMAIN=""
    fi
fi

while [ -z "$EXISTING_DOMAIN" ]; do
    echo -ne "${C_WHITE}Masukkan Domain / Hostname (misal: in.domainku.com): ${C_RESET}"
    read -r EXISTING_DOMAIN
    if [ -z "$EXISTING_DOMAIN" ]; then
        echo -e "${C_RED}Domain tidak boleh kosong!${C_RESET}"
    fi
done

# Save vpn.conf
cat << EOF > "$TARGET_DIR/vpn.conf"
CF_TOKEN="$EXISTING_TOKEN"
CF_DOMAIN="$EXISTING_DOMAIN"
EOF

# Password generation
PASS=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | tr '[:upper:]' '[:lower:]')
if [ -z "$PASS" ]; then
    PASS=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
fi

# 5. Deploy Configuration and Scripts
echo -e "\n${C_CYAN}[5/6] Menyusun File Konfigurasi & Menu...${C_RESET}"

# Generate Xray config
cat << EOF > "$CONFIG_DIR/config.json"
{
  "log": {
    "loglevel": "warning"
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "bufferSize": 4
      }
    }
  },
  "inbounds": [
    {
      "port": 8080,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$PASS"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/trojan-ws"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
        "finalRules": [
          {
            "action": "allow"
          }
        ]
      }
    }
  ]
}
EOF

# Install scripts (from local if exists, otherwise download from GitHub)
SCRIPT_FILES=("start.sh" "stop.sh" "restart.sh" "status.sh" "account.sh" "menu.sh")
for SF in "${SCRIPT_FILES[@]}"; do
    if [ -f "$SCRIPT_SOURCE/scripts/$SF" ]; then
        cp "$SCRIPT_SOURCE/scripts/$SF" "$TARGET_DIR/$SF"
    else
        curl -fsSL "$REPO_RAW/scripts/$SF" -o "$TARGET_DIR/$SF"
    fi
    chmod +x "$TARGET_DIR/$SF"
done

# Create global commands: vpn & vpnmenu
cat << "EOF" > "$PREFIX/bin/vpnmenu"
#!/data/data/com.termux/files/usr/bin/bash
exec "$HOME/vpn-server/menu.sh"
EOF
chmod +x "$PREFIX/bin/vpnmenu"

cat << "EOF" > "$PREFIX/bin/vpn"
#!/data/data/com.termux/files/usr/bin/bash
if [ -z "$1" ]; then
    exec "$HOME/vpn-server/menu.sh"
fi

case "$1" in
    start)
        "$HOME/vpn-server/start.sh"
        ;;
    stop)
        "$HOME/vpn-server/stop.sh"
        ;;
    status)
        "$HOME/vpn-server/status.sh"
        ;;
    restart)
        "$HOME/vpn-server/restart.sh"
        ;;
    log)
        echo "=== Xray Log (last 15 lines) ==="
        tail -n 15 "$HOME/vpn-server/xray.log" 2>/dev/null
        echo ""
        echo "=== Cloudflared Log (last 15 lines) ==="
        tail -n 15 "$HOME/vpn-server/cloudflared.log" 2>/dev/null
        ;;
    account|acc|qr)
        "$HOME/vpn-server/account.sh"
        ;;
    menu)
        exec "$HOME/vpn-server/menu.sh"
        ;;
    *)
        echo "Usage: vpn [start|stop|restart|status|log|account|menu]"
        echo "Atau ketik 'vpn' / 'vpnmenu' untuk membuka TUI interaktif."
        ;;
esac
EOF
chmod +x "$PREFIX/bin/vpn"

# 6. Start Service
echo -e "\n${C_CYAN}[6/6] Menjalankan VPN Service...${C_RESET}"
"$TARGET_DIR/start.sh"

echo ""
echo -e "${C_BGREEN}╔══════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BGREEN}║      INSTALASI SELESAI & SERVICE SEDANG BERJALAN     ║${C_RESET}"
echo -e "${C_BGREEN}╚══════════════════════════════════════════════════════╝${C_RESET}"
echo ""
echo -e "Ketik ${C_YELLOW}vpnmenu${C_RESET} atau ${C_YELLOW}vpn${C_RESET} kapan saja untuk membuka menu kontrol."
echo ""
"$TARGET_DIR/account.sh"
