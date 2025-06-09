# FortiVPN Auto-Connect

🚀 **Automated FortiVPN connection with 2FA OTP extraction from Messages app**

Transform your VPN connection experience from a complex multi-step process into a simple one-command operation with automatic 2FA handling.

## ✨ Features

- **🔄 Fully Automated**: Connect with a single command (`fortivpn-autoconnect`)
- **📱 Smart 2FA**: Automatically extracts OTP codes from Messages app
- **🔐 Touch ID Integration**: Automatic Touch ID configuration for sudo_local (optional)
- **⚡ Fast Connection**: Continuous monitoring for instant OTP detection
- **🛡️ Secure**: Config files stored with proper permissions (600)
- **🔧 Easy Setup**: Enhanced interactive setup wizard with system validation
- **📊 Status Monitoring**: Built-in connection status checking and troubleshooting
- **🎨 Color Output**: Beautiful color-coded messages for better user experience
- **🔍 Smart Validation**: Automatic input validation and error handling
- **🔑 Auto Certificate**: Automatic trusted certificate detection and configuration
- **⚙️ Smart Defaults**: Intelligent port detection (443/4443) and configuration

## 🎯 Quick Start (Homebrew Installation)

The easiest way to install and use FortiVPN Auto-Connect:

```bash
# 1. Add the tap
brew tap ATMasoumi/fortivpn

# 2. Install the tool
brew install fortivpn-autoconnect

# 3. Run setup wizard
fortivpn-setup
```

That's it! After setup, connect with:
```bash
fortivpn-autoconnect
```

**Optional**: Create your own alias for convenience:
```bash
# Add to your ~/.zshrc or ~/.bashrc
alias forti="fortivpn-autoconnect"
# Or any other alias you prefer:
alias vpn="fortivpn-autoconnect"
```

## 📋 What This Replaces

### Before (Manual Process):
1. Install `openfortivpn` and `expect` manually
2. Create and configure VPN config file
3. Set up Touch ID for sudo
4. Grant Messages app permissions
5. Run complex connection commands
6. Manually enter 2FA codes
7. Debug connection issues

**Time:** 20-45 minutes setup + 2-5 minutes per connection

### After (Automated Process):
1. `brew tap ATMasoumi/fortivpn`
2. `brew install fortivpn-autoconnect`  
3. `fortivpn-setup` (enhanced guided configuration with auto-validation)

**Time:** 2-3 minutes setup + 5-10 seconds per connection

## 🌟 What's New in v1.5.0

- **🔍 Enhanced System Validation**: Comprehensive checking of Full Disk Access, Touch ID, Messages app, and dependencies
- **🎨 Colorized Output**: Beautiful color-coded messages throughout the setup and connection process
- **🔧 Improved Setup Wizard**: Better input validation, password confirmation, and error handling  
- **🔑 Smart Certificate Detection**: Multiple methods for automatic trusted certificate detection
- **📱 Messages Integration Check**: Validates SMS forwarding and OTP delivery capabilities
- **⚙️ Intelligent Defaults**: Port 443 as default, smart Homebrew installation, better error recovery
- **🚀 New Command Options**: `--skip-check`, improved `--help`, enhanced status reporting
- **🔄 Robust Installation**: Automatic Homebrew installation and dependency management

## 🔧 Manual Installation

If you prefer not to use Homebrew:

```bash
# Clone the repository
git clone https://github.com/ATMasoumi/fortivpn-autoconnect.git
cd fortivpn-autoconnect

# Install dependencies
brew install openfortivpn expect

# Copy config template and edit
cp forticonfig.template forticonfig
nano forticonfig

# Make scripts executable
chmod +x fortivpn-autoconnect fortivpn-setup

# Run the connection script
./fortivpn-autoconnect
```

## 📱 Prerequisites

### Required:
- **macOS** with Messages app
- **Homebrew** package manager
- **VPN account** with 2FA enabled
- **Messages app** configured to receive OTP SMS

### System Permissions:
- **Touch ID for sudo** (recommended)
- **Full Disk Access** for Terminal app
- **Messages app** access permissions

## 🛠️ Configuration

### Automatic Configuration (Recommended):
```bash
fortivpn-setup
```

The enhanced setup wizard will guide you through:
- **System Requirements Check**: Validates all prerequisites automatically
- **Dependency Installation**: Installs Homebrew, openfortivpn, and expect if needed
- **VPN Configuration**: Interactive credential setup with validation
- **Certificate Detection**: Automatic trusted certificate discovery and configuration
- **Permission Validation**: Checks Full Disk Access, Touch ID, and Messages app access
- **Connection Testing**: Verifies everything works before completion

### Advanced Setup Options:
```bash
fortivpn-setup --help              # Show all available commands
fortivpn-setup --status            # Check current configuration status
fortivpn-setup --configure         # Configure VPN settings only
fortivpn-setup --install-deps      # Install dependencies only  
fortivpn-setup --complete          # Run complete automated setup
fortivpn-setup --skip-check        # Skip system requirements check
```

