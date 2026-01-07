# Fix Supabase Verify Endpoint Hash Issue

## Problem

When clicking password reset email link:
1. Link goes to: `https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=...&redirect_to=...`
2. Supabase verifies token
3. Redirects to: `https://compostkaki.vercel.app/reset-password`
4. **Hash fragment is missing** → No tokens → Error

## Root Cause

Supabase's `/verify` endpoint uses PKCE flow, which might not preserve hash fragments during redirect, or the redirect doesn't include tokens in the hash.

## Solutions

### Option 1: Check Supabase Email Template (Recommended)

The email template should use `{{ .ConfirmationURL }}` which should include tokens. But Supabase might be using a different flow.

**Check:**
1. Go to **Supabase** → **Authentication** → **Email** → **Templates** → **Reset password**
2. Verify template uses: `{{ .ConfirmationURL }}`
3. Check if there's a PKCE setting that affects this

### Option 2: Configure Supabase to Use Direct Redirect

Supabase might have a setting to use direct redirects instead of verify endpoint.

**Check:**
1. Go to **Supabase** → **Authentication** → **URL Configuration**
2. Look for PKCE or flow settings
3. Try disabling PKCE if possible (for password reset)

### Option 3: Handle Verify Endpoint in Web Page

The web page now checks for verify tokens and calls Supabase verify endpoint. But this might not work if Supabase doesn't return tokens in hash.

### Option 4: Use Supabase Client-Side Verification

Instead of relying on server-side redirect, verify the token client-side:

```typescript
// In reset-password page
const verifyToken = searchParams.get('token')
if (verifyToken) {
  // Call Supabase client to verify and get session
  const { data, error } = await supabase.auth.verifyOtp({
    token: verifyToken,
    type: 'recovery'
  })
  
  if (data.session) {
    // Redirect to app with tokens
    const hash = `#type=recovery&access_token=${data.session.access_token}&refresh_token=${data.session.refresh_token}`
    window.location.href = `compostkaki://reset-password${hash}`
  }
}
```

## Debugging Steps

1. **Check browser console** when clicking email link
2. **Check Network tab** - see what Supabase verify endpoint returns
3. **Check Supabase logs** - see if verify is successful
4. **Check redirect URL** - see if hash is present after redirect

## Expected Behavior

**Correct flow:**
1. Email link: `https://supabase.co/auth/v1/verify?token=...&redirect_to=...`
2. Supabase redirects: `https://compostkaki.vercel.app/reset-password#type=recovery&access_token=...&refresh_token=...`
3. Web page redirects: `compostkaki://reset-password#tokens`
4. App opens with tokens ✅

**Current (broken) flow:**
1. Email link: `https://supabase.co/auth/v1/verify?token=...&redirect_to=...`
2. Supabase redirects: `https://compostkaki.vercel.app/reset-password` (no hash)
3. Web page shows error ❌

## Next Steps

1. **Check browser console** - see what's actually happening
2. **Check Supabase Auth logs** - see if verify is successful
3. **Try Option 4** - client-side verification might work better
4. **Check Supabase settings** - might need to configure PKCE differently

The web page now handles verify tokens, but we need to test if Supabase actually returns tokens in the hash after verification.

