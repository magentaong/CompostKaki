# Installing Flutter on Windows

## Quick Installation Steps

### Option 1: Using Git (Recommended)

1. **Install Git** (if not already installed):
   - Download from: https://git-scm.com/download/win
   - Or use: `winget install Git.Git`

2. **Clone Flutter**:
   ```bash
   cd C:\
   git clone https://github.com/flutter/flutter.git -b stable
   ```

3. **Add Flutter to PATH**:
   - Press `Win + X` and select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\flutter\bin`
   - Click "OK" on all dialogs
   - **Restart your terminal/command prompt**

4. **Verify Installation**:
   ```bash
   flutter doctor
   ```

### Option 2: Download ZIP (Alternative)

1. **Download Flutter SDK**:
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable release ZIP file
   - Extract to `C:\flutter` (or your preferred location)

2. **Add Flutter to PATH** (same as Option 1, step 3)

3. **Verify Installation**:
   ```bash
   flutter doctor
   ```

## Additional Requirements

After installing Flutter, you'll need:

1. **Android Studio** (for Android development):
   - Download from: https://developer.android.com/studio
   - Install Android SDK and Android SDK Platform-Tools
   - Flutter doctor will guide you through this

2. **VS Code** (optional but recommended):
   - Download from: https://code.visualstudio.com/
   - Install the Flutter extension

## Verify Installation

Run these commands in a new terminal:

```bash
flutter --version
flutter doctor
```

The `flutter doctor` command will tell you what else needs to be installed.

## After Installation

Once Flutter is installed, navigate to your project and run:

```bash
cd C:\Users\sumit\OneDrive\Desktop\Composters\flutter
flutter pub get
flutter run
```

## Troubleshooting

### If `flutter` command still not found:
- Make sure you restarted your terminal/command prompt after adding to PATH
- Try closing and reopening VS Code/your IDE
- Verify the PATH by running: `echo %PATH%` and checking if `C:\flutter\bin` is listed

### If you get permission errors:
- Run your terminal as Administrator
- Or install Flutter to a location you have write access to (like `C:\Users\sumit\flutter`)

