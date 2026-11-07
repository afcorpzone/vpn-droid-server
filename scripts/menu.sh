#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/vpn-server"
CONFIG="$HOME/.config/xray/config.json"
CONF_FILE="$DIR/vpn.conf"

# ANSI Colors
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

cls() {
    clear 2>/dev/null || printf "\033[2J\033[H"
}

load_conf() {
    if [ -f "$CONF_FILE" ]; then
        source "$CONF_FILE"
    fi
    DOMAIN="${CF_DOMAIN:-Not Set}"
    TOKEN="${CF_TOKEN:-Not Set}"
}

save_conf() {
    cat << CFG > "$CONF_FILE"
CF_TOKEN="$TOKEN"
CF_DOMAIN="$DOMAIN"
CFG
}

pause() {
    echo ""
    echo -e "${C_GRAY}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

get_status() {
    XPID=$(pgrep xray 2>/dev/null | head -n 1)
    if [ -n "$XPID" ]; then
        STATUS_XRAY="${C_BGREEN}● RUNNING${C_RESET} ${C_GRAY}(PID: $XPID)${C_RESET}"
    else
        STATUS_XRAY="${C_BRED}○ STOPPED${C_RESET}"
    fi

    CFPID=$(pgrep cloudflared 2>/dev/null | head -n 1)
    if [ -n "$CFPID" ]; then
        STATUS_CF="${C_BGREEN}● RUNNING${C_RESET} ${C_GRAY}(PID: $CFPID)${C_RESET}"
    else
        STATUS_CF="${C_BRED}○ STOPPED${C_RESET}"
    fi
}

change_token() {
    cls
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo -e "${C_WHITE}       UBAH TOKEN CLOUDFLARE TUNNEL           ${C_RESET}"
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo ""
    load_conf
    if [ "$TOKEN" != "Not Set" ]; then
        PREVIEW="${TOKEN:0:15}...${TOKEN: -10}"
        echo -e " Token saat ini : ${C_YELLOW}$PREVIEW${C_RESET}"
    else
        echo -e " Token saat ini : ${C_RED}Belum diset${C_RESET}"
    fi
    echo ""
    echo -e "${C_GRAY}Ketik '0' untuk membatalkan.${C_RESET}"
    echo -ne "${C_WHITE}Masukkan Token Baru: ${C_RESET}"
    read -r NEW_TOKEN

    if [ "$NEW_TOKEN" = "0" ] || [ -z "$NEW_TOKEN" ]; then
        echo -e "\n${C_YELLOW}Perubahan dibatalkan.${C_RESET}"
        pause
        return
    fi

    TOKEN="$NEW_TOKEN"
    save_conf
    echo -e "\n${C_BGREEN}✓ Token Cloudflare Tunnel berhasil disimpan!${C_RESET}"

    echo -ne "\nRestart VPN service sekarang agar token baru aktif? (y/n): "
    read -r ANS
    if [[ "$ANS" =~ ^[Yy]$ ]]; then
        echo ""
        "$DIR/restart.sh"
    fi
    pause
}

change_domain() {
    cls
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo -e "${C_WHITE}          UBAH DOMAIN / HOSTNAME              ${C_RESET}"
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo ""
    load_conf
    echo -e " Domain saat ini : ${C_YELLOW}$DOMAIN${C_RESET}"
    echo ""
    echo -e "${C_GRAY}Ketik '0' untuk membatalkan.${C_RESET}"
    echo -ne "${C_WHITE}Masukkan Domain Baru (misal: vpn.domainku.com): ${C_RESET}"
    read -r NEW_DOMAIN

    if [ "$NEW_DOMAIN" = "0" ] || [ -z "$NEW_DOMAIN" ]; then
        echo -e "\n${C_YELLOW}Perubahan dibatalkan.${C_RESET}"
        pause
        return
    fi

    DOMAIN="$NEW_DOMAIN"
    save_conf
    echo -e "\n${C_BGREEN}✓ Domain berhasil disimpan menjadi: ${C_WHITE}$DOMAIN${C_RESET}"
    echo -e "\n${C_YELLOW}[!] PENTING:${C_RESET}"
    echo -e "Pastikan di Cloudflare Zero Trust Dashboard (Public Hostnames),"
    echo -e "domain ${C_WHITE}$DOMAIN${C_RESET} sudah diarahkan ke ${C_CYAN}http://127.0.0.1:8080${C_RESET}"

    echo -ne "\nTampilkan link akun & QR Code baru sekarang? (y/n): "
    read -r ANS
    if [[ "$ANS" =~ ^[Yy]$ ]]; then
        echo ""
        "$DIR/account.sh"
    fi
    pause
}

reset_password() {
    cls
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo -e "${C_WHITE}           RESET PASSWORD TROJAN              ${C_RESET}"
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo ""
    CUR_PASS=$(grep "\"password\"" "$CONFIG" 2>/dev/null | head -n 1 | sed "s/.*\"password\": *\"\([^\"]*\)\".*/\1/")
    echo -e " Password saat ini : ${C_YELLOW}$CUR_PASS${C_RESET}"
    echo ""
    echo -e "Password baru akan digenerate otomatis dengan format"
    echo -e "standar 32-karakter heksadesimal yang aman dan kompatibel."
    echo ""
    echo -ne "${C_WHITE}Yakin ingin me-reset password? (y/n): ${C_RESET}"
    read -r CONFIRM

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "\n${C_YELLOW}Reset password dibatalkan.${C_RESET}"
        pause
        return
    fi

    NEW_PASS=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | tr '[:upper:]' '[:lower:]')
    if [ -z "$NEW_PASS" ]; then
        NEW_PASS=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
    fi

    sed -i "s/\"password\": \".*\"/\"password\": \"$NEW_PASS\"/" "$CONFIG"
    echo -e "\n${C_BGREEN}✓ Password baru berhasil digenerate:${C_RESET} ${C_YELLOW}$NEW_PASS${C_RESET}"

    echo -e "\nMerestart Xray Service..."
    "$DIR/restart.sh" >/dev/null 2>&1

    echo ""
    "$DIR/account.sh"
    pause
}

