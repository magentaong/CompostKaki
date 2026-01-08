# Fix access_denied Error - Password Reset

## The Problem
You're getting `access_denied` error when clicking password reset link. This means Supabase is rejecting the `redirect_to` URL.

## Root Cause
When Supabase generates the email link, it uses the `redirectTo` parameter from `resetPasswordForEmail()`. However, if:
1. The `redirectTo` doesn't match Supabase's allowed redirect URLs EXACTLY
2. The email template is using a hardcoded URL instead of `{{ .ConfirmationURL }}`
3. The `redirect_to` in the email link is different from what's in allowed URLs

Then Supabase will reject it with `access_denied`.

## Solution

### Step 1: Check Email Link Format
When you receive the password reset email, check the link format. It should be:
```
https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=pkce_...&type=recovery&redirect_to=https://compostkaki.vercel.app/reset-password
```

**CRITICAL:** The `redirect_to` parameter MUST match EXACTLY what's in Supabase's allowed redirect URLs.

### Step 2: Verify Supabase Configuration
In Supabase Dashboard → Authentication → URL Configuration:

**Site URL:**
```
https://compostkaki.vercel.app
```

**Redirect URLs (must include):**
```
https://compostkaki.vercel.app/reset-password
compostkaki://reset-password
```

### Step 3: Check Email Template
In Supabase Dashboard → Authentication → Email Templates → Reset Password:

The template MUST use `{{ .ConfirmationURL }}` - this automatically includes the correct `redirect_to` parameter.

**Correct Template:**
```html
<h2>Reset Password</h2>
<p>Click the button below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #00796B; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">Reset Password</a></p>
<p>This link will expire in 1 hour.</p>
```

**WRONG (hardcoded URL):**
```html
<a href="https://compostkaki.vercel.app/reset-password">Reset Password</a>
```

### Step 4: Verify Code
In `flutter/lib/services/auth_service.dart`, ensure:
```dart
await _supabaseService.client.auth.resetPasswordForEmail(
  email,
  redirectTo: 'https://compostkaki.vercel.app/reset-password', // Must match allowed URL exactly
);
```

## Debugging Steps

1. **Request a new password reset**
2. **Check the email link** - copy the full URL
3. **Verify `redirect_to` parameter** matches allowed URLs exactly
4. **Check browser console** when clicking link - look for errors
5. **Check Supabase Auth Logs** for detailed error messages

## Common Issues

### Issue 1: Email Template Using Wrong URL
**Symptom:** Email link has `redirect_to=https://compostkaki.vercel.app` (Site URL) instead of `redirect_to=https://compostkaki.vercel.app/reset-password`

**Fix:** Update email template to use `{{ .ConfirmationURL }}` instead of hardcoded URL

### Issue 2: redirectTo Parameter Mismatch
**Symptom:** Code uses `redirectTo: 'https://compostkaki.vercel.app/reset-password'` but Supabase allowed URLs don't have it

**Fix:** Add `https://compostkaki.vercel.app/reset-password` to Supabase allowed redirect URLs

### Issue 3: Trailing Slash Mismatch
**Symptom:** Code uses `redirectTo: 'https://compostkaki.vercel.app/reset-password/'` (with trailing slash) but allowed URL is without slash

**Fix:** Ensure no trailing slash - use `https://compostkaki.vercel.app/reset-password` (no trailing slash)

## After Fixing

1. **Save all changes** in Supabase Dashboard
2. **Request a NEW password reset** (old emails won't work)
3. **Test the flow** end-to-end
4. **Check browser console** for any errors

