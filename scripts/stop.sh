#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/vpn-server"

echo "Stopping VPN services..."
if [ -f "$DIR/xray.pid" ]; then
    kill $(cat "$DIR/xray.pid") 2>/dev/null || true
    rm -f "$DIR/xray.pid"
fi
pkill -f "xray run" 2>/dev/null || true

if [ -f "$DIR/cloudflared.pid" ]; then
    kill $(cat "$DIR/cloudflared.pid") 2>/dev/null || true
    rm -f "$DIR/cloudflared.pid"
fi
pkill -f "cloudflared tunnel" 2>/dev/null || true

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
fi

echo "All stopped."
