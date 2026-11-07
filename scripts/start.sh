#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/vpn-server"
mkdir -p "$DIR"

if [ -f "$DIR/vpn.conf" ]; then
    source "$DIR/vpn.conf"
fi

if [ -z "$CF_TOKEN" ]; then
    echo "Error: CF_TOKEN is empty! Please configure it in vpnmenu or vpn.conf"
    exit 1
fi

"$DIR/stop.sh" --keep-lock >/dev/null 2>&1 || true

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi

echo "Starting Xray Core..."
nohup xray run -config "$HOME/.config/xray/config.json" > "$DIR/xray.log" 2>&1 &
echo $! > "$DIR/xray.pid"

echo "Starting Cloudflared Tunnel..."
nohup cloudflared tunnel run --token "$CF_TOKEN" > "$DIR/cloudflared.log" 2>&1 &
echo $! > "$DIR/cloudflared.pid"

sleep 2
"$DIR/status.sh"
