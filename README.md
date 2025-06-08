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

## 🎯 Quick Start (Homebrew Installation)

```bash
# 1. Add the tap
brew tap amintorabi/fortivpn

# 2. Install the tool
brew install fortivpn-autoconnect

# 3. Run setup wizard
fortivpn-setup
```

After setup, connect with:
```bash
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

**Time:** 20-45 minutes setup + 2-5 minutes per connection

### After (Automated Process):
1. `brew tap amintorabi/fortivpn`
2. `brew install fortivpn-autoconnect`
3. `fortivpn-setup` (guided configuration)

**Time:** 3-5 minutes setup + 10 seconds per connection

## 🔧 Manual Installation

```bash
# Clone the repository
git clone https://github.com/amintorabi/fortivpn-autoconnect.git
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

## �� Usage

### Connect to VPN:
```bash
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

## 🔍 How It Works

1. **Connection Initiation**: Script starts OpenFortiVPN with your config
2. **Authentication**: Uses Touch ID for sudo authentication
3. **2FA Detection**: Monitors for two-factor authentication prompts
4. **OTP Extraction**: Automatically reads latest OTP from Messages app
5. **Auto-Entry**: Enters the OTP code automatically
6. **Tunnel Establishment**: Completes VPN connection

## 🔐 Security

- **Config files** stored in `~/.fortivpn/` with 600 permissions
- **No credentials** in command history or logs
- **Touch ID integration** for secure sudo access
- **Temporary files** cleaned up automatically

## 📝 License

MIT License - see LICENSE file for details.

---

**Made with ❤️ by [Amin Torabi](https://github.com/amintorabi)**
