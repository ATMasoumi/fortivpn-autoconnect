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

# Pre-authenticate sudo to enable Touch ID
echo "🔐 Authenticating with Touch ID (or password)..."
if ! sudo -v; then
    echo "❌ Authentication failed"
    exit 1
fi

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

# Handle the various prompts that may appear
while {1} {
    expect {
        "Password:" {
            puts "🔐 Please enter your sudo password:"
            interact -o "\r" return
            exp_continue
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
        "tunnel is up and running" {
            puts "\n🎉 Connected ✅"
            puts "🔒 VPN tunnel established - press Ctrl+C to disconnect"
            interact
        }
        "Invalid token" {
            puts "\n❌ Invalid OTP token - may be expired"
            exit 1
        }
        "Login failed" {
            puts "\n❌ Login failed - check credentials"
            exit 1
        }
        "Could not authenticate to gateway" {
            puts "\n❌ Authentication failed - check credentials or OTP"
            exit 1
        }
        timeout {
            puts "\n❌ Connection timeout"
            exit 1
        }
        eof {
            puts "\n🔚 Connection ended unexpectedly"
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

# Cleanup
rm -f /tmp/forti_expect.exp

echo ""
echo "🏁 FortiVPN automation completed"
