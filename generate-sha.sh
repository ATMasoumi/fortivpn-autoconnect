#!/bin/bash

# Automated SHA256 generation script for FortiVPN Auto-Connect releases
# Usage: ./generate-sha.sh v2.0.2

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Version tag required${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./generate-sha.sh v2.0.2"
    echo "  ./generate-sha.sh v2.1.0"
    echo ""
    echo -e "${YELLOW}Note: Make sure the tag exists on GitHub before running this script${NC}"
    exit 1
fi

VERSION="$1"

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid version format${NC}"
    echo -e "${YELLOW}Expected format: v2.0.1, v2.1.0, etc.${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Generating SHA256 for FortiVPN Auto-Connect $VERSION...${NC}"
echo ""

# Generate SHA256
echo -e "${CYAN}📥 Downloading release tarball...${NC}"
SHA=$(curl -sL "https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1)

if [ -n "$SHA" ] && [ ${#SHA} -eq 64 ]; then
    echo -e "${GREEN}✅ SHA256 successfully generated!${NC}"
    echo ""
    echo -e "${CYAN}📋 Release Information:${NC}"
    echo "  Version: $VERSION"
    echo "  Release Date: $(date +%Y-%m-%d)"
    echo "  Download URL: https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz"
    echo "  SHA256: $SHA"
    echo ""
    
    echo -e "${CYAN}📝 Homebrew Formula Update:${NC}"
    echo "  url \"https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz\""
    echo "  sha256 \"$SHA\""
    echo "  version \"${VERSION#v}\""
    echo ""
    
    echo -e "${CYAN}📄 RELEASE_INFO.md Entry:${NC}"
    echo "## Version ${VERSION#v}"
    echo "- **Release Date**: $(date +%Y-%m-%d)"
    echo "- **Git Tag**: $VERSION"
    echo "- **SHA256**: \`$SHA\`"
    echo "- **Download URL**: https://github.com/ATMasoumi/fortivpn-autoconnect/archive/$VERSION.tar.gz"
    echo ""
    
    echo -e "${GREEN}🎉 Ready for Homebrew formula update!${NC}"
else
    echo -e "${RED}❌ Failed to generate SHA256${NC}"
    echo ""
    echo -e "${YELLOW}Possible causes:${NC}"
    echo "  • Tag $VERSION doesn't exist on GitHub yet"
    echo "  • Network connectivity issues"
    echo "  • GitHub is temporarily unavailable"
    echo ""
    echo -e "${CYAN}💡 Solutions:${NC}"
    echo "  1. Make sure you've pushed the tag: git push origin $VERSION"
    echo "  2. Wait a few minutes for GitHub to process the tag"
    echo "  3. Check the tag exists: https://github.com/ATMasoumi/fortivpn-autoconnect/releases"
    exit 1
fi
