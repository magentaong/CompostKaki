# CompostKaki Mobile App

A Kotlin Multiplatform Mobile (KMM) application that runs on both Android and iOS.

## Features

- ✅ Authentication (Sign Up / Sign In)
- ✅ Bin Management (Create, Join, View)
- ✅ Activity Logging (Track compost activities)
- ✅ Task Management (Create, Accept, Complete tasks)
- ✅ QR Code Scanner (Join bins via QR)
- ✅ Tips & Guides

## Tech Stack

- **Kotlin Multiplatform Mobile (KMM)** - Shared business logic
- **Compose Multiplatform** - Shared UI for Android and iOS
- **Supabase** - Backend (Auth, Database, Storage)
- **Ktor** - HTTP client
- **Koin** - Dependency Injection

## Setup

### Prerequisites

- Android Studio Hedgehog (2023.1.1) or later
- Xcode 15+ (for iOS development)
- JDK 17+
- Kotlin 2.0.21+

### Configuration

1. **Set up Supabase credentials:**

   Edit `mobile/shared/src/commonMain/kotlin/com/compostkaki/shared/data/SupabaseClient.kt`:
   ```kotlin
   const val SUPABASE_URL = "YOUR_SUPABASE_URL"
   const val SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"
   ```

2. **Build the project:**

   ```bash
   cd mobile
   ./gradlew build
   ```

### Running on Android

1. Open the project in Android Studio
2. Select `androidApp` configuration
3. Run on an emulator or device

### Running on iOS

1. Open the project in Android Studio
2. Open Xcode and create a new iOS project (or use the existing one)
3. Build and run from Xcode

**Note:** For iOS, you'll need to:
- Set up the iOS project in Xcode
- Configure signing certificates
- Build the shared framework first

## Project Structure

```
mobile/
├── shared/              # Shared Kotlin code
│   ├── data/           # Data models and repositories
│   └── ui/             # Compose Multiplatform UI
├── androidApp/          # Android-specific code
└── iosApp/             # iOS-specific code
```

## Development Notes

- The app uses Compose Multiplatform for UI, which means most UI code is shared between platforms
- Platform-specific code (like camera access) should be implemented using `expect/actual` declarations
- Supabase client is configured in the shared module and works on both platforms

## Troubleshooting

### iOS Build Issues

- Make sure you have Xcode installed
- Run `./gradlew :shared:linkDebugFrameworkIosArm64` first to build the shared framework
- Check that your iOS deployment target is set correctly

### Android Build Issues

- Ensure you have Android SDK 35 installed
- Check that `compileSdk` and `targetSdk` match in `androidApp/build.gradle.kts`

## Next Steps

- [ ] Add QR code scanner library integration
- [ ] Implement image upload for logs
- [ ] Add push notifications
- [ ] Implement offline caching
- [ ] Add unit tests
- [ ] Add UI tests
