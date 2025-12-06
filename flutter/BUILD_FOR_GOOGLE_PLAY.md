# Building Android App Bundle (AAB) for Google Play

## Step 1: Set Up App Signing

You need to create a keystore for signing your app. Google Play requires signed apps.

### Create a Keystore:

```bash
cd flutter/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** 
- Remember the password you set - you'll need it!
- Store the keystore file safely - you CANNOT recover it if lost
- The alias name is `upload` (you'll need this too)

### Create key.properties file:

Create `flutter/android/key.properties` with:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with your actual passwords.**

## Step 2: Update build.gradle.kts

The build.gradle.kts file needs to be updated to use your keystore. I'll update it for you.

## Step 3: Update Application ID

Change `com.example.compostkaki` to your actual package name (e.g., `com.compostkaki.app` or `com.yourcompany.compostkaki`).

## Step 4: Build the App Bundle

Once signing is set up, run:

```bash
cd flutter
flutter build appbundle --release
```

This will create: `flutter/build/app/outputs/bundle/release/app-release.aab`

## Step 5: Upload to Google Play

1. Go to Google Play Console
2. Create a new app (if first time)
3. Go to "Production" → "Create new release"
4. Upload the `app-release.aab` file
5. Fill in release notes
6. Submit for review

---

## Quick Commands:

```bash
# Build AAB
flutter build appbundle --release

# The AAB file will be at:
# flutter/build/app/outputs/bundle/release/app-release.aab
```

