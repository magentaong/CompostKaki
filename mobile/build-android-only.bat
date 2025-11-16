@echo off
REM Build script for Windows - Android only
REM Uses init script to prevent iOS initialization

echo Building Android app only...
echo Using init script to prevent iOS target initialization...

call gradlew.bat --init-script gradle\init.gradle :androidApp:assembleDebug --no-daemon

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful! APK location:
    echo androidApp\build\outputs\apk\debug\androidApp-debug.apk
) else (
    echo.
    echo Build failed. Check the error messages above.
)

pause

