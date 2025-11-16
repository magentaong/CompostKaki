# Building on macOS

macOS is required for iOS builds. This guide covers building both Android and iOS on macOS.

## Prerequisites

1. **Xcode** (latest version from App Store)
   - Required for iOS builds
   - Includes iOS simulators

2. **Android Studio** (optional but recommended)
   - For Android development
   - Or use command line tools

3. **Java 17+**
   ```bash
   java -version
   ```

## Setup Steps

### 1. Enable iOS Targets

Edit `mobile/gradle.properties`:

```properties
# Change this to false to enable iOS builds
kotlin.mpp.skipIosTargets=false
```

### 2. Open Xcode and Accept License

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### 3. Build the Project

#### Build Everything (Android + iOS)

```bash
cd mobile
./gradlew build
```

#### Build Android Only

```bash
./gradlew :androidApp:assembleDebug
```

The APK will be at: `androidApp/build/outputs/apk/debug/androidApp-debug.apk`

#### Build iOS Framework

```bash
./gradlew :shared:linkDebugFrameworkIosArm64
# or for simulator:
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

The framework will be at: `shared/build/framework/`

## Running on iOS

### Option 1: Using Xcode

1. Open Xcode
2. Create a new iOS project or use the existing one in `iosApp/iosApp/`
3. Add the shared framework to your Xcode project:
   - Build the framework first: `./gradlew :shared:linkDebugFrameworkIosArm64`
   - In Xcode: File → Add Files to Project → Select the framework
4. Configure signing in Xcode (requires Apple Developer account for device, free for simulator)
5. Build and run from Xcode

### Option 2: Using Command Line (Simulator)

```bash
# Build the iOS app
./gradlew :iosApp:iosSimulatorArm64Binaries

# Run on simulator (requires simulator to be running)
xcrun simctl install booted iosApp/build/bin/iosSimulatorArm64/debugFramework/iosApp.app
xcrun simctl launch booted com.compostkaki.ios
```

## Troubleshooting

### "No such module 'ComposeApp'"

The shared framework needs to be built first:
```bash
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

### Signing Errors

- For simulator: No signing needed
- For device: Configure signing in Xcode with your Apple Developer account

### "Command not found: xcrun"

Make sure Xcode command line tools are installed:
```bash
xcode-select --install
```

### Build Fails with iOS Errors

1. Make sure `kotlin.mpp.skipIosTargets=false` in `gradle.properties`
2. Clean and rebuild:
   ```bash
   ./gradlew clean
   ./gradlew build
   ```

## Project Structure on macOS

```
mobile/
├── shared/              # Shared Kotlin code (works on both platforms)
├── androidApp/          # Android-specific code
└── iosApp/              # iOS-specific code (only builds on macOS)
```

## Quick Start

```bash
# 1. Enable iOS builds
echo "kotlin.mpp.skipIosTargets=false" >> gradle.properties

# 2. Build everything
./gradlew build

# 3. For Android: Install APK on device/emulator
./gradlew :androidApp:installDebug

# 4. For iOS: Open in Xcode and run
open iosApp/iosApp/iosApp.xcodeproj
```

## Notes

- iOS builds **only work on macOS** (Apple requirement)
- Android builds work on macOS, Windows, and Linux
- The shared code compiles to both platforms automatically
- Use Android Studio for Android development, Xcode for iOS development

