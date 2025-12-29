# APNs (Apple Push Notification Service) Setup Guide

## Step 1: Create APNs Authentication Key (Recommended)

### 1.1 Generate APNs Key in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** in the left sidebar
4. Click the **+** button to create a new key
5. Enter a name: `CompostKaki APNs Key`
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** → **Register**
8. **Download the key file** (`.p8` file) - **You can only download this once!**
9. **Note the Key ID** (shown on the page)

### 1.2 Upload to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **compostkaki-eaf61**
3. Go to **Project Settings** (gear icon) → **Cloud Messaging** tab
4. Scroll to **Apple app configuration**
5. Under **APNs Authentication Key**:
   - Click **Upload**
   - Select your `.p8` key file
   - Enter the **Key ID** (from step 1.1)
   - Enter your **Team ID** (found in Apple Developer Portal → Membership)
6. Click **Upload**

## Step 2: Enable Push Notifications Capability in Xcode

1. Open Xcode:
   ```bash
   open /Users/itzsihui/CompostKaki/flutter/ios/Runner.xcworkspace
   ```

2. Select **Runner** target in the left sidebar

3. Go to **Signing & Capabilities** tab

4. Click **+ Capability**

5. Add **Push Notifications**:
   - Search for "Push Notifications"
   - Double-click to add

6. Add **Background Modes**:
   - Click **+ Capability** again
   - Search for "Background Modes"
   - Double-click to add
   - Check **Remote notifications**

## Step 3: Verify Bundle ID Matches

1. In Xcode → **Signing & Capabilities**
2. Verify **Bundle Identifier** matches Firebase:
   - Should be: `com.compostkaki`
   - If different, update in Firebase Console → Project Settings → iOS app

## Step 4: Test APNs Connection

After uploading the key, Firebase will automatically test the connection. You should see:
- ✅ **Status: Active** (if successful)
- ❌ **Status: Error** (if there's an issue)

## Troubleshooting

### Key Upload Fails
- Ensure `.p8` file is valid
- Check Key ID matches
- Verify Team ID is correct
- Ensure key has APNs permission enabled

### Push Notifications Not Working
- Verify capability is added in Xcode
- Check bundle ID matches
- Ensure app is signed with correct provisioning profile
- Test on physical device (simulator doesn't support push)

## Next Steps

Once APNs is configured:
1. ✅ Firebase can send push notifications to iOS devices
2. ✅ Test push notifications from Firebase Console
3. ✅ Deploy Supabase Edge Function to send notifications

