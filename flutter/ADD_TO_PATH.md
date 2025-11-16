# Add Flutter to PATH Permanently

Flutter is currently installed at `C:\flutter`, but you need to add it to your PATH so you can use the `flutter` command from anywhere.

## Quick Steps (Windows)

1. **Open Environment Variables:**
   - Press `Win + X` and select "System"
   - Click "Advanced system settings" (on the right)
   - Click "Environment Variables" button at the bottom

2. **Add Flutter to PATH:**
   - Under "User variables" (top section), find "Path" and click "Edit"
   - Click "New" button
   - Type: `C:\flutter\bin`
   - Click "OK" on all dialogs

3. **Restart your terminal/IDE:**
   - Close and reopen your command prompt/PowerShell
   - Close and reopen VS Code (if using it)
   - This is important! PATH changes only take effect in new terminal sessions

4. **Verify it works:**
   ```bash
   flutter --version
   ```

## Alternative: Use PowerShell Script (Run as Administrator)

You can also run this PowerShell command as Administrator:

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", [EnvironmentVariableTarget]::User)
```

Then restart your terminal.

## For Current Session Only

If you just want to use Flutter in your current terminal session, run:

```powershell
$env:Path += ";C:\flutter\bin"
```

This only works until you close the terminal.

