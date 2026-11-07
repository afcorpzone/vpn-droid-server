#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/vpn-server"
"$DIR/stop.sh" --keep-lock
sleep 1
"$DIR/start.sh"
