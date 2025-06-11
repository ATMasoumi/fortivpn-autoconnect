# GitHub Copilot Instructions for FortiVPN Auto-Connect

## Project Overview
This is a macOS automation tool that provides seamless FortiVPN connections with automatic 2FA OTP extraction from the Messages app. The project includes dual authentication support (Touch ID/password), Persian/English SMS detection, and comprehensive error handling.

## Code Style & Standards

### Shell Scripting (Bash)
- Use `#!/bin/bash` shebang
- Always include `set -e` for error handling
- Use color-coded output with predefined color variables
- Follow consistent indentation (4 spaces)
- Include comprehensive error messages with troubleshooting guidance
- Use descriptive variable names with clear prefixes (e.g., `CONFIG_FILE`, `OTP_SCRIPT`)

### AppleScript (.scpt files)
- Use proper error handling with `try...on error` blocks
- Include debug logging for troubleshooting
- Support both English and Persian/Farsi text patterns
- Use SQLite queries for Messages database access when possible
- Fall back to AppleScript Messages app access if database fails

### Expect Scripts
- Use proper timeout values (typically 120 seconds for VPN connections)
- Include colored output for better user experience
- Handle multiple authentication scenarios (Touch ID, password, 2FA)
- Provide clear progress indicators during long operations

## Key Components

### Main Scripts
- `fortivpn-autoconnect`: Main connection script with dual authentication
- `fortivpn-setup`: Interactive setup wizard with system validation
- `get_otp_code.scpt`: OTP extraction from Messages app (English/Persian)

### Configuration
- Config files stored in `~/.fortivpn/` with 600 permissions
- Support both Homebrew and manual installation paths
- Auto-detect installation type and adjust paths accordingly

### Security Considerations
- Never expose passwords in logs or command history
- Use secure input methods (`stty -echo` for password entry)
- Validate all user inputs
- Clean up temporary files in cleanup functions
- Use proper file permissions (600 for config files)

## Architecture Patterns

### Path Detection
```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ "$SCRIPT_DIR" =~ /usr/local/bin ]] || [[ "$SCRIPT_DIR" =~ /opt/homebrew/bin ]]; then
    # Homebrew installation
    CONFIG_DIR="$HOME/.fortivpn"
    CONFIG_FILE="$CONFIG_DIR/forticonfig"
else
    # Development/manual installation
    CONFIG_FILE="$SCRIPT_DIR/forticonfig"
fi
```

### Error Handling
```bash
cleanup() {
    echo "🧹 Cleaning up..."
    # Kill background processes
    # Remove temporary files
    # Disconnect VPN if needed
}

trap cleanup EXIT
trap cleanup INT
trap cleanup TERM
```

### Color Output
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}✅ Success message${NC}"
echo -e "${RED}❌ Error message${NC}"
echo -e "${YELLOW}⚠️  Warning message${NC}"
```

## Feature Requirements

### Dual Authentication Support
- Detect Touch ID availability using `bioutil -s`
- Provide password fallback when Touch ID unavailable
- Pre-authenticate sudo to avoid expect script complications
- Handle both interactive and non-interactive environments

### Multi-language OTP Detection
- Support English patterns: "VPN FortiGate", "OTP", "FortiGate"
- Support Persian patterns: "کد OTP", "واحد عملیات"
- Use timestamp-based filtering to only check messages after 2FA prompt
- Prefer SQLite database queries over AppleScript for performance

### System Validation
- Check Homebrew installation
- Validate dependencies (openfortivpn, expect)
- Verify Full Disk Access for Terminal
- Test Messages database connectivity
- Validate VPN server connectivity

## Release Process

### Version Management
- Update VERSION variable in main script
- Create git tag with `v` prefix (e.g., `v2.0.1`)
- Generate SHA256 for Homebrew formula
- Update RELEASE_INFO.md with complete release information

### SHA Generation for Homebrew
```bash
curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/vX.Y.Z.tar.gz | shasum -a 256
```

### Testing Requirements
- Test both Touch ID and password authentication modes
- Verify OTP detection with both English and Persian messages
- Test Homebrew and manual installation paths
- Validate all error handling scenarios
- Test connection flow end-to-end

## Common Patterns to Suggest

### When adding new features:
1. Include proper error handling and cleanup
2. Add colored output for user feedback
3. Support both installation types (Homebrew/manual)
4. Include validation and testing
5. Update documentation accordingly

### When modifying OTP detection:
1. Test with both database and AppleScript methods
2. Include timestamp filtering
3. Support both English and Persian patterns
4. Add debug logging for troubleshooting

### When updating authentication:
1. Maintain dual Touch ID/password support
2. Handle timeout scenarios gracefully
3. Provide clear user guidance
4. Test non-interactive environments

## Dependencies
- macOS with Messages app
- Homebrew package manager
- openfortivpn (VPN client)
- expect (automation tool)
- sqlite3 (Messages database access)
- bioutil (Touch ID detection)

## File Permissions
- Executable scripts: 755
- Configuration files: 600
- AppleScript files: 755
- Documentation: 644
