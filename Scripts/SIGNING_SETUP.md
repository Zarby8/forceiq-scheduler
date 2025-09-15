# Code Signing & Notarization Setup

This guide will help you configure ForceIQ Scheduler for code signing and notarization with your Apple Developer account.

## Prerequisites

1. **Apple Developer Account**: Active paid Apple Developer account
2. **Xcode**: Latest version installed with command line tools
3. **Developer ID Certificate**: "Developer ID Application" certificate installed in Keychain

## Setup Steps

### 1. Get Your Team ID

1. Sign in to [Apple Developer](https://developer.apple.com/)
2. Go to "Account" → "Membership Details"
3. Copy your **Team ID** (10-character alphanumeric string)

### 2. Create App-Specific Password

1. Sign in to [Apple ID](https://appleid.apple.com/)
2. Go to "App-Specific Passwords"
3. Generate a new password for "ForceIQ Scheduler Notarization"
4. Save this password securely

### 3. Set Environment Variables

Add these to your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
# Apple Developer Configuration for ForceIQ Scheduler
export DEVELOPMENT_TEAM="YOUR_TEAM_ID_HERE"
export APPLE_ID="your.email@example.com"
export APPLE_ID_PASSWORD="your-app-specific-password"
```

Then reload your shell:
```bash
source ~/.zshrc
```

### 4. Install Developer ID Certificate

1. In Xcode, go to **Preferences** → **Accounts**
2. Add your Apple ID if not already added
3. Select your team and click "Manage Certificates..."
4. Click the "+" button and select "Developer ID Application"
5. The certificate will be automatically installed

## Building & Signing

### Development Build (Local Testing)
```bash
cd /path/to/forceiq-scheduler
./Scripts/build-signed.sh
```

### Production Build with Notarization
```bash
cd /path/to/forceiq-scheduler
./Scripts/notarize.sh
```

## Verification

After building, verify your setup:

```bash
# Check certificate is installed
security find-identity -v -p codesigning

# Verify app signature
codesign --verify --verbose=4 "build/ForceIQ Scheduler.app"

# Test Gatekeeper
spctl --assess --verbose=4 --type execute "build/ForceIQ Scheduler.app"
```

## Troubleshooting

### "No signing certificate" Error
- Ensure Developer ID Application certificate is installed
- Check that DEVELOPMENT_TEAM matches your Apple Developer Team ID

### Notarization Fails
- Verify APPLE_ID and APPLE_ID_PASSWORD are correct
- Ensure your Apple Developer account is in good standing
- Check that hardened runtime is enabled (already configured)

### Gatekeeper Rejects App
- Ensure app is properly notarized and stapled
- Try: `xattr -dr com.apple.quarantine "ForceIQ Scheduler.app"`

## Distribution

After successful notarization:

1. **DMG Created**: `build/ForceIQ-Scheduler.dmg`
2. **Notarized & Stapled**: Ready for distribution
3. **Gatekeeper Compatible**: Will run on user machines without warnings

The DMG can be distributed via:
- Direct download from your website
- Email distribution
- Third-party distribution platforms
- Mac App Store (requires separate signing configuration)

## Security Notes

- Never commit certificates or private keys to version control
- Use app-specific passwords, not your main Apple ID password
- Keep your Developer ID certificate private and secure
- Regularly rotate app-specific passwords for security

---

For questions or issues, refer to Apple's [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).