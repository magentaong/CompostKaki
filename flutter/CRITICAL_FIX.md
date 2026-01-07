# CRITICAL FIX: OTP Expired Error

## The Problem

You're getting `otp_expired` error **immediately** after clicking the link, even though you clicked it right away.

## Root Cause

Supabase is **rejecting the token** because the `redirect_to` URL doesn't match exactly what's in Supabase's allowed redirect URLs list.

## CRITICAL CHECK - DO THIS NOW:

### Step 1: Verify Redirect URL EXACTLY

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Look at the **Redirect URLs** list
3. Find `https://compostkaki.vercel.app/reset-password`
4. **Copy it EXACTLY** - check for:
   - ✅ No trailing slash (`/reset-password` not `/reset-password/`)
   - ✅ Exact case (lowercase)
   - ✅ No extra spaces
   - ✅ Must be `https://` not `http://`

### Step 2: Check Email Link Format

When you receive the password reset email, check the link format:
- Should be: `https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=...&redirect_to=https://compostkaki.vercel.app/reset-password`
- The `redirect_to` parameter MUST match exactly what's in Supabase's redirect URLs

### Step 3: Verify Supabase Settings

1. **Site URL**: Should be `https://compostkaki.vercel.app` (no trailing slash)
2. **Redirect URLs** must include:
   - `https://compostkaki.vercel.app/reset-password` (EXACT match)
   - `compostkaki://reset-password`

### Step 4: Check OTP Expiration

1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Look for **"OTP Expiration"** or **"Token Expiration"**
3. Default is usually 1 hour, but check if it's set to something very short

## Why This Happens

Supabase's verify endpoint checks:
1. Is the token valid? ✅
2. Is the `redirect_to` URL in the allowed list? ❌ **THIS IS FAILING**
3. If either fails → Returns `otp_expired` error

## The Fix

**Make sure the redirect URL in your code EXACTLY matches what's in Supabase:**

```dart
// In auth_service.dart
final resetPasswordUrl = 'https://compostkaki.vercel.app/reset-password';
// Must match EXACTLY what's in Supabase redirect URLs
```

## Test After Fix

1. **Request a NEW password reset** (old links won't work)
2. **Click the link immediately**
3. **Check browser console** for any errors
4. **Should redirect to reset-password page with tokens in hash**

## If Still Not Working

Check Vercel logs:
1. Go to **Vercel Dashboard** → Your project → **Logs**
2. Look for errors when clicking the reset link
3. Check what URL Supabase is trying to redirect to

## Summary

- ❌ **Problem**: Redirect URL mismatch causing Supabase to reject token
- ✅ **Fix**: Ensure redirect URL EXACTLY matches Supabase's allowed list
- ✅ **Result**: Token verification will succeed, tokens will be in hash

**This is 99% likely the issue - Supabase is very strict about redirect URL matching!**

