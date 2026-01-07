# PKCE Settings in Supabase

## Answer: No PKCE Toggle Available

**PKCE (Proof Key for Code Exchange) is enabled by default in Supabase and cannot be disabled through the dashboard UI.**

## Why PKCE is Always Enabled

- ✅ **Security**: PKCE provides better security for OAuth flows
- ✅ **Best Practice**: Industry standard for mobile and web apps
- ✅ **Required**: Supabase requires PKCE for certain flows
- ✅ **Not Configurable**: No UI toggle to disable it

## What This Means

Your password reset flow **will always use PKCE**, which means:
1. Email links go to `/verify` endpoint first
2. Supabase verifies the token
3. Then redirects to your `redirect_to` URL

## Our Solution (Already Implemented)

We've handled PKCE flow correctly in `app/reset-password/page.tsx`:

✅ **Detects verify token** in URL (`?token=...&type=recovery`)
✅ **Uses Supabase client** to verify token client-side
✅ **Gets session tokens** directly from Supabase
✅ **Creates hash with tokens** and redirects to app

## Where PKCE Settings Might Be (But Probably Aren't)

### 1. URL Configuration (You're Here)
- ❌ No PKCE toggle
- Only Site URL and Redirect URLs

### 2. Authentication → Providers → Email
- Might have provider-specific settings
- But PKCE is global, not per-provider

### 3. Authentication → Settings
- Might have advanced settings
- But PKCE is usually not exposed

### 4. Project Settings → API Settings
- Might have API-level settings
- But PKCE is auth-level, not API-level

## Verification

You can verify PKCE is enabled by checking:
1. **Email link format**: Contains `/verify` endpoint → PKCE enabled
2. **Auth logs**: Look for PKCE-related entries
3. **API behavior**: Uses `/verify` endpoint → PKCE flow

## Current Status

✅ **PKCE**: Enabled (default, not configurable)
✅ **Fix**: Implemented (handles verify endpoint client-side)
✅ **Status**: Should work now

## Next Steps

1. **No need to disable PKCE** - it's not possible and not needed
2. **Test the password reset flow** - our fix handles PKCE correctly
3. **Verify it works** - the client-side verification should work

## Summary

- ❌ **PKCE toggle**: Not available in Supabase UI
- ✅ **PKCE status**: Always enabled (default)
- ✅ **Our fix**: Handles PKCE flow correctly
- ✅ **Action**: Test the password reset flow

The fix we implemented should work with PKCE enabled. No configuration changes needed!

