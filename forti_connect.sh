#!/bin/bash

# FortiVPN Auto-Connect with 2FA
# Automatically connects to FortiVPN and handles 2FA OTP codes

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

echo "🚀 FortiVPN Auto-Connect with 2FA"
echo "======================================="

# Check if already connected
if pgrep -f "openfortivpn" > /dev/null; then
    echo -e "${GREEN}✅ FortiVPN is already running${NC}"
    echo ""
    echo "Current connection status:"
    ps aux | grep openfortivpn | grep -v grep || echo "No active connections found"
    echo ""
    echo "Use 'sudo pkill openfortivpn' to disconnect"
    exit 0
fi

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    if [[ "$SCRIPT_DIR" =~ /usr/local/bin ]] || [[ "$SCRIPT_DIR" =~ /opt/homebrew/bin ]]; then
        echo ""
        echo "🔧 Run 'fortivpn-setup' to configure your VPN settings"
    else
        echo "Please create the config file with your VPN credentials"
    fi
    exit 1
fi

# Check OTP script exists
if [[ ! -f "$OTP_SCRIPT" ]]; then
    echo -e "${RED}❌ OTP script not found: $OTP_SCRIPT${NC}"
    echo "Please ensure get_otp_code.scpt exists"
    exit 1
fi

echo "📝 Configuration file: $CONFIG_FILE"
echo "📱 OTP extraction script: $OTP_SCRIPT"
echo ""
echo "🔄 Initializing VPN connection..."

# Pre-authenticate sudo to enable Touch ID and extend timeout
echo "🔐 Authenticating with Touch ID (or password)..."
if ! sudo -v; then
    echo -e "${RED}❌ Authentication failed${NC}"
    exit 1
fi

# Keep sudo credentials fresh by refreshing them in background
# This prevents the second Touch ID prompt
(while true; do sleep 60; sudo -n true; done 2>/dev/null) &
SUDO_REFRESH_PID=$!

# Setup cleanup function for when script exits or is interrupted
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    
    # Kill sudo refresh process
    if [[ -n "$SUDO_REFRESH_PID" ]]; then
        kill $SUDO_REFRESH_PID 2>/dev/null
        echo "🔐 Stopped background authentication"
    fi
    
    # Kill any running openfortivpn processes
    if pgrep -f "openfortivpn" > /dev/null; then
        echo "⚠️  Disconnecting VPN..."
        sudo pkill openfortivpn 2>/dev/null
        sleep 1
        echo -e "${GREEN}✅ VPN disconnected${NC}"
    fi
    
    # Remove temporary files
    rm -f /tmp/forti_expect.exp
    
    echo "🏁 Cleanup complete"
}

# Trap signals to ensure cleanup happens on exit/interruption
trap cleanup EXIT
trap cleanup INT
trap cleanup TERM

# Create expect script for automation
cat > /tmp/forti_expect.exp << 'EXPECT_EOF'
#!/usr/bin/expect -f

set timeout 120
set config_file [lindex $argv 0]
set otp_script [lindex $argv 1]

# Color definitions for expect script (minimal)
set RED "\033\[0;31m"
set GREEN "\033\[0;32m"
set NC "\033\[0m"

# Disable debug output for cleaner interface
log_user 0
exp_internal 0

puts "${GREEN}-> Connecting to FortiVPN server...${NC}"

# Start openfortivpn without verbose mode for cleaner output
spawn sudo openfortivpn --config=$config_file

# Initialize OTP submission flag
set otp_submitted 0

