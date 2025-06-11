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

## Release Process (Required for Every Tag Release)

### Step-by-Step Release Workflow:

1. **Update Version Number**
   ```bash
   # Update VERSION variable in fortivpn-autoconnect script
   VERSION="X.Y.Z"
   ```

2. **Commit Changes and Create Tag**
   ```bash
   git add .
   git commit -m "Release vX.Y.Z: [brief description]"
   git tag -a vX.Y.Z -m "Version X.Y.Z: [detailed description]"
   git push origin main
   git push origin vX.Y.Z
   ```

3. **Generate SHA256 (REQUIRED)**
   ```bash
   # Wait for GitHub to process the tag, then generate SHA
   curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/vX.Y.Z.tar.gz | shasum -a 256
   ```

4. **Update RELEASE_INFO.md**
   - Add new version section with SHA256
   - Include release date, commit hash, and key features
   - Update formula information

5. **Update Homebrew Formula**
   - Update `url`, `sha256`, and `version` in the tap repository
   - Test the formula before publishing

### SHA Generation Examples:

```bash
# For a new version X.Y.Z:
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/vX.Y.Z.tar.gz | shasum -a 256

# Example for v2.0.2:
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.0.2.tar.gz | shasum -a 256

# Example for v2.1.0:
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.1.0.tar.gz | shasum -a 256
```

### Automated SHA Generation Script:
```bash
#!/bin/bash
# save as generate-sha.sh in project root

if [ -z "$1" ]; then
    echo "Usage: ./generate-sha.sh v2.0.2"
    exit 1
fi

VERSION="$1"
echo "🔍 Generating SHA256 for version $VERSION..."
echo ""

SHA=$(curl -sL "https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1)

if [ -n "$SHA" ]; then
    echo "✅ SHA256 for $VERSION:"
    echo "$SHA"
    echo ""
    echo "📋 Formula update:"
    echo "url \"https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz\""
    echo "sha256 \"$SHA\""
    echo "version \"${VERSION#v}\""
else
    echo "❌ Failed to generate SHA256. Make sure the tag exists on GitHub."
    exit 1
fi
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
