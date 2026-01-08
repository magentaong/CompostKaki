# Fix: Reset Password Button Not Clickable on First Email

## Problem
- **First email**: Button has no link (not clickable)
- **Second email**: Button works (has link)

## Root Cause
The Supabase email template is likely:
1. **Using plain text** instead of HTML anchor tag
2. **Template variable not rendering** on first send
3. **Email service caching** the wrong template

## Solution: Update Supabase Email Template

### Step 1: Go to Email Template Settings

1. Go to **Supabase Dashboard**
2. Navigate to **Authentication** → **Email** → **Templates**
3. Click on **"Reset password"** template

### Step 2: Check Current Template

Look for one of these issues:

**❌ WRONG (Plain Text):**
```
Reset Password
{{ .ConfirmationURL }}
```

**❌ WRONG (No Anchor Tag):**
```
Click here: {{ .ConfirmationURL }}
```

**✅ CORRECT (HTML Anchor Tag):**
```html
<a href="{{ .ConfirmationURL }}">Reset Password</a>
```

### Step 3: Replace with This Template

**Subject Line:**
```
Reset Your Password
```

**Body (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #E6FFF3; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
    <h1 style="color: #00796B; margin: 0;">CompostKaki</h1>
  </div>
  
  <h2 style="color: #00796B;">Reset Your Password</h2>
  
  <p>Click the button below to reset your password:</p>
  
  <div style="text-align: center; margin: 30px 0;">
    <a href="{{ .ConfirmationURL }}" style="
      background-color: #00796B;
      color: white;
      padding: 16px 32px;
      text-decoration: none;
      border-radius: 12px;
      display: inline-block;
      font-weight: bold;
      font-size: 16px;
    ">Reset Password</a>
  </div>
  
  <p style="color: #666; font-size: 14px;">
    Or copy and paste this link into your browser:
  </p>
  
  <p style="
    word-break: break-all;
    color: #00796B;
    background-color: #f5f5f5;
    padding: 12px;
    border-radius: 4px;
    font-size: 12px;
  ">{{ .ConfirmationURL }}</p>
  
  <p style="color: #999; font-size: 12px; margin-top: 30px;">
    This link will expire in 1 hour. If you didn't request this, please ignore this email.
  </p>
</body>
</html>
```

### Step 4: Important Notes

1. **Must use `{{ .ConfirmationURL }}`** - This is the correct variable
2. **Must use HTML `<a>` tag** - Plain text won't be clickable
3. **Save the template** - Click "Save" in Supabase
4. **Test it** - Use "Send test email" button

### Step 5: Verify Template is Saved

1. After saving, refresh the page
2. Open the template again
3. Verify your changes are there
4. Check that it's set to **HTML** format (not plain text)

## Why First Email Fails But Second Works

Possible reasons:

1. **Template caching** - Supabase caches templates, first send uses old cached version
2. **Email service initialization** - SendGrid/SMTP needs to initialize on first send
3. **Template rendering delay** - First email might render before template is fully loaded

## Quick Test

After updating the template:

1. **Save the template** in Supabase
2. **Wait 30 seconds** (let cache clear)
3. **Request a NEW password reset** from app
4. **Check the email** - button should be clickable
5. **Click the button** - should work!

## Alternative: Use Plain Text Link

If HTML still doesn't work, use plain text with full URL:

```
Reset your password by clicking this link:

{{ .ConfirmationURL }}

This link will expire in 1 hour.
```

## Verification Checklist

- [ ] Template uses HTML format (not plain text)
- [ ] Template has `<a href="{{ .ConfirmationURL }}">` anchor tag
- [ ] Template is saved in Supabase
- [ ] Test email sent and button is clickable
- [ ] Request new password reset and verify it works

## If Still Not Working

1. **Check Supabase Auth Logs:**
   - Go to **Logs** → **Auth Logs**
   - Look for `user_recovery_requested` events
   - Check for template errors

2. **Check SendGrid Logs** (if using SendGrid):
   - Go to SendGrid Dashboard → Activity
   - Check email delivery status
   - Verify HTML is being rendered

3. **Try Different Email Client:**
   - Some email clients cache emails
   - Try Gmail, Outlook, Apple Mail
   - Check if issue is email-client specific

## Summary

- ❌ **Problem**: First email button not clickable
- ✅ **Fix**: Update email template with proper HTML anchor tag
- ✅ **Template Variable**: Use `{{ .ConfirmationURL }}`
- ✅ **Format**: Must be HTML (not plain text)
- ✅ **Result**: Button will be clickable on first email!

