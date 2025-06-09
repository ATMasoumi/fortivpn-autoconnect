#!/bin/bash

# Debug version with full verbose output to diagnose authentication issues
# This version shows all output to help diagnose authentication problems

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Determine script directory and config paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if we're running from Homebrew installation
if [[ "$SCRIPT_DIR" =~ /usr/local/bin ]] || [[ "$SCRIPT_DIR" =~ /opt/homebrew/bin ]]; then
    # Homebrew installation - look for config in user's home directory
    CONFIG_DIR="$HOME/.fortivpn"
    CONFIG_FILE="$CONFIG_DIR/forticonfig"
    OTP_SCRIPT="$SCRIPT_DIR/get_otp_code.scpt"
else
    # Development or manual installation - use script directory
    CONFIG_FILE="$SCRIPT_DIR/forticonfig"
    OTP_SCRIPT="$SCRIPT_DIR/get_otp_code.scpt"
fi

echo "🚀 FortiVPN Auto-Connect DEBUG MODE"
echo "======================================="
echo "📝 Configuration file: $CONFIG_FILE"
echo "📱 OTP extraction script: $OTP_SCRIPT"
echo ""

# Check if already connected
if pgrep -f "openfortivpn" > /dev/null; then
    echo -e "${GREEN}✅ FortiVPN is already running${NC}"
    exit 0
fi

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Check OTP script exists
if [[ ! -f "$OTP_SCRIPT" ]]; then
    echo -e "${RED}❌ OTP script not found: $OTP_SCRIPT${NC}"
    exit 1
fi

echo "🔐 Requesting sudo authentication..."
if ! sudo -v; then
    echo -e "${RED}❌ Authentication failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Authentication successful${NC}"

echo ""
echo "🎬 Starting DEBUG connection (showing ALL output)..."
echo "===================================================="
echo ""

# Create expect script with full debugging
cat > /tmp/forti_debug.exp << 'EXPECT_EOF'
#!/usr/bin/expect -f

set timeout 120
set config_file [lindex $argv 0]

# Enable full logging for debugging
log_user 1
exp_internal 1

puts "DEBUG: Starting openfortivpn with config: $config_file"

# Start openfortivpn with maximum verbosity
spawn sudo openfortivpn --config=$config_file --verbose

# Just show everything - no filtering
expect {
    -re ".+" {
        puts "CAPTURED: $expect_out(0,string)"
        exp_continue
    }
    timeout {
        puts "TIMEOUT REACHED"
        exit 1
    }
    eof {
        puts "PROCESS ENDED"
        exit 1
    }
}
EXPECT_EOF

chmod +x /tmp/forti_debug.exp

echo "Running debug connection..."
/tmp/forti_debug.exp "$CONFIG_FILE"

echo ""
echo "🏁 Debug session ended"
