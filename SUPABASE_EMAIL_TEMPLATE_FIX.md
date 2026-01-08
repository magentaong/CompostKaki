# Fix Supabase Email Template - Use TokenHash Instead of ConfirmationURL

## The Problem
Using `{{ .ConfirmationURL }}` in the email template causes iOS Gmail to consume the OTP token automatically (prefetch/scanner), leading to `otp_expired` errors.

## The Solution
Use `{{ .TokenHash }}` instead and route to YOUR site first, then verify on button click.

---

## Step 1: Update Supabase Email Template

### Go to Supabase Dashboard
1. Navigate to **Authentication** → **Email Templates**
2. Click on **"Reset Password"** template

### Replace the Template Body

**❌ OLD (causes iOS Gmail issues):**
```html
<h2>Reset Password</h2>
<p>Click the link below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
```

**✅ NEW (iOS-safe):**
```html
<h2>Reset Password</h2>
<p>Click the button below to reset your password:</p>
<p><a href="https://compostkaki.vercel.app/reset-password?token_hash={{ .TokenHash }}&type=recovery" style="display: inline-block; padding: 12px 24px; background-color: #00796B; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">Reset Password</a></p>
<p>This link will expire in 1 hour.</p>
<p>If you didn't request this, please ignore this email.</p>
```

### Key Changes
- **Use `{{ .TokenHash }}`** instead of `{{ .ConfirmationURL }}`
- **Route to YOUR site** (`compostkaki.vercel.app/reset-password`) instead of Supabase's `/verify` endpoint
- **TokenHash is safe** - it doesn't consume the OTP by itself

---

## Step 2: Update Reset Password Page

The reset-password page will now:
1. Show a "Continue to Reset Password" button
2. Only when user clicks → call `verifyOtp` with `token_hash`
3. Get session tokens → deep link to app

---

## Why This Works

### Link Scanners Won't Click Buttons
- Gmail's prefetch/scanner hits the URL (harmless - just loads your page)
- TokenHash doesn't consume OTP by itself
- Only when user clicks button → `verifyOtp` is called → OTP consumed

### iOS Gmail Safe
- No automatic GET to Supabase `/verify` endpoint
- OTP only consumed on explicit user action
- Works reliably on all email clients

---

## After Updating Template

1. **Save the template** in Supabase Dashboard
2. **Request a NEW password reset** (old emails won't work)
3. **Test the flow** - should work reliably on iOS Gmail

