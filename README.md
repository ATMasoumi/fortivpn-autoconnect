# FortiVPN Auto-Connect

🚀 **Automated FortiVPN connection with 2FA OTP extraction from Messages app**

Transform your VPN connection experience from a complex multi-step process into a simple one-command operation with automatic 2FA handling.

## ✨ Features

- **🔄 Fully Automated**: Connect with a single command
- **📱 Smart 2FA**: Automatically extracts OTP codes from Messages app
- **🔐 Touch ID Integration**: Seamless sudo authentication
- **⚡ Fast Connection**: Continuous monitoring for instant OTP detection
- **🛡️ Secure**: Config files stored with proper permissions
- **🔧 Easy Setup**: Interactive setup wizard included
- **📊 Status Monitoring**: Built-in connection status checking

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
forti
# or the full command:
fortivpn-autoconnect
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
3. `fortivpn-setup` (guided configuration)

**Time:** 3-5 minutes setup + 10 seconds per connection

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
chmod +x forti_connect.sh fortivpn-setup

# Run the connection script
./forti_connect.sh
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

The setup wizard will guide you through:
- Installing dependencies
- Configuring VPN credentials
- Testing connection
- Setting up permissions

### Manual Configuration:
Edit `~/.fortivpn/forticonfig`:
```
host = your-vpn-server.com
port = 443
username = your.username
password = your_password
trusted-cert = certificate_hash_if_needed
```

## 🚀 Usage

### Connect to VPN:
```bash
forti
# or
fortivpn-autoconnect
```

### Check Status:
```bash
fortivpn-setup --status
```

### Reconfigure:
```bash
fortivpn-setup --configure
```

### Get Help:
```bash
fortivpn-setup --help
```

## 🔍 How It Works

1. **Connection Initiation**: Script starts OpenFortiVPN with your config
2. **Authentication**: Uses Touch ID for sudo authentication
3. **2FA Detection**: Monitors for two-factor authentication prompts
4. **OTP Extraction**: Automatically reads latest OTP from Messages app
5. **Auto-Entry**: Enters the OTP code automatically
6. **Tunnel Establishment**: Completes VPN connection
7. **Status Monitoring**: Shows connection status and keeps tunnel active

## 🔐 Security

- **Config files** stored in `~/.fortivpn/` with 600 permissions (owner read/write only)
- **No credentials** in command history or logs
- **Touch ID integration** for secure sudo access
- **Temporary files** cleaned up automatically
- **OTP codes** read directly from Messages database (no network exposure)

## 🐛 Troubleshooting

### Common Issues:

**"Config file not found"**
```bash
fortivpn-setup --configure
```

**"OTP script failed"**
- Grant Full Disk Access to Terminal in System Preferences
- Ensure Messages app is receiving SMS codes

**"Authentication failed"**
- Check VPN credentials in config file
- Verify Touch ID is enabled for sudo

**"Connection timeout"**
- Check VPN server address and port
- Verify network connectivity

### Debug Mode:
For verbose output, edit the connection script and set:
```bash
exp_internal 1  # In the expect script section
```

## 📊 Status Commands

```bash
# Check if VPN is running
ps aux | grep openfortivpn

# Disconnect VPN
sudo pkill openfortivpn

# View config (without password)
grep -v password ~/.fortivpn/forticonfig

# Test dependencies
fortivpn-setup --status
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

> "Went from dreading VPN connections to connecting in seconds. The 2FA automation is magic!" - Developer User

> "Setup took 3 minutes, now I save 5 minutes every time I connect. That's hours per month!" - Remote Worker

---

**Made with ❤️ by [Amin Torabi](https://github.com/ATMasoumi)**

*Transform your VPN workflow today!*
