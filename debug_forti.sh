#!/bin/bash

# Debug version of FortiVPN Auto-Connect
# This version shows all output to help diagnose the "authentication expired" issue

set -e

CONFIG_DIR="$HOME/.fortivpn"
CONFIG_FILE="$CONFIG_DIR/forticonfig"

echo "🔍 DEBUG: FortiVPN Auto-Connect Debug Mode"
echo "======================================="

# Check if already connected
if pgrep -f "openfortivpn" > /dev/null; then
    echo "✅ FortiVPN is already running"
    exit 0
fi

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "📝 Configuration file: $CONFIG_FILE"
echo ""
echo "🔄 Testing direct openfortivpn connection..."

# Pre-authenticate sudo
echo "🔐 Authenticating with sudo..."
if ! sudo -v; then
    echo "❌ Authentication failed"
    exit 1
fi

echo "✅ Sudo authentication successful"
echo ""
echo "🚀 Starting openfortivpn directly (showing all output)..."
echo "======================================="

# Run openfortivpn directly with verbose output to see what's happening
sudo openfortivpn --config="$CONFIG_FILE" --debug=1

echo ""
echo "🏁 Debug session ended"
