#!/data/data/com.termux/files/usr/bin/bash
echo "=== VPN Service Status ==="
XPID=$(pgrep xray 2>/dev/null | head -n 1)
if [ -n "$XPID" ]; then
    echo "Xray: RUNNING (PID: $XPID)"
else
    echo "Xray: STOPPED"
fi

CFPID=$(pgrep cloudflared 2>/dev/null | head -n 1)
if [ -n "$CFPID" ]; then
    echo "Cloudflared: RUNNING (PID: $CFPID)"
else
    echo "Cloudflared: STOPPED"
fi

echo "=== Local Ports ==="
ss -tulpn 2>/dev/null | grep 8080 || echo "Port 8080 active"
