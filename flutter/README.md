# CompostKaki Flutter Mobile App 🌱

[![Flutter CI/CD](https://github.com/YOUR_USERNAME/compostkaki/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/compostkaki/actions/workflows/flutter-ci.yml)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/compostkaki/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/compostkaki)

A mobile app for managing community composting bins, tracking activities, and building sustainable communities.

## 📱 Features

- **Bin Management**: Create, join, and manage compost bins
- **Activity Logging**: Track composting activities with photos
- **Health Monitoring**: Automatic health status calculation (Healthy, Needs Attention, Critical)
- **QR Code Sharing**: Share and join bins via QR codes
- **Deep Linking**: Join bins via shareable links
- **Community Tasks**: Post and complete composting tasks
- **Profile Management**: Edit user profiles and preferences
- **Real-time Updates**: Instant refresh across all screens

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: `3.24.0` or higher
- Dart SDK: `3.5.0` or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android builds)
- Xcode (for iOS builds on macOS)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/compostkaki.git
   cd compostkaki/flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   
   Create a `.env` file or update `lib/main.dart` with your Supabase credentials:
   ```dart
   const supabaseUrl = 'YOUR_SUPABASE_URL';
   const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Run the app**
   ```bash
   # On connected device/emulator
   flutter run
   
   # On specific device
   flutter run -d <device-id>
   ```

### Running on Physical Device

#### Android
1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify
5. Run `flutter run`

#### iOS (macOS only)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your development team
3. Connect your iPhone
4. Run from Xcode or `flutter run`

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Integration Tests
```bash
flutter test integration_test/app_test.dart
```

### Quick Test Script
```bash
./scripts/test.sh
```

## 🏗️ Building

### Android APK (Debug)
```bash
flutter build apk --debug
```

### Android APK (Release)
```bash
flutter build apk --release --split-per-abi
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS (macOS only)
```bash
flutter build ios --release
```

### Build Script
```bash
# Debug APK
./scripts/build.sh debug android

# Release APK
./scripts/build.sh release android

# App Bundle
./scripts/build.sh appbundle android
```

## 📁 Project Structure

```
flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── router/
│   │   └── app_router.dart       # Navigation routes
│   ├── screens/
│   │   ├── auth/                 # Login, Signup screens
│   │   ├── bin/                  # Bin-related screens
│   │   ├── main/                 # Main home screen
│   │   ├── profile/              # Profile screens
│   │   └── tasks/                # Community tasks
│   ├── services/
│   │   ├── auth_service.dart     # Authentication
│   │   ├── bin_service.dart      # Bin operations
│   │   ├── task_service.dart     # Task operations
│   │   └── supabase_service.dart # Supabase client
│   ├── widgets/
│   │   ├── bin_card.dart         # Bin list item
│   │   ├── task_card.dart        # Task list item
│   │   └── activity_timeline_item.dart
│   └── theme/
│       └── app_theme.dart        # App styling
├── test/                         # Unit & widget tests
├── integration_test/             # E2E tests
├── android/                      # Android config
├── ios/                          # iOS config
└── scripts/                      # Build & test scripts
```

## 🔧 Configuration

### Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Set up the following tables:
   - `profiles`: User profiles
   - `bins`: Compost bins
   - `bin_members`: Bin membership
   - `bin_logs`: Activity logs
   - `tasks`: Community tasks

3. Create storage buckets:
   - `bin-images`: For bin photos
   - `bin-logs`: For activity photos

4. Enable Row Level Security (RLS) on all tables

### Deep Linking Setup

#### Android
Deep link scheme: `compostkaki://bin/{binId}`

Already configured in `android/app/src/main/AndroidManifest.xml`

#### iOS
1. Open `ios/Runner.xcworkspace` in Xcode
2. Add URL scheme in Info.plist
3. Set scheme to `compostkaki`

## 🚢 Deployment

### Firebase App Distribution (Recommended)

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Distribute APK**
   ```bash
   firebase appdistribution:distribute \
     build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --groups testers
   ```

3. **Automatic Distribution**
   - Push to `develop` branch
   - GitHub Actions will auto-distribute to testers

### Google Play Store

1. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Upload to Google Play Console
3. Complete store listing
4. Submit for review

### Apple App Store

1. Build iOS app in Xcode
2. Archive and upload to App Store Connect
3. Complete metadata
4. Submit for review

## 🔄 CI/CD Pipeline

Our GitHub Actions workflow automatically:

1. ✅ Runs code formatting checks
2. ✅ Performs static analysis
3. ✅ Executes all unit tests
4. ✅ Generates coverage reports
5. ✅ Builds APK/IPA artifacts
6. ✅ Distributes to testers (on `develop` branch)

See [DEVOPS.md](./DEVOPS.md) for detailed pipeline documentation.

## 📊 Code Quality

- **Linting**: `flutter analyze`
- **Formatting**: `flutter format lib/ test/`
- **Coverage**: Target 80%+ code coverage
- **Static Analysis**: Configured via `analysis_options.yaml`

## 🤝 Contributing

### Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes
3. Run tests: `./scripts/test.sh`
4. Commit: `git commit -m "feat: add feature"`
5. Push: `git push origin feature/your-feature`
6. Create Pull Request

### Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `test:` - Tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance

## 📖 Documentation

- [Testing Guide](./TESTING.md) - Comprehensive testing documentation
- [DevOps Guide](./DEVOPS.md) - CI/CD and deployment guide
- [Flutter Docs](https://docs.flutter.dev/) - Official Flutter documentation
- [Supabase Docs](https://supabase.com/docs) - Supabase documentation

## 🐛 Troubleshooting

### Common Issues

**Issue**: Flutter not recognized
```bash
# Add to PATH (Windows)
set PATH=%PATH%;C:\flutter\bin

# Verify
flutter doctor
```

**Issue**: Build fails with "Namespace not specified"
```bash
flutter clean
flutter pub get
```

**Issue**: Emulator not detected
```bash
# Restart ADB
adb kill-server
adb start-server

# List devices
flutter devices
```

**Issue**: Supabase connection fails
- Verify `supabaseUrl` and `supabaseAnonKey` in `main.dart`
- Check internet connection
- Verify Supabase project is active

## 🔐 Security

- Never commit Supabase keys to Git
- Use environment variables for secrets
- Enable Row Level Security on all tables
- Implement proper authentication checks

## 📱 Supported Platforms

- ✅ Android 6.0+ (API 23+)
- ✅ iOS 12.0+

## 🎨 Design System

- **Primary Color**: `#4CAF50` (Green)
- **Accent Color**: `#8BC34A` (Light Green)
- **Typography**: Default Flutter fonts
- **Icons**: Material Icons

## 📜 License

[Add your license here]

## 👥 Team

[Add team members here]

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Contact: your-email@example.com

## 🗺️ Roadmap

- [ ] iOS app release
- [ ] Push notifications
- [ ] Offline mode
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Leaderboard implementation
- [ ] Social sharing features

---

Made with 💚 by the CompostKaki team