# Handle the various prompts that may appear
while {1} {
    expect {
        "Password:" {
            puts "${RED}❌ Authentication expired. Please run the script again.${NC}"
            exit 1
        }
        -re "(Connected to gateway|tunnel is up)" {
            puts "${GREEN}✅ Connected to VPN gateway!${NC}"
            exp_continue
        }
        -re "(ERROR|WARN|DEBUG):" {
            # Silently consume debug/error messages
            exp_continue
        }
        -re "SSL_connect.*error" {
            puts "\n${RED}❌ SSL connection failed${NC}"
            puts "⚠️  Disconnecting VPN due to SSL/certificate error"
            puts "ℹ️  Try adding --insecure-ssl to your config or check certificate settings"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Could not log out" {
            puts "\n${RED}❌ Connection failed during setup${NC}"
            puts "⚠️  Disconnecting VPN due to connection setup error"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Two.*factor.*token" {
            # Skip if we've already submitted an OTP
            if {$otp_submitted == 1} {
                puts "🔄 Waiting for authentication result..."
                exp_continue
            }
            
            puts "\n🔐 2FA prompt detected!"
            puts "📱 Monitoring Messages app for OTP codes..."
            puts ""
            
            # Record the current timestamp when 2FA prompt appears
            set prompt_time [clock seconds]
            
            # Continuous monitoring with very short intervals (0.5 seconds)
            set otp_code ""
            set max_attempts 120  ; # 120 * 0.5 = 60 seconds total
            
            for {set i 0} {$i < $max_attempts} {incr i} {
                if {[expr $i % 20] == 0} {
                    puts "⏳ Waiting for OTP... ([expr $i/2] seconds elapsed)"
                }
                
                catch {
                    # Pass the prompt timestamp to the script so it only looks for newer messages
                    set otp_code [exec osascript $otp_script $prompt_time]
                } catch_result
                
                if {$otp_code != ""} {
                    puts "\n${GREEN}✅ OTP code received: $otp_code${NC}"
                    puts "🔑 Submitting authentication code..."
                    send "$otp_code\r"
                    set otp_submitted 1
                    break
                } else {
                    if {$i < [expr $max_attempts - 1]} {
                        # Very short sleep for near-continuous monitoring
                        after 500  ; # 0.5 seconds
                    }
                }
            }
            
            if {$otp_code == ""} {
                puts "\n${RED}❌ No OTP code detected after 60 seconds${NC}"
                puts "📱 Please enter the OTP code manually:"
                interact
                exit 1
            }
            
            # Continue to check connection result
            exp_continue
        }
        "Authenticated" {
            puts "\n${GREEN}🎉 Authentication successful!${NC}"
            exp_continue
        }
        "Negotiation complete" {
            puts "\n📋 VPN negotiation complete"
            exp_continue
        }
        "tunnel is up and running" {
            puts "\n${GREEN}🎉 VPN Connected Successfully!${NC}"
            puts "${GREEN}🔒 Secure tunnel established${NC}"
            puts ""
            puts "ℹ️  Your connection is now active. Press Ctrl+C to disconnect."
            interact
        }
        "Invalid token" {
            puts "\n${RED}❌ Invalid OTP token - may be expired${NC}"
            puts "⚠️  Disconnecting VPN due to invalid authentication token"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Login failed" {
            puts "\n${RED}❌ Login failed - check credentials${NC}"
            puts "⚠️  Disconnecting VPN due to login failure"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Could not authenticate to gateway" {
            puts "\n${RED}❌ Authentication failed - check credentials or OTP${NC}"
            puts "⚠️  Disconnecting VPN due to authentication failure"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "authentication failed" {
            puts "\n${RED}❌ Authentication failed${NC}"
            puts "⚠️  Disconnecting VPN due to authentication failure"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        timeout {
            puts "\n${RED}❌ Connection timeout${NC}"
            puts "⚠️  Disconnecting VPN due to connection timeout"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        eof {
            puts "\n${RED}❌ Connection ended unexpectedly${NC}"
            puts "⚠️  Disconnecting VPN due to connection error"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
    }
}
EXPECT_EOF

# Make expect script executable
chmod +x /tmp/forti_expect.exp

echo "🎬 Starting automated connection process..."
echo ""

# Run the expect script
/tmp/forti_expect.exp "$CONFIG_FILE" "$OTP_SCRIPT"

echo ""
echo "🏁 Session ended"