view_logs() {
    cls
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo -e "${C_WHITE}               LIVE LOGS                      ${C_RESET}"
    echo -e "${C_BCYAN}==============================================${C_RESET}"
    echo -e " 1. Tampilkan 20 Baris Log Terakhir"
    echo -e " 2. Streaming Log Xray (Live)        ${C_GRAY}[Ctrl+C untuk selesai]${C_RESET}"
    echo -e " 3. Streaming Log Cloudflared (Live) ${C_GRAY}[Ctrl+C untuk selesai]${C_RESET}"
    echo -e " 0. Kembali"
    echo ""
    echo -ne "${C_WHITE}Pilih menu: ${C_RESET}"
    read -r LOPT
    case "$LOPT" in
        1)
            echo ""
            echo -e "${C_CYAN}=== Xray Log ===${C_RESET}"
            tail -n 20 "$DIR/xray.log" 2>/dev/null || echo "Tidak ada log"
            echo ""
            echo -e "${C_CYAN}=== Cloudflared Log ===${C_RESET}"
            tail -n 20 "$DIR/cloudflared.log" 2>/dev/null || echo "Tidak ada log"
            pause
            ;;
        2)
            echo -e "\n${C_GRAY}Streaming Xray log (Tekan Ctrl+C untuk keluar)...${C_RESET}\n"
            tail -f "$DIR/xray.log"
            ;;
        3)
            echo -e "\n${C_GRAY}Streaming Cloudflared log (Tekan Ctrl+C untuk keluar)...${C_RESET}\n"
            tail -f "$DIR/cloudflared.log"
            ;;
        *)
            return
            ;;
    esac
}

while true; do
    load_conf
    get_status
    cls
    echo -e "${C_BCYAN}╔══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}          TERMUX ANDROID VPN SERVER MANAGER           ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_GRAY}         Trojan-WS + Cloudflare Zero Trust            ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}╠══════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  Xray Core   :${C_RESET} ${STATUS_XRAY}"
    echo -e "${C_BCYAN}║${C_WHITE}  CF Tunnel   :${C_RESET} ${STATUS_CF}"
    echo -e "${C_BCYAN}║${C_WHITE}  Domain      :${C_RESET} ${C_YELLOW}${DOMAIN}${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  Port Lokal  :${C_RESET} ${C_CYAN}127.0.0.1:8080${C_RESET}"
    echo -e "${C_BCYAN}╠══════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  [1]${C_RESET} Nyalakan VPN (Start)                             ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  [2]${C_RESET} Matikan VPN (Stop)                               ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  [3]${C_RESET} Restart VPN Service                              ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  [4]${C_RESET} Tampilkan Akun Trojan & QR Code                  ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_WHITE}  [5]${C_RESET} Pantau Log Koneksi (Logs)                        ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}╟──────────────────────────────────────────────────────╢${C_RESET}"
    echo -e "${C_BCYAN}║${C_YELLOW}  [6]${C_RESET} Ganti Token Cloudflare Tunnel                    ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_YELLOW}  [7]${C_RESET} Ganti Domain / Hostname                          ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}║${C_YELLOW}  [8]${C_RESET} Reset Password Trojan (Generate Otomatis)        ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}╟──────────────────────────────────────────────────────╢${C_RESET}"
    echo -e "${C_BCYAN}║${C_RED}  [0]${C_RESET} Keluar (Exit)                                    ${C_BCYAN}║${C_RESET}"
    echo -e "${C_BCYAN}╚══════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -ne "${C_WHITE}Pilih menu [0-8]: ${C_RESET}"
    read -r CHOICE

    case "$CHOICE" in
        1)
            echo ""
            "$DIR/start.sh"
            pause
            ;;
        2)
            echo ""
            "$DIR/stop.sh"
            pause
            ;;
        3)
            echo ""
            "$DIR/restart.sh"
            pause
            ;;
        4)
            cls
            "$DIR/account.sh"
            pause
            ;;
        5)
            view_logs
            ;;
        6)
            change_token
            ;;
        7)
            change_domain
            ;;
        8)
            reset_password
            ;;
        0|q|Q)
            cls
            echo -e "${C_BGREEN}Sampai jumpa! Service VPN tetap berjalan di background.${C_RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
            sleep 1
            ;;
    esac
done
