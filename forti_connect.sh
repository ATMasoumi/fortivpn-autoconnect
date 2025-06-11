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
    echo ""
    echo "🔧 Starting automatic VPN configuration setup..."
    echo ""
    
    if [[ "$SCRIPT_DIR" =~ /usr/local/bin ]] || [[ "$SCRIPT_DIR" =~ /opt/homebrew/bin ]]; then
        # Homebrew installation - run setup from the same directory
        if [[ -f "$SCRIPT_DIR/fortivpn-setup" ]]; then
            exec "$SCRIPT_DIR/fortivpn-setup"
        else
            echo -e "${RED}❌ Setup script not found: $SCRIPT_DIR/fortivpn-setup${NC}"
            echo "Please run 'fortivpn-setup' manually to configure your VPN settings"
            exit 1
        fi
    else
        # Development or manual installation - run setup from script directory
        if [[ -f "$SCRIPT_DIR/fortivpn-setup" ]]; then
            exec "$SCRIPT_DIR/fortivpn-setup"
        else
            echo -e "${RED}❌ Setup script not found: $SCRIPT_DIR/fortivpn-setup${NC}"
            echo "Please create the config file with your VPN credentials"
            exit 1
        fi
    fi
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

# Pre-authenticate sudo with better handling for Touch ID vs password
echo "🔐 Requesting sudo authentication..."

# Check if Touch ID is available for sudo_local
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✅ Using cached sudo credentials${NC}"
elif grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
    echo "🔍 Touch ID configured for sudo_local - requesting authentication..."
    if sudo -v; then
        echo -e "${GREEN}✅ Touch ID authentication successful${NC}"
    else
        echo -e "${RED}❌ Touch ID authentication failed${NC}"
        exit 1
    fi
else
    echo "🔐 Touch ID not configured for sudo_local - requesting password..."
    if sudo -v; then
        echo -e "${GREEN}✅ Password authentication successful${NC}"
    else
        echo -e "${RED}❌ Password authentication failed${NC}"
        exit 1
    fi
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
set YELLOW "\033\[1;33m"
set NC "\033\[0m"

# Enable logging for debugging
log_user 1
exp_internal 0

puts "${GREEN}-> Connecting to FortiVPN server...${NC}"

# Start openfortivpn (sudo should already be authenticated)
spawn sudo openfortivpn --config=$config_file

# Initialize flags
set otp_submitted 0
set connection_started 0

# Handle the various prompts that may appear
while {1} {
    expect {
        -re "Password.*:" {
            # This should be VPN password prompt, not sudo
            # Since sudo is pre-authenticated, any password prompt should be from VPN server
            puts "🔐 VPN server requesting password authentication..."
            puts "📝 Using password from config file..."
            # Let openfortivpn handle password from config file
            # Don't send anything manually - it should read from config
            exp_continue
        }
        -re "sudo.*Password.*:" {
            # This shouldn't happen since we pre-authenticate sudo
            puts "\n${RED}❌ Unexpected sudo password prompt${NC}"
            puts "⚠️  Sudo authentication may have expired"
            exit 1
        }
        -re "(Connected to gateway|tunnel is up)" {
            puts "${GREEN}✅ Connected to VPN gateway!${NC}"
            set connection_started 1
            exp_continue
        }
        -re "Established.*connection" {
            puts "${GREEN}✅ Connection established!${NC}"
            exp_continue
        }
        -re "(ERROR|WARN):" {
            # Show important error/warning messages
            puts "$expect_out(0,string)"
            exp_continue
        }
        -re "DEBUG:" {
            # Silently consume debug messages to reduce noise
            exp_continue
        }
        -re "SSL_connect.*error" {
            puts "\n${RED}❌ SSL connection failed${NC}"
            puts "⚠️  Certificate validation error"
            puts "ℹ️  Check certificate settings in config file"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Could not log out" {
            puts "\n${RED}❌ Connection failed during setup${NC}"
            puts "⚠️  VPN connection setup error"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Two.*factor.*token|Enter.*token|Please enter.*token" {
            # Skip if we've already submitted an OTP
            if {$otp_submitted == 1} {
                puts "🔄 Waiting for 2FA authentication result..."
                exp_continue
            }
            
            puts "\n🔐 2FA prompt detected!"
            puts "📱 Monitoring Messages app for OTP codes..."
            puts ""
            
            # Record the current timestamp when 2FA prompt appears
            set prompt_time [clock seconds]
            
            # Continuous monitoring with short intervals
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
                        # Short sleep for responsive monitoring
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
            puts "⚠️  The OTP code may have expired or been used already"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Login failed" {
            puts "\n${RED}❌ Login failed${NC}"
            puts "⚠️  Possible causes:"
            puts "   • Incorrect username or password in config file"
            puts "   • Account locked or disabled"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Could not authenticate to gateway" {
            puts "\n${RED}❌ Authentication failed${NC}"
            puts "⚠️  Could not authenticate with VPN gateway"
            puts "⚠️  Check credentials and OTP in config file"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "authentication failed|Authentication.*failed" {
            puts "\n${RED}❌ Authentication failed${NC}"
            puts "⚠️  Possible causes:"
            puts "   • Incorrect username or password in config file"
            puts "   • Account locked or expired"
            puts "   • Network connectivity issues"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Login.*failed|Invalid.*credentials" {
            puts "\n${RED}❌ Login failed${NC}"
            puts "⚠️  Please check your username and password in the config file"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        -re "Authentication.*expired|Session.*expired|Token.*expired" {
            puts "\n${RED}❌ Authentication expired${NC}"
            puts "⚠️  Your session or credentials have expired"
            puts "ℹ️  This can happen if:"
            puts "   • The VPN session timed out"
            puts "   • Your account password has expired"
            puts "   • The OTP token took too long to submit"
            puts ""
            puts "💡 Please try running the script again"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        timeout {
            puts "\n${RED}❌ Connection timeout${NC}"
            puts "⚠️  The VPN server is not responding within the expected time"
            puts "⚠️  Check your network connection and VPN server settings"
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        eof {
            if {$connection_started == 0} {
                puts "\n${RED}❌ Connection ended unexpectedly${NC}"
                puts "⚠️  The VPN process terminated before establishing connection"
                puts "ℹ️  Check your config file and network connectivity"
            } else {
                puts "\n${YELLOW}⚠️  VPN connection closed${NC}"
            }
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
