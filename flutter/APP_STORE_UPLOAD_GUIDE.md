# Step-by-Step Guide: Uploading to App Store Connect

## Prerequisites Checklist

Before starting, make sure you have:
- [ ] Apple Developer Account (paid membership)
- [ ] Xcode installed (latest version recommended)
- [ ] App Store Connect access
- [ ] Bundle ID created in Apple Developer Portal (`com.compostkaki`)
- [ ] App created in App Store Connect (if first upload)

## Step 1: Update Version Number

### Current Version: `1.0.0+3`

**For a new release, update the version:**

1. Open `flutter/pubspec.yaml`
2. Update the version:
   ```yaml
   version: 1.0.1+4  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
   ```
   - **Version** (1.0.1): User-facing version (shown in App Store)
   - **Build Number** (+4): Internal build number (must increment for each upload)

**Important:** Build number must be higher than the previous upload!

## Step 2: Clean and Prepare Build

```bash
cd /Users/itzsihui/CompostKaki/flutter

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Verify iOS setup
flutter doctor -v
```

## Step 3: Build iOS Release

```bash
# Build iOS release (creates .app file)
flutter build ios --release

# This creates: build/ios/iphoneos/Runner.app
```

**Note:** This step prepares the app but doesn't create an archive yet. The archive is created in Xcode.

## Step 4: Open in Xcode

```bash
# Open the workspace (NOT the .xcodeproj file)
open ios/Runner.xcworkspace
```

**Important:** Always open `.xcworkspace`, not `.xcodeproj` (because of CocoaPods)

## Step 5: Configure Signing & Capabilities in Xcode

1. **Select the Runner project** in the left sidebar
2. **Select the Runner target** (under TARGETS)
3. Go to **"Signing & Capabilities"** tab
4. **Team:** Select your Apple Developer team
5. **Bundle Identifier:** Should be `com.compostkaki`
6. **Automatically manage signing:** ✅ Checked
7. **Provisioning Profile:** Should auto-generate

### Verify Capabilities:
- ✅ Push Notifications (if needed)
- ✅ Camera (required for QR scanner)
- ✅ Photo Library (required for image picker)

## Step 6: Set Build Configuration

1. In Xcode, click on **"Runner"** scheme (top left, next to the play button)
2. Select **"Edit Scheme..."**
3. Under **"Run"** → **"Info"** → **Build Configuration:** Select **"Release"**
4. Click **"Close"**

## Step 7: Select Generic iOS Device

1. In Xcode, look at the device selector (top center)
2. Click the dropdown
3. Select **"Any iOS Device (arm64)"** or **"Generic iOS Device"**

**Important:** You cannot archive if a simulator is selected!

## Step 8: Archive the App

1. In Xcode menu: **Product** → **Archive**
2. Wait for the build to complete (this may take 5-10 minutes)
3. The **Organizer** window will open automatically when done

## Step 9: Validate the Archive

**Before uploading, validate to catch errors early:**

1. In the **Organizer** window, select your archive
2. Click **"Validate App"**
3. Select your **Apple ID** and **Team**
4. Click **"Next"**
5. Xcode will check:
   - Code signing
   - App Store requirements
   - Missing capabilities
6. If validation passes, you'll see ✅ **"Validation Successful"**
7. If there are errors, fix them and re-archive

## Step 10: Distribute to App Store Connect

1. In the **Organizer** window, with your archive selected
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Next"**
5. Select **"Upload"** (not "Export")
6. Click **"Next"**
7. Select your **Distribution Certificate** and **Provisioning Profile** (usually auto-selected)
8. Click **"Next"**
9. Review the summary
10. Click **"Upload"**
11. Wait for upload to complete (progress bar will show)

**Upload time:** Usually 5-15 minutes depending on app size and internet speed.

## Step 11: Verify Upload in App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Sign in with your Apple ID
3. Click **"My Apps"**
4. Select **"CompostKaki"** (or create it if first time)
5. Click on your app
6. Go to **"TestFlight"** tab (for beta testing) or **"App Store"** tab (for production)

