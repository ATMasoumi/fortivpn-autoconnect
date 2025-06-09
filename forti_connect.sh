#!/bin/bash

# FortiVPN Auto-Connect with 2FA
# Automatically connects to FortiVPN and handles 2FA OTP codes

set -e

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
echo "=================================="

# Check if already connected
if pgrep -f "openfortivpn" > /dev/null; then
    echo "✅ FortiVPN is already running"
    echo ""
    echo "Current connection status:"
    ps aux | grep openfortivpn | grep -v grep || echo "No active connections found"
    echo ""
    echo "Use 'sudo pkill openfortivpn' to disconnect"
    exit 0
fi

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
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
    echo "❌ OTP script not found: $OTP_SCRIPT"
    echo "Please ensure get_otp_code.scpt exists"
    exit 1
fi

echo "📝 Configuration file: $CONFIG_FILE"
echo "📱 OTP extraction script: $OTP_SCRIPT"
echo ""
echo "🔄 Starting FortiVPN connection..."

# Pre-authenticate sudo to enable Touch ID and extend timeout
echo "🔐 Authenticating with Touch ID (or password)..."
if ! sudo -v; then
    echo "❌ Authentication failed"
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
        echo "🔐 Stopped sudo refresh process"
    fi
    
    # Kill any running openfortivpn processes
    if pgrep -f "openfortivpn" > /dev/null; then
        echo "🔌 Disconnecting FortiVPN..."
        sudo pkill openfortivpn 2>/dev/null
        sleep 1
        echo "✅ FortiVPN disconnected"
    fi
    
    # Remove temporary files
    rm -f /tmp/forti_expect.exp
    
    echo "🏁 Cleanup completed"
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

# Enable debug logging
log_user 1
exp_internal 0

puts "🔗 Connecting to FortiVPN server..."

# Start openfortivpn with verbose mode
spawn sudo openfortivpn --config=$config_file -v

# Initialize OTP submission flag
set otp_submitted 0

# Handle the various prompts that may appear
while {1} {
    expect {
        "Password:" {
            puts "❌ Sudo authentication expired. Please run the script again."
            exit 1
        }
        "DEBUG:  Loaded configuration file" {
            puts "📝 Configuration loaded successfully"
            exp_continue
        }
        "DEBUG:  Resolving gateway host ip" {
            puts "🔍 Resolving server address..."
            exp_continue
        }
        "DEBUG:  Establishing TLS connection" {
            puts "🔐 Establishing secure connection..."
            exp_continue
        }
        "DEBUG:  server_addr:" {
            puts "🌐 Server address resolved"
            exp_continue
        }
        "Connected to gateway" {
            puts "✅ Connected to gateway successfully!"
            exp_continue
        }
        -re "Two.*factor.*token" {
            # Skip if we've already submitted an OTP
            if {$otp_submitted == 1} {
                puts "🔄 Waiting for authentication result..."
                exp_continue
            }
            
            puts "\n🔐 2FA prompt detected!"
            puts "⏰ Starting CONTINUOUS OTP monitoring..."
            puts "🔍 Checking Messages app constantly for new OTP codes"
            puts ""
            
            # Record the current timestamp when 2FA prompt appears
            set prompt_time [clock seconds]
            puts "DEBUG: Timestamp recorded: $prompt_time"
            
            # Continuous monitoring with very short intervals (0.5 seconds)
            set otp_code ""
            set max_attempts 120  ; # 120 * 0.5 = 60 seconds total
            
            for {set i 0} {$i < $max_attempts} {incr i} {
                if {[expr $i % 20] == 0} {
                    puts "💭 Monitoring... ([expr $i/2] seconds elapsed)"
                }
                
                catch {
                    # Pass the prompt timestamp to the script so it only looks for newer messages
                    set otp_code [exec osascript $otp_script $prompt_time]
                    puts "DEBUG: OTP script returned: '$otp_code'"
                } catch_result
                
                if {$otp_code != ""} {
                    puts "\n✅ OTP detected: $otp_code"
                    puts "🔑 Auto-entering OTP code..."
                    send "$otp_code\r"
                    puts "🛑 Stopping OTP monitoring - code submitted"
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
                puts "\n❌ No OTP code detected after 60 seconds"
                puts "📱 Please enter the OTP code manually:"
                interact
                exit 1
            }
            
            # Continue to check connection result
            exp_continue
        }
        "Authenticated" {
            puts "\n🎉 Authentication successful!"
            puts "🛑 Stopping OTP monitoring - authentication complete"
            exp_continue
        }
        "Negotiation complete" {
            puts "\n🔗 VPN negotiation complete"
            puts "🛑 Stopping OTP monitoring - tunnel negotiation complete"
            exp_continue
        }
        "tunnel is up and running" {
            puts "\n🎉 Connected ✅"
            puts "🔒 VPN tunnel established - press Ctrl+C to disconnect"
            puts "🛑 OTP monitoring stopped - connection established"
            interact
        }
        "Invalid token" {
            puts "\n❌ Invalid OTP token - may be expired"
            puts "🛑 Stopping OTP monitoring - authentication failed"
            puts "🔌 Disconnecting FortiVPN..."
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Login failed" {
            puts "\n❌ Login failed - check credentials"
            puts "🛑 Stopping OTP monitoring - login failed"
            puts "🔌 Disconnecting FortiVPN..."
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "Could not authenticate to gateway" {
            puts "\n❌ Authentication failed - check credentials or OTP"
            puts "🛑 Stopping OTP monitoring - authentication failed"
            puts "🔌 Disconnecting FortiVPN..."
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        "authentication failed" {
            puts "\n❌ Authentication failed"
            puts "🛑 Stopping OTP monitoring - authentication failed"
            puts "🔌 Disconnecting FortiVPN..."
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        timeout {
            puts "\n❌ Connection timeout"
            puts "🔌 Disconnecting FortiVPN due to timeout..."
            catch {exec sudo pkill openfortivpn}
            exit 1
        }
        eof {
            puts "\n🔚 Connection ended unexpectedly"
            puts "🔌 Disconnecting FortiVPN due to unexpected end..."
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
echo "🏁 FortiVPN automation completed"
