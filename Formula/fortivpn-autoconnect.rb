# FortiVPN Auto-Connect Homebrew Formula
# 
# To update for new releases:
# 1. Generate SHA: curl -sL https://github.com/ATMasoumi/fortivpn-autoconnect/archive/vX.Y.Z.tar.gz | shasum -a 256
# 2. Update url, sha256, and version fields below
# 3. Test with: brew install --build-from-source ATMasoumi/fortivpn/fortivpn-autoconnect

class FortivpnAutoconnect < Formula
  desc "Automated FortiVPN connection with 2FA OTP extraction from Messages app"
  homepage "https://github.com/ATMasoumi/fortivpn-autoconnect"
  url "https://github.com/ATMasoumi/fortivpn-autoconnect/archive/v2.0.1.tar.gz"
  sha256 "7db739a24181468b561c19ee5add0dff8f8c87f269f53af4e63e2acc5fea6d61"
  license "MIT"
  version "2.0.1"

  depends_on "openfortivpn"
  depends_on "expect"

  def install
    # Install main scripts to bin
    bin.install "fortivpn-autoconnect"
    bin.install "fortivpn-setup"
    bin.install "get_otp_code.scpt"
    
    # Create config directory structure for user
    prefix.install "forticonfig.template"
    
    # Install documentation
    doc.install "README.md"
    doc.install "LICENSE"
    
    # Make scripts executable
    chmod 0755, bin/"fortivpn-autoconnect"
    chmod 0755, bin/"fortivpn-setup"
    chmod 0755, bin/"get_otp_code.scpt"
  end

  def caveats
    <<~EOS
      🚀 FortiVPN Auto-Connect v#{version} installed successfully!
      
      To get started:
      1. Run the setup wizard: fortivpn-setup
      2. Follow the guided configuration process
      3. Connect to your VPN: fortivpn-autoconnect
      
      📋 Requirements:
      - Full Disk Access for Terminal (for Messages app access)
      - Touch ID configured for sudo (optional, but recommended)
      - Messages app configured to receive SMS OTP codes
      
      🔧 Configuration files will be stored in ~/.fortivpn/
      
      For help and troubleshooting: https://github.com/ATMasoumi/fortivpn-autoconnect
    EOS
  end

  test do
    # Test that the main script exists and is executable
    assert_predicate bin/"fortivpn-autoconnect", :exist?
    assert_predicate bin/"fortivpn-autoconnect", :executable?
    
    # Test that setup script exists and is executable
    assert_predicate bin/"fortivpn-setup", :exist?
    assert_predicate bin/"fortivpn-setup", :executable?
    
    # Test that OTP script exists
    assert_predicate bin/"get_otp_code.scpt", :exist?
    
    # Test version output
    system bin/"fortivpn-autoconnect", "--help"
    system bin/"fortivpn-setup", "--help"
  end
end
