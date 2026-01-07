# OTP Expired Error - Fix

## Error Message
```
error=access_denied
error_code=otp_expired
error_description=Email link is invalid or has expired
```

## What This Means

The password reset token in the email link has **expired**. This happens when:
1. **Link is too old** - Supabase has a default expiration time (usually 1 hour)
2. **Link was already used** - Tokens can only be used once
3. **Token expired** - Security measure to prevent old links from working

## Solution

**Request a NEW password reset link:**
1. Go back to the app
2. Go to **Profile** → **Settings** → **Reset Password**
3. Enter your email
4. Tap **"Send Reset Link"**
5. Check your email for the NEW link
6. Click the NEW link immediately (don't wait)

## Code Fix Applied

I've updated `app/reset-password/page.tsx` to:
- ✅ **Detect Supabase error responses** (error, error_code, error_description)
- ✅ **Show user-friendly error messages** for expired links
- ✅ **Handle errors from both query params and hash**

## Error Handling

The code now checks for:
- `error=access_denied` → Shows "Access denied" message
- `error_code=otp_expired` → Shows "Link expired, request new one" message
- `error_description` → Shows the actual error description

## Why Links Expire

Supabase expires password reset links for security:
- ✅ **Prevents old links from being used** if someone gains access to old emails
- ✅ **Limits time window** for password reset attacks
- ✅ **Standard security practice** - most services expire reset links

## Default Expiration Time

Supabase's default expiration is usually **1 hour**, but this can vary. Check:
- **Supabase Dashboard** → **Authentication** → **Settings**
- Look for **"Token Expiration"** or **"OTP Expiration"** settings

## Best Practices

1. **Request reset link when ready** - Don't request it hours before you need it
2. **Click link immediately** - Don't let it sit in your inbox
3. **Use link once** - If you need to reset again, request a new link
4. **Check email quickly** - Links expire, so act fast

## Testing

After requesting a NEW password reset:
1. ✅ **Check email immediately**
2. ✅ **Click link right away**
3. ✅ **Should work without expiration error**

## Summary

- ❌ **Old link**: Expired → Error
- ✅ **New link**: Fresh → Should work
- ✅ **Code fix**: Now shows better error messages
- ✅ **Action**: Request a new password reset link

Request a fresh password reset link and it should work! 🎉

