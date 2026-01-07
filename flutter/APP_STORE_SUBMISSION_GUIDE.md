# iOS App Store Submission Guide

This guide walks you through the process of submitting your Flutter app to the iOS App Store.

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Sign up at [developer.apple.com](https://developer.apple.com)
   - Enroll in the Apple Developer Program

2. **Xcode** (latest version recommended)
   - Download from Mac App Store
   - Ensure Command Line Tools are installed: `xcode-select --install`

3. **App Store Connect Access**
   - Access granted through your Apple Developer account

## Step 1: Configure App Identity

### 1.1 Set Bundle Identifier

1. Open `flutter/ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in the left sidebar
3. Select **Runner** target
4. Go to **Signing & Capabilities** tab
5. Set **Bundle Identifier** (e.g., `com.yourcompany.compostkaki`)
   - Must be unique and match your App Store Connect app ID
   - Format: `com.[company].[appname]`

### 1.2 Configure Version Numbers

Update `flutter/pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# Example: 1.0.0+1 means version 1.0.0, build 1
```

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: CompostKaki (or your app name)
   - **Primary Language**: English (or your primary language)
   - **Bundle ID**: Select the bundle identifier you created
   - **SKU**: Unique identifier (e.g., `compostkaki-001`)
   - **User Access**: Full Access (or as needed)

## Step 3: Configure Signing & Certificates

### 3.1 Automatic Signing (Recommended)

1. In Xcode, select **Runner** target
2. Go to **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your **Team** (Apple Developer account)
5. Xcode will automatically:
   - Create provisioning profiles
   - Manage certificates
   - Configure signing

### 3.2 Manual Signing (If needed)

If automatic signing fails:
1. Download certificates from [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Install certificates in Keychain Access
3. Download provisioning profiles
4. Configure manually in Xcode

## Step 4: Prepare App Store Assets

### 4.1 App Icons

1. Create app icon set:
   - 1024x1024px PNG (required for App Store)
   - No transparency
   - No rounded corners (iOS adds them automatically)

2. Add to Xcode:
   - Open `flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset`
   - Add 1024x1024 icon

### 4.2 Screenshots

Prepare screenshots for different device sizes:
- **iPhone 6.7" Display** (iPhone 14 Pro Max): 1290x2796px
- **iPhone 6.5" Display** (iPhone 11 Pro Max): 1242x2688px
- **iPhone 5.5" Display** (iPhone 8 Plus): 1242x2208px
- **iPad Pro 12.9"**: 2048x2732px

Minimum required: 6.7" and 6.5" displays

### 4.3 App Preview Video (Optional)

- 15-30 seconds
- Show key features
- Same dimensions as screenshots

## Step 5: Build for Release

### 5.1 Clean Build

```bash
cd flutter
flutter clean
flutter pub get
```

### 5.2 Build iOS Release

```bash
# Build for release (creates .app bundle)
flutter build ios --release

# Or build IPA directly
flutter build ipa --release
```

The IPA file will be created at:
```
flutter/build/ios/ipa/CompostKaki.ipa
```

## Step 6: Archive and Upload via Xcode

### 6.1 Archive the App

1. Open `flutter/ios/Runner.xcworkspace` in Xcode
2. Select **Any iOS Device** (or **Generic iOS Device**) as target
3. Go to **Product** → **Archive**
4. Wait for archive to complete (may take several minutes)

### 6.2 Upload to App Store Connect

1. In the **Organizer** window (Xcode → Window → Organizer)
2. Select your archive
3. Click **Distribute App**
4. Choose **App Store Connect**
5. Click **Next**
6. Select **Upload**
7. Click **Next**
8. Review signing options (usually automatic is fine)
9. Click **Upload**
10. Wait for upload to complete

**Alternative: Use Transporter App**
- Download [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) from Mac App Store
- Drag and drop your `.ipa` file
- Click **Deliver**

## Step 7: Configure App Store Listing

In App Store Connect:

### 7.1 App Information

1. Go to your app → **App Information**
2. Fill in:
   - **Category**: Select appropriate categories
   - **Subtitle**: Short description (30 characters)
   - **Privacy Policy URL**: Required for most apps

### 7.2 Pricing and Availability

1. Set price (Free or Paid)
2. Select countries/regions
3. Set availability date

### 7.3 App Privacy

1. Go to **App Privacy**
2. Answer questions about data collection
3. Add privacy policy URL

### 7.4 Version Information

1. Go to **1.0 Prepare for Submission**
2. Fill in:
   - **What's New in This Version**: Release notes
   - **Description**: Full app description
   - **Keywords**: Search keywords (comma-separated, 100 characters max)
   - **Support URL**: Your support website
   - **Marketing URL** (optional): Your marketing website

3. Upload screenshots:
   - Drag screenshots to appropriate device sizes
   - Minimum 3 screenshots required

4. Upload app preview video (optional)

5. Set age rating:
   - Click **Age Rating**
   - Answer questionnaire
   - Save

6. Add app review information:
   - **Contact Information**: Your contact details
   - **Demo Account**: If app requires login
   - **Notes**: Any additional info for reviewers

## Step 8: Submit for Review

1. Review all information
2. Ensure status shows **Ready to Submit**
3. Click **Add for Review** → **Submit for Review**
4. Confirm submission

## Step 9: Monitor Review Status

Check status in App Store Connect:
- **Waiting for Review**: In queue
- **In Review**: Apple is reviewing
- **Pending Developer Release**: Approved, waiting for you to release
- **Ready for Sale**: Live on App Store
- **Rejected**: Review feedback provided

## Troubleshooting

### Common Issues

1. **"No valid 'aps-environment' entitlement"**
   - Enable Push Notifications capability in Xcode
   - Regenerate provisioning profile

2. **"Invalid Bundle"**
   - Check bundle identifier matches App Store Connect
   - Verify version number format

3. **"Missing Compliance"**
   - Answer Export Compliance questions in App Store Connect
   - If using encryption, may need to provide compliance info

4. **"Invalid Binary"**
   - Ensure minimum iOS version is set correctly (15.5+)
   - Check all required permissions are declared in Info.plist

5. **Build Errors**
   ```bash
   # Clean and rebuild
   flutter clean
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter build ios --release
   ```

### Upload Errors

- **"Unable to process application"**
  - Check app size (max 4GB)
  - Verify all required assets are included

- **"Invalid Signature"**
  - Re-archive with correct signing
  - Ensure certificates are valid

## Quick Reference Commands

```bash
# Build release IPA
flutter build ipa --release

# Build with specific version
flutter build ipa --release --build-number=2 --build-name=1.0.1

# Check app size
du -sh build/ios/ipa/*.ipa

# Validate IPA before upload
xcrun altool --validate-app \
  --file build/ios/ipa/CompostKaki.ipa \
  --type ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID

# Upload IPA (alternative to Xcode)
xcrun altool --upload-app \
  --file build/ios/ipa/CompostKaki.ipa \
  --type ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

## Post-Submission

1. **Monitor Reviews**: Check App Store Connect regularly
2. **Respond to Feedback**: Address any reviewer questions quickly
3. **Update App**: Use same process for updates
4. **TestFlight**: Consider using TestFlight for beta testing before release

## Additional Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)

---

**Note**: The review process typically takes 24-48 hours, but can take longer during busy periods or if issues are found.

