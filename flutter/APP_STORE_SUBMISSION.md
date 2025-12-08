# App Store Submission Guide for CompostKaki 📱

Complete guide to submit your Flutter app to the Apple App Store.

## Prerequisites Checklist

- ✅ Apple Developer Program membership (approved)
- ✅ App configured with bundle ID: `com.compostkaki`
- ✅ Development Team ID: `86R4H3R8L7`
- ✅ App version: `1.0.0+1`

## Step 1: Update App Display Name ✅ COMPLETED

✅ **Already done!** The app display name has been updated:
- `CFBundleDisplayName` = "CompostKaki" ✅
- `CFBundleName` = "CompostKaki" ✅

**File:** `ios/Runner/Info.plist` (already updated)

## Step 2: Create Bundle ID in Apple Developer Portal ⚠️ IMPORTANT

**Before creating the app in App Store Connect, you must create the Bundle ID first!**

If you see `com.example.compostkaki` in the dropdown instead of `com.compostkaki`, follow these steps:

1. **Go to Apple Developer Portal**
   - Visit: https://developer.apple.com/account/resources/identifiers/list
   - Sign in with your Apple Developer account

2. **Create New App ID**
   - Click **"+"** button (top left)
   - Select **"App IDs"** → **"Continue"**
   - Select **"App"** → **"Continue"**
   - **Description:** CompostKaki
   - **Bundle ID:** Select **"Explicit"**
   - **Bundle ID String:** Enter `com.compostkaki` (must match your Xcode project exactly)
   - **Capabilities:** Enable:
     - ✅ Camera (for mobile_scanner)
     - ✅ Photo Library (for image_picker)
     - ✅ Push Notifications (if you plan to use them)
   - Click **"Continue"** → **"Register"**

3. **Wait 2-5 minutes** for the Bundle ID to sync to App Store Connect

📖 **Detailed guide:** See `CREATE_BUNDLE_ID.md` for step-by-step instructions with screenshots.

## Step 3: Create App in App Store Connect

1. **Go to App Store Connect**
   - Visit: https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Create New App**
   - Click **"My Apps"** → **"+"** → **"New App"**
   - Fill in the details:
     - **Platform:** iOS
     - **Name:** CompostKaki
     - **Primary Language:** English (or your preferred language)
     - **Bundle ID:** Select `com.compostkaki` (should now appear in dropdown ✅)
     - **SKU:** `compostkaki-001` (unique identifier, can be anything)
     - **User Access:** Full Access (or Limited Access if you have a team)

3. **Click "Create"**

## Step 4: Configure App Information

### 4.1 App Information Tab

- **Name:** CompostKaki
- **Subtitle:** (Optional) A short tagline
- **Category:** 
  - Primary: Lifestyle or Utilities
  - Secondary: (Optional) Social Networking or Food & Drink
- **Privacy Policy URL:** (Required) Your privacy policy URL
  - Example: `https://compostkaki.vercel.app/privacy` or your website

### 4.2 Pricing and Availability

- **Price:** Free (or set your price)
- **Availability:** All countries (or select specific countries)

## Step 5: Prepare App Store Listing

### 5.1 App Store Screenshots (Required)

You'll need screenshots for:
- **iPhone 6.7" Display (iPhone 14 Pro Max):** 1290 x 2796 pixels
- **iPhone 6.5" Display (iPhone 11 Pro Max):** 1242 x 2688 pixels
- **iPhone 5.5" Display (iPhone 8 Plus):** 1242 x 2208 pixels

**Minimum:** At least 1 screenshot per device size
**Recommended:** 3-5 screenshots showing key features

**How to take screenshots:**
```bash
# Run app on simulator
flutter run

# Or use Xcode Simulator:
# 1. Open Simulator
# 2. Run your app
# 3. Cmd + S to take screenshot
# 4. Screenshots saved to Desktop
```

### 5.2 App Preview Video (Optional but Recommended)

- 15-30 second video showing app features
- Same sizes as screenshots
- Upload as MP4 or MOV

### 5.3 App Description

Write a compelling description (up to 4000 characters):

**Example:**
```
CompostKaki - Your Community Composting Companion 🌱

CompostKaki is a digital journaling platform that makes community composting easy, fun, and sustainable. Join or create compost bins, track your composting activities, and build a greener community together.

Features:
• Create and manage compost bins
• Track composting activities with photos
• Monitor bin health status
• Join bins via QR codes
• Community task management
• Real-time updates

Perfect for:
- Community gardens
- Neighborhood composting groups
- Eco-conscious individuals
- Sustainability enthusiasts

Start your composting journey today!
```

### 5.4 Keywords

- Maximum 100 characters
- Separate with commas
- Example: `composting,community,garden,sustainable,eco-friendly,recycling,organic`

### 5.5 Support URL

- Your support website or email
- Example: `https://compostkaki.vercel.app/support` or `mailto:support@compostkaki.com`

### 5.6 Marketing URL (Optional)

- Your marketing website
- Example: `https://compostkaki.vercel.app`

### 5.7 App Icon

- **Size:** 1024 x 1024 pixels
- **Format:** PNG (no transparency)
- **Location:** `flutter/assets/icons/app_icon.png`
- Make sure it's square and high quality

### 5.8 Privacy Policy (Required)

You must provide a privacy policy URL. Create one that covers:
- What data you collect
- How you use the data
- Third-party services (Supabase)
- User rights

## Step 6: Configure Xcode for Release

### 6.1 Open Project in Xcode

```bash
cd /Users/itzsihui/CompostKaki/flutter
open ios/Runner.xcworkspace
```

