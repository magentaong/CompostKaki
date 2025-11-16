# CompostKaki Mobile App - Setup Guide

## Overview

This is a Kotlin Multiplatform Mobile (KMM) application built with Compose Multiplatform. It shares code between Android and iOS while maintaining native performance.

## Project Structure

```
mobile/
├── shared/                    # Shared Kotlin code
│   ├── data/
│   │   ├── models/          # Data models (Bin, Task, Log, User, etc.)
│   │   ├── repository/      # Repository classes for API calls
│   │   └── SupabaseClient.kt
│   └── ui/
│       ├── screens/         # Compose UI screens
│       ├── navigation/      # Navigation setup
│       └── theme/          # App theme
├── androidApp/              # Android-specific code
└── iosApp/                  # iOS-specific code
```

## Prerequisites

1. **Android Studio Hedgehog (2023.1.1) or later**
   - Install Kotlin Multiplatform Mobile plugin
   - Install Android SDK 35

2. **Xcode 15+** (for iOS development)
   - macOS required

3. **JDK 17+**

4. **Supabase Account**
   - Get your Supabase URL and anon key

## Setup Steps

### 1. Configure Supabase

Edit `mobile/shared/src/commonMain/kotlin/com/compostkaki/shared/data/SupabaseClient.kt`:

```kotlin
const val SUPABASE_URL = "https://your-project.supabase.co"
const val SUPABASE_ANON_KEY = "your-anon-key"
```

### 2. Build the Project

```bash
cd mobile
./gradlew build
```

### 3. Run on Android

1. Open the project in Android Studio
2. Select `androidApp` run configuration
3. Click Run

### 4. Run on iOS

**Note:** iOS setup requires additional configuration:

1. Open Xcode
2. Create a new iOS project or use the existing one in `iosApp/iosApp/`
3. Link the shared framework:
   - Build the shared framework first: `./gradlew :shared:linkDebugFrameworkIosArm64`
   - Add the framework to your Xcode project
4. Configure signing certificates in Xcode
5. Build and run from Xcode

## Important Notes

### Navigation Library

The current navigation setup uses `androidx.navigation.compose`, which works on Android but may need adjustment for iOS. For full multiplatform support, consider:

- **Voyager** - Popular multiplatform navigation library
- **Decompose** - Another multiplatform navigation solution

To use Voyager instead:

1. Add to `libs.versions.toml`:
```toml
voyager = "1.1.0"
```

2. Update dependencies in `shared/build.gradle.kts`:
```kotlin
implementation("cafe.adriel.voyager:voyager-navigator:$voyager")
```

### Supabase Library

The app uses `io.github.jan-tennert.supabase` which is a Kotlin Multiplatform library. Make sure you're using version 3.0.0 or later.

### Missing Dependencies

Some features may need additional setup:

1. **QR Code Scanner**: Add a multiplatform QR scanner library
2. **Image Picker**: Implement platform-specific image pickers using `expect/actual`
3. **Camera Access**: Use platform-specific implementations

## Troubleshooting

### Build Errors

- **"Unresolved reference"**: Sync Gradle files (File → Sync Project with Gradle Files)
- **iOS build fails**: Make sure you've built the shared framework first
- **Supabase errors**: Verify your URL and anon key are correct

### iOS Specific Issues

- **Framework not found**: Build the shared framework for the correct architecture
- **Signing errors**: Configure your Apple Developer account in Xcode
- **Swift/Objective-C bridging**: The Swift file in `iosApp/iosApp/AppDelegate.swift` bridges Kotlin to SwiftUI

## Next Steps

1. ✅ Configure Supabase credentials
2. ⏳ Test authentication flow
3. ⏳ Implement QR code scanner
4. ⏳ Add image upload functionality
5. ⏳ Test on both platforms
6. ⏳ Add error handling and loading states
7. ⏳ Implement offline caching (optional)

## Development Tips

- Most UI code is in the `shared` module and works on both platforms
- Platform-specific code should use `expect/actual` declarations
- Test on both platforms regularly to catch platform-specific issues
- Use `println()` or `Napier` for logging (works on both platforms)

## Resources

- [Kotlin Multiplatform Mobile Docs](https://kotlinlang.org/docs/multiplatform-mobile-getting-started.html)
- [Compose Multiplatform Docs](https://www.jetbrains.com/lp/compose-multiplatform/)
- [Supabase Kotlin Docs](https://github.com/supabase/supabase-kt)

