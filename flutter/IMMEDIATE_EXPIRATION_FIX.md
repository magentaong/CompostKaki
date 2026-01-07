# Fix: Link Expired Immediately After Clicking

## Problem
You clicked the password reset link **immediately** after receiving it, but it says "expired". This shouldn't happen!

## Root Cause

If a link expires immediately, it's **NOT actually expired** - Supabase is **rejecting the redirect** because:

**The API route is NOT in Supabase's allowed Redirect URLs!**

## Critical Fix Required

### Step 1: Add API Route to Supabase Redirect URLs

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Under **"Redirect URLs"**, check if this URL exists:
   ```
   https://compostkaki.vercel.app/api/auth/verify-reset
   ```
3. **If it's NOT there:**
   - Click **"Add URL"**
   - Paste: `https://compostkaki.vercel.app/api/auth/verify-reset`
   - Click **"Save"**

### Step 2: Verify All Redirect URLs

Make sure you have ALL of these:
- ✅ `https://compostkaki.vercel.app/reset-password`
- ✅ `https://compostkaki.vercel.app/api/auth/verify-reset` (CRITICAL!)
- ✅ `compostkaki://reset-password`

## Why This Causes "Expired" Error

When Supabase's verify endpoint tries to redirect to a URL **not in the allow list**:
1. Supabase **rejects the redirect**
2. Returns an error (often "expired" or "access_denied")
3. User sees "expired" even though link is fresh

## How to Verify It's Fixed

After adding the API route to redirect URLs:

1. **Request a NEW password reset** (old links won't work)
2. **Click the link immediately**
3. **Should work!** ✅

## Check Vercel Logs

If still not working, check Vercel logs:
1. Go to **Vercel Dashboard** → Your project → **Logs**
2. Look for `🔐 [VERIFY API]` logs
3. Check what error Supabase is returning

## Summary

- ❌ **Problem**: API route not in Supabase redirect URLs
- ✅ **Fix**: Add `https://compostkaki.vercel.app/api/auth/verify-reset` to redirect URLs
- ✅ **Result**: Links will work immediately!

**This is the most common cause of immediate "expiration" - Supabase rejecting the redirect!**

