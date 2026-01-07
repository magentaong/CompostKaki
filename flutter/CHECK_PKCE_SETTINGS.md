# How to Check PKCE Settings in Supabase

## What is PKCE?

PKCE (Proof Key for Code Exchange) is a security extension for OAuth 2.0. Supabase uses PKCE by default for password reset flows, which uses a `/verify` endpoint instead of direct hash fragments.

## How to Check PKCE Settings

### Step 1: Navigate to Authentication Settings

1. **Go to Supabase Dashboard**
2. **Select your project** (CompostConnect)
3. **Click "Authentication"** in the left sidebar
4. **Click "Configuration"** (or look for settings)

### Step 2: Look for PKCE/Flow Settings

PKCE settings might be in different places:

#### Option A: URL Configuration
1. Go to **Authentication** → **URL Configuration**
2. Look for:
   - **"PKCE"** toggle or setting
   - **"Flow Type"** or **"Auth Flow"** setting
   - **"Use PKCE"** checkbox

#### Option B: Provider Settings
1. Go to **Authentication** → **Providers**
2. Look for **"Email"** provider settings
3. Check for PKCE-related options

#### Option C: Advanced Settings
1. Go to **Authentication** → **Settings** (or **Configuration**)
2. Look for **"Advanced"** or **"Security"** section
3. Check for PKCE settings

### Step 3: Check Email Template Settings

1. Go to **Authentication** → **Email** → **Templates**
2. Click **"Reset password"** template
3. Check if there's a **"Flow"** or **"PKCE"** setting
4. Look for any options about **"Redirect method"** or **"Token delivery"**

## What to Look For

### Settings That Might Affect Password Reset:

- ✅ **"Use PKCE"** - Toggle to enable/disable PKCE
- ✅ **"Flow Type"** - Options like "PKCE", "Implicit", "Authorization Code"
- ✅ **"Redirect Method"** - Hash fragment vs query parameters
- ✅ **"Token Delivery"** - How tokens are included in redirect

## If You Can't Find PKCE Settings

Supabase might have PKCE enabled by default and not expose a toggle. In that case:

### Option 1: Check Supabase Documentation
- Look for "PKCE" in Supabase docs
- Check if it's configurable for password reset

### Option 2: Check Auth Logs
1. Go to **Logs** → **Auth Logs**
2. Look for password reset attempts
3. Check if logs mention "PKCE" or "verify" endpoint

### Option 3: Check Email Link Format
- **With PKCE**: Link goes to `/verify` endpoint first
- **Without PKCE**: Link goes directly to your redirect URL with hash

## Current Behavior (PKCE Flow)

Your current email links use PKCE:
```
https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=...&redirect_to=...
```

This means:
- ✅ PKCE is enabled (default)
- ✅ Uses `/verify` endpoint
- ✅ Requires client-side verification (which we've implemented)

## Solution Already Implemented

We've already fixed this by handling the verify endpoint client-side in `app/reset-password/page.tsx`:

1. ✅ Detects verify token in URL
2. ✅ Uses Supabase client to verify token
3. ✅ Gets session tokens
4. ✅ Redirects to app with tokens in hash

## Next Steps

1. **Check Supabase settings** using the steps above
2. **If PKCE can be disabled** for password reset, try disabling it
3. **If PKCE must stay enabled**, the current fix should work
4. **Test the password reset flow** to confirm it works

## Alternative: Check Supabase Version

PKCE behavior might depend on Supabase version:
1. Go to **Settings** → **Project Settings**
2. Check **"Supabase Version"** or **"API Version"**
3. Newer versions might have different PKCE behavior

## Summary

- **PKCE is likely enabled by default** in Supabase
- **Settings might not be exposed** in the dashboard
- **Our client-side fix handles PKCE flow** correctly
- **Check the settings locations above** to see if you can configure it

The fix we implemented should work regardless of PKCE settings, as it handles the verify endpoint properly.

