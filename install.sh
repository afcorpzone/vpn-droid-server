#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  VPN-DROID-SERVER: One-Click Installer & Updater for Termux Android
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

# Robust read helper that supports piped executions (e.g. curl | bash)
read_tty() {
    if [ -t 0 ]; then
        read -r "$@"
    elif [ -e /dev/tty ]; then
        read -r "$@" < /dev/tty
    else
        read -r "$@"
    fi
}

clear 2>/dev/null || printf "\033[2J\033[H"
echo -e "${C_BCYAN}╔══════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BCYAN}║${C_WHITE}         VPN-DROID-SERVER AUTO INSTALLER              ${C_BCYAN}║${C_RESET}"
echo -e "${C_BCYAN}║${C_GRAY}        Xray Trojan-WS + Cloudflare Zero Trust        ${C_BCYAN}║${C_RESET}"
echo -e "${C_BCYAN}╚══════════════════════════════════════════════════════╝${C_RESET}"
echo ""

# 1. Environment Check
echo -e "${C_BCYAN}[1/6] Memeriksa Lingkungan Sistem...${C_RESET}"
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
    echo -e "${C_RED}Error: Skrip ini dirancang khusus untuk Termux di Android.${C_RESET}"
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        XRAY_ZIP="Xray-android-arm64-v8a.zip"
        CF_ARCH="arm64"
        ;;
    arm|armv7l|armv8l)
        XRAY_ZIP="Xray-linux-arm32-v7a.zip"
        CF_ARCH="arm"
        ;;
    x86_64|amd64)
        XRAY_ZIP="Xray-android-amd64.zip"
        CF_ARCH="amd64"
        ;;
    *)
        echo -e "${C_RED}Arsitektur CPU tidak didukung: $ARCH${C_RESET}"
        exit 1
        ;;
esac
echo -e "  ${C_GREEN}✓${C_RESET} Arsitektur CPU : ${C_WHITE}$ARCH${C_RESET} (${C_YELLOW}$XRAY_ZIP${C_RESET})"
echo -e "  ${C_GREEN}✓${C_RESET} Direktori Base : ${C_WHITE}$PREFIX${C_RESET}"

# Idempotency Check: Already installed?
IS_UPDATE=0
if [ -f "$TARGET_DIR/vpn.conf" ] && [ -f "$CONFIG_DIR/config.json" ]; then
    echo ""
    echo -e "${C_YELLOW}╔══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_YELLOW}║  [!] Terdeteksi Sistem Sudah Pernah Terpasang!       ║${C_RESET}"
    echo -e "${C_YELLOW}╚══════════════════════════════════════════════════════╝${C_RESET}"
    echo -e " ${C_WHITE}[1]${C_RESET} ${C_BGREEN}Update / Perbaiki Sistem${C_RESET} (Pertahankan Token, Domain & Password)"
    echo -e " ${C_WHITE}[2]${C_RESET} ${C_YELLOW}Install Ulang Total${C_RESET} (Konfigurasi Ulang Token & Domain)"
    echo -e " ${C_WHITE}[0]${C_RESET} ${C_RED}Batal / Keluar${C_RESET}"
    echo ""
    echo -ne "${C_WHITE}Pilih opsi [1/2/0, default: 1]: ${C_RESET}"
    read_tty REINSTALL_OPT

    case "$REINSTALL_OPT" in
        0|q|Q)
            echo -e "\n${C_GREEN}Dibatalkan. Sistem lama tetap berjalan tanpa perubahan.${C_RESET}\n"
            exit 0
            ;;
        2)
            echo -e "\n${C_YELLOW}Melakukan instalasi ulang total...${C_RESET}"
            IS_UPDATE=0
            ;;
        *)
            echo -e "\n${C_GREEN}Melakukan update sistem tanpa mengubah konfigurasi akun...${C_RESET}"
            IS_UPDATE=1
            ;;
    esac
fi

# 2. Install & Synchronize Dependencies
echo -e "\n${C_BCYAN}[2/6] Memasang & Menyelaraskan Dependencies...${C_RESET}"
echo -e "  ➜ Memperbarui index repository package..."
pkg update -y || apt update -y

echo -e "  ➜ Memasang/memperbarui openssl, libcurl, curl, cloudflared, libqrencode, unzip, termux-tools..."
# Install openssl and libcurl together to prevent symbol mismatch
pkg install -y openssl libcurl curl cloudflared libqrencode unzip termux-tools || apt install -y openssl libcurl curl cloudflared libqrencode unzip termux-tools

# Health check & Auto-fix for curl linking error
echo -e "  ➜ Memeriksa integritas pustaka curl..."
if ! curl --version >/dev/null 2>&1; then
    echo -e "  ${C_YELLOW}⚠ Terdeteksi library curl belum sinkron dengan OpenSSL. Memperbaiki...${C_RESET}"
    pkg install -y --reinstall openssl libcurl curl || apt-get --reinstall install -y openssl libcurl curl
fi

if ! curl --version >/dev/null 2>&1; then
    echo -e "  ${C_RED}Gagal menyelaraskan pustaka curl otomatis. Mencoba update paket...${C_RESET}"
    pkg upgrade -y -o Dpkg::Options::="--force-confold" openssl libcurl curl
fi
echo -e "  ${C_GREEN}✓${C_RESET} Pustaka curl & OpenSSL sehat: ${C_WHITE}$(curl --version | head -n 1 | cut -d ' ' -f 1-3)${C_RESET}"

# Fallback check for cloudflared
if ! command -v cloudflared >/dev/null 2>&1; then
    echo -e "  ${C_YELLOW}Mengunduh standalone cloudflared binary dari Cloudflare GitHub...${C_RESET}"
    curl -L --progress-bar -o "$PREFIX/bin/cloudflared" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}"
    chmod +x "$PREFIX/bin/cloudflared"
