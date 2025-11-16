# Quick Fix: Use Flutter Right Now

Since your CMD was opened before adding Flutter to PATH, you have two options:

## Option 1: Restart CMD (Recommended)
Just close and reopen your command prompt. Then `flutter` will work!

## Option 2: Use Full Path (Temporary)
In your current CMD, use the full path:

```cmd
C:\flutter\bin\flutter.bat --version
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Option 3: Add to PATH in Current Session
In your CMD prompt, run:
```cmd
set PATH=%PATH%;C:\flutter\bin
```

Then `flutter` will work in that CMD window (until you close it).

