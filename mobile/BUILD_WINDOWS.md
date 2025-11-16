# Building on Windows

Due to limitations in Kotlin Multiplatform, iOS targets cannot be built on Windows. The Kotlin plugin tries to initialize iOS classes during plugin loading, which causes errors on Windows.

## Solution: Build Android Only

On Windows, you should build only the Android target:

```bash
cd mobile
.\gradlew.bat :androidApp:assembleDebug
```

Or to build just the shared module for Android:

```bash
.\gradlew.bat :shared:compileDebugKotlinAndroid
```

## For iOS Development

iOS builds **must** be done on macOS with Xcode installed. When you're on macOS:

1. Set `kotlin.mpp.skipIosTargets=false` in `gradle.properties`
2. Build normally: `./gradlew build`

## Current Workaround

The project is configured to skip iOS targets on Windows automatically, but the Kotlin plugin still tries to initialize iOS classes. This is a known limitation.

For now, on Windows, focus on Android development only.