### Manual Configuration:
Edit `~/.fortivpn/forticonfig`:
```
host = your-vpn-server.com
port = 443                    # Default changed from 4443 to 443 (more common)
username = your.username
password = your_password
trusted-cert = certificate_hash_if_needed  # Auto-detected during setup
```

## 🚀 Usage

### Connect to VPN:
```bash
fortivpn-autoconnect             # Main command
# or
fortivpn-autoconnect          # Full command
```

### Management Commands:
```bash
fortivpn-setup --status       # Check current configuration and system status
fortivpn-setup --configure    # Reconfigure VPN settings with validation
fortivpn-setup --install-deps # Install or update dependencies
fortivpn-setup --help         # Show comprehensive help and usage guide
```

## 🔍 How It Works

1. **System Validation**: Enhanced setup validates all prerequisites automatically
2. **Connection Initiation**: Script starts OpenFortiVPN with your configuration
3. **Authentication**: Uses Touch ID for sudo authentication (or password fallback)
4. **2FA Detection**: Monitors for two-factor authentication prompts with color feedback
5. **OTP Extraction**: Automatically reads latest OTP from Messages database
6. **Auto-Entry**: Enters the OTP code automatically with confirmation
7. **Tunnel Establishment**: Completes VPN connection with status indicators
8. **Status Monitoring**: Shows colorized connection status and keeps tunnel active

## 🔐 Security & Privacy

- **Config files** stored in `~/.fortivpn/` with 600 permissions (owner read/write only)
- **No credentials** exposed in command history, logs, or temporary files
- **Touch ID integration** for secure sudo access (optional, password fallback available)
- **Secure OTP handling** - codes read directly from Messages database (no network exposure)
- **Automatic cleanup** of temporary files and sensitive data
- **Certificate validation** with automatic trusted certificate detection
- **Input validation** prevents configuration errors and security issues

## 🐛 Troubleshooting

### Enhanced Setup Diagnostics:
```bash
fortivpn-setup --status        # Comprehensive system status check
fortivpn-setup --skip-check    # Skip system validation if needed
```

### Common Issues:

**"Config file not found"**
- The main script now automatically triggers setup
- Or run: `fortivpn-setup --configure`

**"System requirements not met"**
- Run: `fortivpn-setup` for automatic validation and guidance
- Check Full Disk Access: System Settings > Privacy & Security > Full Disk Access
- Toggle ON the switch next to Terminal and restart Terminal

**"OTP detection failed"**
- Verify Messages app is receiving SMS codes
- Check SMS forwarding from iPhone: Settings > Messages > Text Message Forwarding
- Test Messages database access: `sqlite3 ~/Library/Messages/chat.db '.tables'`

**"Certificate errors"**
- Setup now auto-detects certificates from multiple sources
- Manual fallback: Connect once manually to accept certificate
- Or run: `fortivpn-setup --configure` to retry auto-detection

**"Authentication failed"**
- Setup validates credentials during configuration
- Check VPN credentials in config file
- Touch ID is now optional (password fallback available)

**"Connection timeout"**
- Setup validates server connectivity
- Check VPN server address and port (default now 443 instead of 4443)
- Test connectivity: `nc -zv your-server.com 443`

**"Homebrew issues"**
- Setup can auto-install Homebrew if missing
- Manual install: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Debug Mode:
For verbose output, edit the connection script and set:
```bash
exp_internal 1  # In the expect script section
```

## 📊 Status Commands

```bash
# Enhanced system status (recommended)
fortivpn-setup --status

# Check if VPN is running
ps aux | grep openfortivpn

# Disconnect VPN  
sudo pkill openfortivpn

# View config (password hidden for security)
fortivpn-setup --status | grep -A 10 "Current settings"

# Test all dependencies and permissions
fortivpn-setup --skip-check    # Skip validation, go to menu

# Reinstall or update dependencies
fortivpn-setup --install-deps
```

## 🔄 Updates

### Homebrew Installation:
```bash
brew update
brew upgrade fortivpn-autoconnect
```

### Manual Installation:
```bash
cd fortivpn-autoconnect
git pull origin main
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details.

## 🙋‍♂️ Support

- **Issues**: [GitHub Issues](https://github.com/ATMasoumi/fortivpn-autoconnect/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ATMasoumi/fortivpn-autoconnect/discussions)

## 🎉 Success Stories

> "The v1.5.0 update is incredible! Setup went from 45 minutes to 2 minutes, and the color coding makes everything so much clearer. The automatic certificate detection saved me hours of debugging!" - DevOps Engineer

> "The automated setup and 2FA detection works flawlessly. No more manual OTP entry!" - Remote Developer

> "Went from dreading VPN connections to connecting in seconds. The 2FA automation is magic, and now the setup is foolproof!" - Security Analyst

---

**Made with ❤️ by [Amin Torabi](https://github.com/ATMasoumi)**

*Transform your VPN workflow today! v1.5.0 - Now with enhanced automation and beautiful UX*
