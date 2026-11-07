#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/vpn-server"
CONFIG="$HOME/.config/xray/config.json"

if [ -f "$DIR/vpn.conf" ]; then
    source "$DIR/vpn.conf"
fi

DOMAIN="${CF_DOMAIN:-your-domain.com}"
PASSWORD=$(grep "\"password\"" "$CONFIG" 2>/dev/null | head -n 1 | sed "s/.*\"password\": *\"\([^\"]*\)\".*/\1/")

if [ -z "$PASSWORD" ]; then
    echo "Error: Password not found in $CONFIG"
    exit 1
fi

PATH_WS=$(grep "\"path\"" "$CONFIG" 2>/dev/null | head -n 1 | sed "s/.*\"path\": *\"\([^\"]*\)\".*/\1/")
if [ -z "$PATH_WS" ]; then
    PATH_WS="/trojan-ws"
fi
URL_PATH=$(echo "$PATH_WS" | sed "s/\//%2F/g")

URL="trojan://${PASSWORD}@${DOMAIN}:443?security=tls&sni=${DOMAIN}&alpn=http/1.1&type=ws&host=${DOMAIN}&path=${URL_PATH}#Termux-Trojan-VPN"

echo "=========================================="
echo "         TROJAN-WS ACCOUNT INFO           "
echo "=========================================="
echo " Domain / Host : $DOMAIN"
echo " Port          : 443"
echo " Password      : $PASSWORD"
echo " Security      : TLS (SNI: $DOMAIN)"
echo " Network       : WebSocket (WS)"
echo " WS Path       : $PATH_WS"
echo " WS Host       : $DOMAIN"
echo "=========================================="
echo ""
echo "=== TROJAN URL (Copy & Import to Nekobox) ==="
echo "$URL"
echo ""
echo "=== QR CODE ==="
if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSIUTF8 "$URL"
else
    echo "(qrencode not installed)"
fi
echo ""
