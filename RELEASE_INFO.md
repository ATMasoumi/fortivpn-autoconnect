# FortiVPN Auto-Connect Release Information

## Version 2.0.1
- **Release Date**: 2025-01-11
- **Git Tag**: v2.0.1
- **Commit**: 0da22b7
- **SHA256**: `7db739a24181468b561c19ee5add0dff8f8c87f269f53af4e63e2acc5fea6d61`
- **Download URL**: https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.0.1.tar.gz

### Key Features in v2.0.1:
- Enhanced dual authentication support (Touch ID and password modes)
- Persian/English OTP detection with patterns کد OTP and واحد عملیات
- Improved expect script password handling with stty -echo
- Pre-authentication logic for password mode
- Enhanced error messages with detailed troubleshooting
- Fixed Touch ID hardware detection using bioutil -s
- Connection timing optimization with 1000ms delay
- Robust Persian SMS support

### Formula Update:
```ruby
url "https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.0.1.tar.gz"
sha256 "7db739a24181468b561c19ee5add0dff8f8c87f269f53af4e63e2acc5fea6d61"
version "2.0.1"
```

## How to Generate SHA for Future Releases:

```bash
# For a new version X.Y.Z:
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/vX.Y.Z.tar.gz | shasum -a 256

# Example for v2.0.2:
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.0.2.tar.gz | shasum -a 256
```

## Homebrew Tap Maintenance:

1. Update the formula in the tap repository: https://github.com/ATMasoumi/homebrew-fortivpn
2. Update the `url`, `sha256`, and `version` fields
3. Test the formula: `brew install --build-from-source ATMasoumi/fortivpn/fortivpn-autoconnect`
4. Commit and push changes to the tap repository

## Installation Commands:

```bash
# Add the tap (one-time setup)
brew tap ATMasoumi/fortivpn

# Install or upgrade the package
brew install fortivpn-autoconnect
brew upgrade fortivpn-autoconnect
```