### 6.2 Configure Signing & Capabilities

1. **Select "Runner" project** in left sidebar
2. **Select "Runner" target** (under TARGETS)
3. **Go to "Signing & Capabilities" tab**
4. **Check "Automatically manage signing"**
5. **Select your Team:** Your Apple Developer account
6. **Verify Bundle Identifier:** `com.compostkaki`

### 6.3 Update Build Settings

1. **Select "Runner" project** → **"Build Settings"**
2. **Search for "Code Signing Identity"**
3. **Set to:** "Apple Distribution" for Release
4. **Set to:** "Apple Development" for Debug

### 6.4 Update Version Numbers

In `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- `1.0.0` = Version (what users see)
- `1` = Build number (increment for each submission)

## Step 7: Build for App Store

### Option A: Using Xcode (Recommended)

1. **Select "Any iOS Device"** or **"Generic iOS Device"** from device dropdown
2. **Product** → **Archive**
3. Wait for archive to complete (may take several minutes)
4. **Organizer window opens** → Select your archive
5. **Click "Distribute App"**
6. **Select "App Store Connect"**
7. **Click "Upload"**
8. **Select your distribution certificate** (should auto-select)
9. **Click "Upload"**
10. Wait for upload to complete

### Option B: Using Flutter Command Line

```bash
cd /Users/itzsihui/CompostKaki/flutter

# Clean build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Then open in Xcode and Archive
open ios/Runner.xcworkspace
```

Then follow steps 1-10 from Option A.

### Option C: Using fastlane (Advanced)

If you want to automate the process:

```bash
# Install fastlane
sudo gem install fastlane

# Navigate to iOS directory
cd ios

# Initialize fastlane
fastlane init

# Follow prompts, then use:
fastlane beta  # For TestFlight
fastlane release  # For App Store
```

## Step 8: Upload Build to App Store Connect

After archiving in Xcode:

1. **Xcode Organizer** opens automatically
2. **Select your archive** (latest one)
3. **Click "Distribute App"**
4. **Select "App Store Connect"** → **Next**
5. **Select "Upload"** → **Next**
6. **Distribution options:**
   - ✅ Upload your app's symbols (recommended)
   - ✅ Manage Version and Build Number (if needed)
7. **Select signing options:**
   - ✅ Automatically manage signing (recommended)
8. **Click "Upload"**
9. **Wait for processing** (can take 10-30 minutes)

## Step 9: Complete App Store Listing

1. **Go back to App Store Connect**
2. **Select your app** → **"App Store" tab**
3. **Fill in all required fields:**
   - Screenshots (required)
   - Description (required)
   - Keywords (required)
   - Support URL (required)
   - Privacy Policy URL (required)
   - App Icon (required)

## Step 10: Submit for Review

1. **In App Store Connect**, go to your app
2. **Select the build** you just uploaded (may take a few minutes to appear)
3. **Fill in "What's New in This Version"** (for first version, describe the app)
4. **Answer App Review questions:**
   - Does your app use encryption? (Usually "No" unless you handle sensitive data)
   - Does your app access user data? (Yes, if you use Supabase)
   - Export compliance (usually "No" for most apps)
5. **Click "Add for Review"**
6. **Click "Submit for Review"**

## Step 10: App Review Process

- **Typical review time:** 24-48 hours
- **Status updates:** You'll receive email notifications
- **Possible outcomes:**
  - ✅ **Approved:** App goes live
  - ⚠️ **Rejected:** Fix issues and resubmit
  - 📝 **In Review:** Waiting for review

## Troubleshooting Common Issues

### Issue: "No suitable application records were found"

**Solution:**
- Make sure you created the app in App Store Connect first
- Bundle ID must match exactly: `com.compostkaki`

### Issue: "Invalid Bundle"

**Solution:**
- Check that version number matches
- Clean build: `flutter clean && flutter pub get`
- Rebuild and re-archive

### Issue: "Missing Compliance"

**Solution:**
- Answer export compliance questions in App Store Connect
- Usually select "No" unless you use encryption

### Issue: "Missing Privacy Policy"

**Solution:**
- Add privacy policy URL in App Store Connect
- Must be accessible (not a placeholder)

### Issue: "Invalid Screenshots"

**Solution:**
- Use correct dimensions (see Step 4.1)
- Screenshots must be from actual app (not mockups)
- Remove any device frames/borders

## Post-Submission Checklist

- [ ] App created in App Store Connect
- [ ] Bundle ID matches (`com.compostkaki`)
- [ ] App icon uploaded (1024x1024)
- [ ] Screenshots uploaded for required device sizes
- [ ] Description written
- [ ] Keywords added
- [ ] Privacy policy URL added
- [ ] Support URL added
- [ ] Build uploaded successfully
- [ ] Build selected in App Store Connect
- [ ] All required fields completed
- [ ] Submitted for review

## Version Updates

For future updates:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.0.1+2  # Increment both numbers
   ```

2. **Build and upload** (same process as above)

3. **Update "What's New"** in App Store Connect

4. **Submit for review**

## Useful Commands

```bash
# Check app version
cd flutter
cat pubspec.yaml | grep version

# Build for release
flutter build ios --release

# Clean and rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release

# Check Flutter doctor
flutter doctor -v
```

## Resources

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## Support

If you encounter issues:
1. Check [Apple Developer Forums](https://developer.apple.com/forums/)
2. Review [Flutter iOS Deployment Docs](https://docs.flutter.dev/deployment/ios)
3. Check Xcode console for specific errors

---

Good luck with your App Store submission! 🚀

