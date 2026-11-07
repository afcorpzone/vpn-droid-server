#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  VPN-DROID-SERVER Uninstaller
# ==============================================================================

C_RESET="\033[0m"
C_RED="\033[0;31m"
C_BRED="\033[1;31m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[1;33m"
C_WHITE="\033[1;37m"

echo -e "${C_BRED}==============================================${C_RESET}"
echo -e "${C_WHITE}       UNINSTALL VPN-DROID-SERVER             ${C_RESET}"
echo -e "${C_BRED}==============================================${C_RESET}"
echo ""
echo -ne "${C_YELLOW}Apakah kamu yakin ingin menghapus seluruh instalasi VPN? (y/n): ${C_RESET}"
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "\n${C_GREEN}Uninstall dibatalkan.${C_RESET}"
    exit 0
fi

echo -e "\n1. Menghentikan service yang berjalan..."
if [ -f "$HOME/vpn-server/stop.sh" ]; then
    "$HOME/vpn-server/stop.sh" >/dev/null 2>&1 || true
fi
pkill -f "xray run" 2>/dev/null || true
pkill -f "cloudflared tunnel" 2>/dev/null || true

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
fi

echo "2. Menghapus perintah global..."
rm -f "$PREFIX/bin/vpn" "$PREFIX/bin/vpnmenu" "$PREFIX/bin/xray"

echo "3. Menghapus direktori konfigurasi dan skrip..."
rm -rf "$HOME/vpn-server" "$HOME/.config/xray" "$PREFIX/share/xray"

echo ""
echo -e "${C_GREEN}✓ VPN-Droid-Server berhasil di-uninstall secara bersih!${C_RESET}"
echo -e "${C_WHITE}Paket bawaan seperti cloudflared dan libqrencode tidak dihapus otomatis.${C_RESET}"
echo -e "Jika ingin menghapusnya, jalankan: ${C_YELLOW}pkg uninstall cloudflared libqrencode${C_RESET}"
echo ""
