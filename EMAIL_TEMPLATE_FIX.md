# Email Template Fix - Reset Password Button Not Clickable

## Problem
The "Reset Password" button in the email doesn't have a link attached on the first email, but works on subsequent emails.

## Root Cause
This is likely a **Supabase email template issue**. The email template might not be properly configured or the `{{ .ConfirmationURL }}` placeholder isn't being replaced correctly on the first send.

## Solution

### Step 1: Check Email Template in Supabase

1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**
2. Find the **"Reset Password"** template
3. Check if it has proper HTML anchor tag:

**CORRECT Format:**
```html
<a href="{{ .ConfirmationURL }}" style="background-color: #00796B; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
  Reset Password
</a>
```

**INCORRECT Format (plain text):**
```
Reset Password: {{ .ConfirmationURL }}
```

### Step 2: Verify Template Variables

Make sure the template uses:
- `{{ .ConfirmationURL }}` - The full reset link URL
- NOT `{{ .Token }}` or `{{ .TokenHash }}` - These won't work for password reset

### Step 3: Check Email Template Syntax

The template should be valid HTML. Common issues:

**❌ Wrong:**
```html
Reset Password
{{ .ConfirmationURL }}
```

**✅ Correct:**
```html
<a href="{{ .ConfirmationURL }}">Reset Password</a>
```

### Step 4: Test Email Template

1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**
2. Click **"Reset Password"** template
3. Click **"Send test email"**
4. Check if the button is clickable in the test email

## Why First Email Fails But Second Works

Possible reasons:

1. **Template caching** - Supabase might cache the template, and the first send uses a cached version
2. **Email service initialization** - SendGrid/SMTP might need to initialize on first send
3. **Template rendering** - First email might be rendered differently by email service

## Recommended Email Template

Here's a complete, working template:

```html
<h2>Reset Your Password</h2>
<p>Click the button below to reset your password:</p>

<a href="{{ .ConfirmationURL }}" style="
  background-color: #00796B;
  color: white;
  padding: 16px 32px;
  text-decoration: none;
  border-radius: 12px;
  display: inline-block;
  font-weight: bold;
  margin: 20px 0;
">
  Reset Password
</a>

<p>Or copy and paste this link:</p>
<p style="word-break: break-all; color: #666;">{{ .ConfirmationURL }}</p>

<p>This link will expire in 1 hour.</p>
```

## Alternative: Use Plain Text Link

If HTML isn't working, use a plain text link:

```
Reset your password by clicking this link:

{{ .ConfirmationURL }}

This link will expire in 1 hour.
```

## Verification Steps

1. **Check Supabase Auth Logs:**
   - Go to **Supabase Dashboard** → **Logs** → **Auth Logs**
   - Look for `user_recovery_requested` events
   - Check if there are any template errors

2. **Check Email Service Logs:**
   - If using SendGrid, check SendGrid activity logs
   - Look for email delivery status
   - Check if HTML is being rendered correctly

3. **Test Email Rendering:**
   - Send test email from Supabase
   - Check email source (View Source in email client)
   - Verify `{{ .ConfirmationURL }}` is replaced with actual URL

## Quick Fix

1. **Update email template** with proper HTML anchor tag
2. **Save template** in Supabase
3. **Request new password reset** - should work now
4. **If still not working**, check SendGrid/SMTP settings

## Prevention

- Always use proper HTML anchor tags in email templates
- Test email template before deploying
- Use `{{ .ConfirmationURL }}` variable (not manual URL construction)
- Check email logs if issues persist