### Check Build Status:
- **Processing:** Apple is processing your build (usually 10-30 minutes)
- **Ready to Submit:** Build is ready for submission
- **Invalid Binary:** There's an issue (check email for details)

## Step 12: Submit for Review (Production Release)

### If this is a new version:

1. In App Store Connect, go to **"App Store"** tab
2. Click **"+ Version"** or **"+ Platform"** → **"iOS"**
3. Enter **Version Number:** `1.0.1` (must match pubspec.yaml)
4. Fill in **"What's New in This Version"** (release notes)
5. Scroll down and click **"Build"** section
6. Select your uploaded build (it should appear after processing)
7. Fill in required information:
   - Screenshots (required for each device size)
   - Description
   - Keywords
   - Support URL
   - Marketing URL (optional)
   - Privacy Policy URL (required)
8. Answer **App Review Information:**
   - Contact information
   - Demo account (if needed)
   - Notes (optional)
9. Click **"Add for Review"**
10. Click **"Submit for Review"** (top right)

### If updating existing version:

1. Go to the version you want to update
2. Click **"Edit"**
3. Select the new build
4. Update release notes
5. Click **"Submit for Review"**

## Step 13: Monitor Review Status

After submission, you can track status in App Store Connect:

- **Waiting for Review:** Your app is in queue
- **In Review:** Apple is reviewing your app (usually 24-48 hours)
- **Pending Developer Release:** Approved, waiting for you to release
- **Ready for Sale:** App is live in App Store
- **Rejected:** Review found issues (check Resolution Center)

## Troubleshooting Common Issues

### Issue: "No accounts with App Store Connect access"

**Solution:**
1. Xcode → Preferences → Accounts
2. Add your Apple ID
3. Select your team

### Issue: "Bundle identifier is already in use"

**Solution:**
- Make sure Bundle ID `com.compostkaki` exists in Apple Developer Portal
- See `CREATE_BUNDLE_ID.md` for instructions

### Issue: "Invalid Bundle"

**Solution:**
- Check email from Apple for specific errors
- Common issues:
  - Missing privacy descriptions in Info.plist
  - Missing app icons
  - Code signing issues

### Issue: "Archive option is grayed out"

**Solution:**
- Make sure "Generic iOS Device" is selected (not simulator)
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

### Issue: "Upload failed: Invalid code signature"

**Solution:**
1. Xcode → Preferences → Accounts
2. Select your Apple ID → Download Manual Profiles
3. In Signing & Capabilities, uncheck "Automatically manage signing"
4. Re-check "Automatically manage signing"
5. Re-archive

## Quick Command Reference

```bash
# Navigate to project
cd /Users/itzsihui/CompostKaki/flutter

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# Check Flutter setup
flutter doctor -v
```

## Version Numbering Best Practices

- **Major (1.0.0):** Breaking changes, major features
- **Minor (0.1.0):** New features, backward compatible
- **Patch (0.0.1):** Bug fixes, small improvements
- **Build (+3):** Internal build number, always increment

**Example progression:**
- First release: `1.0.0+1`
- Bug fix: `1.0.1+2`
- New feature: `1.1.0+3`
- Major update: `2.0.0+4`

## Pre-Upload Checklist

Before uploading, verify:

- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] All tests passing (`flutter test`)
- [ ] App runs correctly on physical device
- [ ] No console errors or warnings
- [ ] App icons are set (all sizes)
- [ ] Privacy descriptions added (Camera, Photo Library)
- [ ] Bundle ID matches Apple Developer Portal
- [ ] Signing certificates are valid
- [ ] Release notes prepared

## Post-Upload Checklist

After upload:

- [ ] Build appears in App Store Connect
- [ ] Build status changes to "Ready to Submit"
- [ ] Version information filled in
- [ ] Screenshots uploaded
- [ ] Release notes added
- [ ] Submitted for review
- [ ] Email notifications enabled for review status

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

**Need Help?** Check the troubleshooting section or refer to Apple's documentation.

