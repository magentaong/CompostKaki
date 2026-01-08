# Configure Supabase Email Template for OTP Codes

## The Problem
`resetPasswordForEmail()` sends a **link**, not an OTP code. To send OTP codes, we need to:
1. Use `signInWithOtp()` instead (which sends OTP codes)
2. Configure Supabase email template to display OTP code

## Solution: Update Supabase Email Template

### Step 1: Go to Supabase Dashboard
1. Navigate to **Authentication** → **Email Templates**
2. Find the **"Magic Link"** or **"OTP"** template (this is what `signInWithOtp` uses)

### Step 2: Update Template to Show OTP Code

**Current template might show:**
```html
Click the link to sign in: {{ .ConfirmationURL }}
```

**Update to show OTP code:**
```html
<h2>Password Reset Code</h2>
<p>Your password reset code is:</p>
<h1 style="font-size: 32px; letter-spacing: 8px; color: #00796B; text-align: center; padding: 20px; background-color: #E6FFF3; border-radius: 8px; margin: 20px 0;">
  {{ .Token }}
</h1>
<p>Enter this code in the app to reset your password.</p>
<p>This code will expire in 1 hour.</p>
<p>If you didn't request this, please ignore this email.</p>
```

### Step 3: Alternative - Use "Change Email" Template

If Supabase doesn't have a dedicated OTP template, you can:
1. Use the **"Change Email"** template
2. Or create a custom template that shows `{{ .Token }}`

## How It Works

1. **App calls `signInWithOtp(email)`**
2. **Supabase sends email** with OTP code (from template)
3. **User enters OTP code** in app
4. **App calls `verifyOTP(type: recovery, email, token)`**
5. **Supabase creates recovery session**
6. **User resets password**

## Important Notes

- The OTP code is in `{{ .Token }}` variable
- Make sure the template displays the code clearly
- The code is usually 6 digits
- Code expires after 1 hour (default)

## Testing

After updating the template:
1. Request password reset from app
2. Check email - should see OTP code (not link)
3. Enter code in app
4. Should work! ✅

