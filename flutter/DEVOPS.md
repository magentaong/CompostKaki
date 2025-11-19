# DevOps Guide for CompostKaki Flutter App

## CI/CD Pipeline Overview

Our CI/CD pipeline ensures code quality, automates testing, and streamlines app deployment.

## Pipeline Architecture

```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│     GitHub Actions Workflow         │
├─────────────────────────────────────┤
│  1. Code Quality Checks             │
│     - Flutter Format                │
│     - Flutter Analyze               │
│     - Linter Rules                  │
├─────────────────────────────────────┤
│  2. Automated Testing               │
│     - Unit Tests                    │
│     - Widget Tests                  │
│     - Integration Tests             │
│     - Coverage Report               │
├─────────────────────────────────────┤
│  3. Build Artifacts                 │
│     - Android APK (Debug/Release)   │
│     - iOS IPA (Release)             │
│     - App Bundles (AAB)             │
├─────────────────────────────────────┤
│  4. Deployment                      │
│     - Firebase App Distribution     │
│     - Google Play (Internal)        │
│     - TestFlight                    │
└─────────────────────────────────────┘
```

## Setup Instructions

### 1. GitHub Repository Setup

#### Required Secrets
Add these to **Settings → Secrets and variables → Actions**:

```yaml
# Supabase
SUPABASE_URL: your-project-url.supabase.co
SUPABASE_ANON_KEY: your-anon-key

# Android Signing (for release builds)
ANDROID_KEYSTORE_BASE64: base64-encoded-keystore
ANDROID_KEY_ALIAS: your-key-alias
ANDROID_KEY_PASSWORD: your-key-password
ANDROID_STORE_PASSWORD: your-store-password

# iOS Signing (optional, for App Store)
IOS_CERTIFICATE_BASE64: base64-encoded-p12-certificate
IOS_PROVISIONING_PROFILE: base64-encoded-mobileprovision
IOS_CERTIFICATE_PASSWORD: certificate-password

# Firebase (for distribution)
FIREBASE_TOKEN: firebase-ci-token
```

#### Branch Protection Rules
1. Go to **Settings → Branches**
2. Add rule for `main` branch:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date
   - ✅ Include administrators

### 2. Local Development Workflow

```bash
# Before committing
flutter format lib/ test/
flutter analyze
flutter test

# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/your-feature
```

### 3. Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new feature
fix: resolve bug in health calculation
docs: update README
test: add unit tests for BinService
refactor: improve code structure
chore: update dependencies
ci: modify GitHub Actions workflow
```

## Deployment Strategies

### Strategy 1: Firebase App Distribution (Recommended for Beta)

**Setup:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init

# Deploy
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups testers
```

**Benefits:**
- ✅ Easy sharing with testers
- ✅ Automatic notifications
- ✅ Supports both Android & iOS
- ✅ No app store approval needed

### Strategy 2: Google Play Internal Testing

**Steps:**
1. Build App Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```

2. Upload to Google Play Console
3. Create internal testing track
4. Add testers via email

**Benefits:**
- ✅ Pre-production environment
- ✅ Gradual rollout
- ✅ Crash reporting
- ✅ In-app updates

### Strategy 3: TestFlight (iOS)

**Steps:**
1. Build iOS app:
   ```bash
   flutter build ios --release
   ```

2. Archive in Xcode
3. Upload to App Store Connect
4. Add beta testers

**Benefits:**
- ✅ Official Apple testing platform
- ✅ Up to 10,000 testers
- ✅ Automatic provisioning
- ✅ TestFlight app for testers

## Monitoring & Analytics

### 1. Crash Reporting
**Firebase Crashlytics** - Track app crashes

Setup:
```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

```dart
// main.dart
void main() async {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(MyApp());
}
```

### 2. Analytics
**Firebase Analytics** - Track user behavior

```yaml
dependencies:
  firebase_analytics: ^10.8.0
```

### 3. Performance Monitoring
**Firebase Performance** - Monitor app performance

```yaml
dependencies:
  firebase_performance: ^0.9.3
```

## Environment Management

### Development
```bash
flutter run --dart-define=ENV=dev
```

### Staging
```bash
flutter run --dart-define=ENV=staging
```

### Production
```bash
flutter build apk --release --dart-define=ENV=prod
```

## Release Checklist

### Pre-Release
- [ ] All tests passing
- [ ] Code coverage > 80%
- [ ] No linter warnings
- [ ] Version number updated in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Screenshots updated
- [ ] Privacy policy reviewed

### Android Release
- [ ] Build signed APK/AAB
- [ ] Test on multiple devices
- [ ] Review app permissions
- [ ] Update store listing
- [ ] Create release notes

### iOS Release
- [ ] Build archive in Xcode
- [ ] Test on physical device
- [ ] Submit for App Store review
- [ ] Update screenshots & description

## Rollback Strategy

### If critical bug found:
1. **Immediate**: Remove from store or stop rollout
2. **Fix**: Create hotfix branch from `main`
3. **Test**: Run full test suite
4. **Deploy**: Emergency release with version bump
5. **Monitor**: Track crash reports closely

### Version Rollback
```bash
# Revert to previous version
git revert <commit-hash>

# Rebuild and deploy
flutter build apk --release
```

## Performance Optimization

### Build Size Optimization
```bash
# Analyze app size
flutter build apk --analyze-size

# Enable code shrinking
flutter build apk --release --shrink
```

### Build Time Optimization
```yaml
# Use build cache
flutter build apk --build-cache

# Parallel builds
flutter build apk --parallel
```

## Security Best Practices

1. **Never commit secrets** - Use environment variables
2. **Code obfuscation** - Enabled in release builds
3. **API key rotation** - Regular updates
4. **Certificate pinning** - For sensitive APIs
5. **ProGuard rules** - Configured for Android

## Maintenance Schedule

### Weekly
- Review crash reports
- Monitor app performance metrics
- Check dependency updates

### Monthly
- Security audit
- Performance review
- User feedback analysis

### Quarterly
- Major version planning
- Technical debt cleanup
- Architecture review

## Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# Clean build cache
flutter clean

# Update dependencies
flutter pub upgrade

# Generate code coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Build for all platforms
flutter build apk --release --split-per-abi
flutter build appbundle --release
flutter build ios --release

# Run on specific device
flutter devices
flutter run -d <device-id>

# Profile app performance
flutter run --profile
```

## Troubleshooting

### Build Fails in CI
1. Check GitHub Actions logs
2. Verify secrets are set correctly
3. Ensure dependencies are compatible
4. Check Flutter version matches local

### Tests Fail in CI but pass locally
1. Check for timezone differences
2. Verify environment variables
3. Look for race conditions
4. Check file path differences (Windows vs Linux)

### APK size too large
1. Use `--split-per-abi` flag
2. Enable ProGuard/R8
3. Remove unused resources
4. Optimize images

## Contact & Support

- **CI/CD Issues**: Check GitHub Actions logs
- **Deployment**: Refer to platform documentation
- **Security**: Follow OWASP Mobile Top 10

## Future Enhancements

- [ ] Automated release notes generation
- [ ] A/B testing infrastructure
- [ ] Feature flags system
- [ ] Automated screenshot generation
- [ ] Load testing automation
- [ ] Multi-language support pipeline

