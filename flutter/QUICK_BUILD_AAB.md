# Quick Guide: Build AAB for Google Play

## For Google Play, you need an **Android App Bundle (AAB)**, not an APK!

## Option 1: Using Google Play App Signing (Recommended - Easiest)

If you use Google Play App Signing, you can upload an unsigned bundle and Google will sign it for you.

### Build unsigned AAB:

```bash
cd flutter
flutter build appbundle --release
```

The file will be at: `build/app/outputs/bundle/release/app-release.aab`

**Note:** You'll need to update the `applicationId` in `android/app/build.gradle.kts` from `com.example.compostkaki` to your actual package name first.

---

## Option 2: Sign it yourself (More secure)

### Step 1: Create keystore (one-time setup)

```bash
cd flutter/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Create key.properties

Create `flutter/android/key.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Build signed AAB

```bash
cd flutter
flutter build appbundle --release
```

---

## Important Notes:

1. **Application ID**: Update `com.example.compostkaki` to your actual package name in `android/app/build.gradle.kts`
2. **Version**: Make sure `version` in `pubspec.yaml` is correct (e.g., `1.0.0+1`)
3. **Keystore**: Keep your keystore file safe - you'll need it for all future updates!

---

## The AAB file location:

After building, your AAB will be at:
```
flutter/build/app/outputs/bundle/release/app-release.aab
```

Upload this file to Google Play Console!

