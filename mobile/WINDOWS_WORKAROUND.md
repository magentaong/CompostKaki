# Windows Build Workaround

## The Problem

Kotlin Multiplatform has a known issue on Windows where the plugin initializes iOS classes during plugin loading, causing `ExceptionInInitializerError` even when building Android-only.

## Solution: Use Android Studio

**The easiest solution is to use Android Studio**, which handles this better:

1. Open Android Studio
2. Open the `mobile` folder as a project
3. Android Studio will handle the multiplatform setup correctly
4. Build and run the Android app from Android Studio

## Alternative: Manual Workaround

If you must use command line on Windows:

1. Temporarily rename `shared/build.gradle.kts` to `shared/build.gradle.kts.backup`
2. Copy `shared/build-android-only.gradle.kts` to `shared/build.gradle.kts`
3. Build: `.\gradlew.bat :androidApp:assembleDebug`
4. Restore the original file when done

## Long-term Solution

- **For iOS development**: Use macOS (required anyway)
- **For Android development on Windows**: Use Android Studio
- **For CI/CD**: Use separate build scripts for Windows (Android) and macOS (iOS)

## Why This Happens

The Kotlin Multiplatform plugin loads iOS-related classes (`KonanTarget`) when the plugin JAR is loaded, which happens before any Gradle properties or init scripts can prevent it. This is a limitation of the plugin architecture, not our code.