fi
echo -e "  ${C_GREEN}✓${C_RESET} Cloudflared: ${C_WHITE}$(cloudflared --version 2>/dev/null | cut -d ' ' -f 1-3 || echo 'Terpasang')${C_RESET}"

# 3. Install Xray-Core Binary
echo -e "\n${C_BCYAN}[3/6] Memasang Xray-Core Native Android...${C_RESET}"
echo -e "  ➜ Memeriksa rilis terbaru Xray-core..."
XRAY_TAG=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 || true)
if [ -z "$XRAY_TAG" ]; then
    XRAY_TAG="v26.10.31"
fi
echo -e "  ${C_GREEN}✓${C_RESET} Versi Xray yang akan dipasang: ${C_YELLOW}$XRAY_TAG${C_RESET}"

TMP_XRAY="$PREFIX/tmp/xray-download"
rm -rf "$TMP_XRAY"
mkdir -p "$TMP_XRAY"
XRAY_ZIP_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_TAG}/${XRAY_ZIP}"

echo -e "  ➜ Mengunduh ${C_WHITE}$XRAY_ZIP${C_RESET}:"
curl -L --progress-bar -o "$TMP_XRAY/xray.zip" "$XRAY_ZIP_URL"

echo -e "  ➜ Mengekstrak binary Xray-core..."
unzip -q -o "$TMP_XRAY/xray.zip" -d "$TMP_XRAY"
cp "$TMP_XRAY/xray" "$PREFIX/bin/xray"
chmod +x "$PREFIX/bin/xray"

mkdir -p "$PREFIX/share/xray"
cp "$TMP_XRAY/"*.dat "$PREFIX/share/xray/" 2>/dev/null || true
rm -rf "$TMP_XRAY"
echo -e "  ${C_GREEN}✓${C_RESET} Xray-Core berhasil dipasang: ${C_WHITE}$($PREFIX/bin/xray version | head -n 1)${C_RESET}"

# 4. Configuration Wizard
echo -e "\n${C_BCYAN}[4/6] Menyiapkan Konfigurasi Akun & Tunnel...${C_RESET}"
mkdir -p "$TARGET_DIR" "$CONFIG_DIR"

if [ "$IS_UPDATE" -eq 1 ]; then
    # Keep existing configuration
    source "$TARGET_DIR/vpn.conf"
    PASS=$(grep "\"password\"" "$CONFIG_DIR/config.json" 2>/dev/null | head -n 1 | sed "s/.*\"password\": *\"\([^\"]*\)\".*/\1/")
    echo -e "  ${C_GREEN}✓${C_RESET} Konfigurasi lama dipertahankan:"
    echo -e "    Domain   : ${C_YELLOW}$CF_DOMAIN${C_RESET}"
    echo -e "    Password : ${C_YELLOW}${PASS:0:8}****************${C_RESET}"
else
    # Interactive input
    EXISTING_TOKEN=""
    EXISTING_DOMAIN=""

    while [ -z "$EXISTING_TOKEN" ]; do
        echo -ne "${C_WHITE}Masukkan Token Cloudflare Tunnel: ${C_RESET}"
        read_tty EXISTING_TOKEN
        if [ -z "$EXISTING_TOKEN" ]; then
            echo -e "${C_RED}Token tidak boleh kosong! Dapatkan token dari Cloudflare Zero Trust Dashboard.${C_RESET}"
        fi
    done

    while [ -z "$EXISTING_DOMAIN" ]; do
        echo -ne "${C_WHITE}Masukkan Domain / Hostname (misal: in.domainku.com): ${C_RESET}"
        read_tty EXISTING_DOMAIN
        if [ -z "$EXISTING_DOMAIN" ]; then
            echo -e "${C_RED}Domain tidak boleh kosong!${C_RESET}"
        fi
    done

    # Save vpn.conf
    cat << EOF > "$TARGET_DIR/vpn.conf"
CF_TOKEN="$EXISTING_TOKEN"
CF_DOMAIN="$EXISTING_DOMAIN"
EOF

    # Generate fresh 32-char hex password with multiple fallbacks
    PASS=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | tr '[:upper:]' '[:lower:]')
    if [ -z "$PASS" ]; then
        PASS=$(head -c 16 /dev/urandom 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n')
    fi
    if [ -z "$PASS" ]; then
        PASS=$(date +%s%N | md5sum | head -c 32)
    fi
fi

# 5. Deploy Configuration and Scripts
echo -e "\n${C_BCYAN}[5/6] Menyusun File Konfigurasi & Menu...${C_RESET}"

# Generate Xray config
echo -e "  ➜ Menulis file konfigurasi Xray-core..."
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
echo -e "  ➜ Memasang modul skrip kontrol & menu..."
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
echo -e "  ${C_GREEN}✓${C_RESET} Perintah global ${C_YELLOW}vpn${C_RESET} dan ${C_YELLOW}vpnmenu${C_RESET} aktif."

# 6. Start Service
echo -e "\n${C_BCYAN}[6/6] Menjalankan VPN Service...${C_RESET}"
"$TARGET_DIR/start.sh"

echo ""
echo -e "${C_BGREEN}╔══════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BGREEN}║      PROSES SELESAI & SERVICE SEDANG BERJALAN        ║${C_RESET}"
echo -e "${C_BGREEN}╚══════════════════════════════════════════════════════╝${C_RESET}"
echo ""
echo -e "Ketik ${C_YELLOW}vpnmenu${C_RESET} atau ${C_YELLOW}vpn${C_RESET} kapan saja untuk membuka menu kontrol."
echo ""
"$TARGET_DIR/account.sh"
