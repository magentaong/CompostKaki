# Password Reset Flow - Complete Explanation

## Overview
The password reset flow uses a **multi-step process** that bypasses Supabase's redirect URL matching issues by intercepting tokens at multiple points.

---

## Step-by-Step Flow

### **Step 1: User Requests Password Reset (Flutter App)**

**Location:** `flutter/lib/services/auth_service.dart` → `resetPassword()`

**What happens:**
1. User enters email in the app
2. App calls `AuthService.resetPassword(email)`
3. App calls Supabase's `resetPasswordForEmail()` **WITHOUT** specifying `redirectTo`
4. Supabase sends password reset email to user

**Key point:** We don't specify `redirectTo` to avoid URL matching issues. Supabase will use its default Site URL.

```dart
await _supabaseService.client.auth.resetPasswordForEmail(
  email,
  // No redirectTo parameter - let Supabase use default
);
```

---

### **Step 2: User Receives Email**

**Email contains:**
- Link to Supabase's verify endpoint
- Format: `https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=pkce_...&type=recovery&redirect_to=https://compostkaki.vercel.app`

**What Supabase does:**
- When user clicks link, Supabase verifies the token
- Supabase redirects to Site URL (`https://compostkaki.vercel.app`) with token in query params

---

### **Step 3: Middleware Intercepts (Server-Side)**

**Location:** `middleware.ts`

**What happens:**
1. **BEFORE** the home page loads, middleware runs on Vercel's server
2. Middleware checks if URL has a password reset token
3. If token found on home page (`/`), redirects to `/reset-password` with token
4. If token found on reset-password page but no hash, redirects to `/api/auth/verify-token`

**Key point:** This happens **server-side** before React even loads, so it's instant.

```typescript
// If on home page with token → redirect to reset-password
if (url.pathname === '/' && token && isRecoveryToken) {
  url.pathname = '/reset-password'
  return NextResponse.redirect(url)
}

// If on reset-password with token but no hash → redirect to verify API
if (url.pathname === '/reset-password' && token && !url.hash) {
  url.pathname = '/api/auth/verify-token'
  return NextResponse.redirect(url)
}
```

---

### **Step 4: Token Verification (API Route)**

**Location:** `app/api/auth/verify-token/route.ts`

**What happens:**
1. API receives token from middleware redirect
2. API calls Supabase's verify endpoint directly via HTTP
3. Supabase returns a redirect with tokens in hash (`#access_token=...&refresh_token=...`)
4. API extracts tokens from hash
5. API redirects back to `/reset-password` **with tokens in hash**

**Key point:** We verify the token **server-side** and extract tokens ourselves, bypassing Supabase's redirect URL checks.

```typescript
// Call Supabase verify endpoint
const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${token}&type=${type}`
const verifyResponse = await fetch(verifyUrl, { redirect: 'manual' })

// Extract tokens from redirect hash
const redirectUrl = new URL(location)
const hash = redirectUrl.hash
// Extract access_token and refresh_token from hash

// Redirect to reset-password page with tokens in hash
return NextResponse.redirect(`/reset-password${hash}`)
```

---

### **Step 5: Reset Password Page (Web)**

**Location:** `app/reset-password/page.tsx`

**What happens:**
1. Page loads with tokens in URL hash (`#access_token=...&refresh_token=...`)
2. Page extracts tokens from hash
3. Page constructs deep link: `compostkaki://reset-password#type=recovery&access_token=...&refresh_token=...`
4. Page redirects to deep link using `window.location.href`

**Key point:** The web page acts as a bridge - it receives tokens and redirects to the app.

```typescript
// Extract tokens from hash
const hashParams = new URLSearchParams(hash.substring(1))
const accessToken = hashParams.get('access_token')
const refreshToken = hashParams.get('refresh_token')

// Create deep link
const deepLink = `compostkaki://reset-password#type=recovery&access_token=...&refresh_token=...`

// Redirect to app
window.location.href = deepLink
```

---

### **Step 6: Deep Link Handler (Flutter App)**

**Location:** `flutter/lib/main.dart` → `_processDeepLink()`

**What happens:**
1. App receives deep link: `compostkaki://reset-password#type=recovery&access_token=...&refresh_token=...`
2. App extracts tokens from URL fragment
3. App navigates to `/reset-password` route with tokens as query parameters
4. App calls `AuthService.setRecoverySession()` to set the Supabase session

**Key point:** The app sets a recovery session so the user can update their password.

```dart
// Extract tokens from deep link
final fragment = uri.fragment
final params = Uri.splitQueryString(fragment)
final accessToken = params['access_token']
final refreshToken = params['refresh_token']

// Navigate to reset password screen with tokens
final route = '/reset-password?access_token=$accessToken&refresh_token=$refreshToken&type=recovery'
AppRouter.router.go(route)
```

---

### **Step 7: Reset Password Screen (Flutter App)**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**What happens:**
1. Screen loads and checks for tokens in route parameters
2. If tokens found, calls `AuthService.setRecoverySession()` to set Supabase session
3. User enters new password
4. User confirms password
5. App calls `AuthService.updatePasswordWithRecovery()` to update password
6. After success, user is signed out and redirected to login

**Key point:** The screen handles the actual password update using the recovery session.

```dart
// Set recovery session from tokens
final authService = context.read<AuthService>();
await authService.setRecoverySession(accessToken, refreshToken);

// User enters new password
// Then update password
await authService.updatePasswordWithRecovery(
  accessToken: accessToken,
  refreshToken: refreshToken,
  newPassword: newPassword,
);
```

---

## Complete Flow Diagram

```
1. User in App
   ↓
2. Request Reset → Supabase sends email
   ↓
3. User clicks email link → Supabase verify endpoint
   ↓
4. Supabase redirects → Home page (https://compostkaki.vercel.app?token=...)
   ↓
5. Middleware intercepts → Redirects to /reset-password?token=...
   ↓
6. Middleware intercepts again → Redirects to /api/auth/verify-token?token=...
   ↓
7. API verifies token → Gets tokens from Supabase → Redirects to /reset-password#access_token=...&refresh_token=...
   ↓
8. Reset-password page → Extracts tokens → Redirects to compostkaki://reset-password#tokens
   ↓
9. App receives deep link → Sets recovery session → Navigates to ResetPasswordScreen
   ↓
10. User enters new password → App updates password → User redirected to login
```

---

## Key Components

### **1. Middleware (`middleware.ts`)**
- **Purpose:** Server-side interception before page loads
- **Why:** Fastest way to catch tokens, no client-side delay
- **Runs on:** Vercel's edge network

### **2. Verify Token API (`app/api/auth/verify-token/route.ts`)**
- **Purpose:** Verify token and extract session tokens
- **Why:** Bypasses Supabase redirect URL matching issues
- **Runs on:** Vercel serverless functions

### **3. Reset Password Page (`app/reset-password/page.tsx`)**
- **Purpose:** Bridge between web and app
- **Why:** Extracts tokens and redirects to app via deep link
- **Runs on:** Client-side (browser)

### **4. Deep Link Handler (`flutter/lib/main.dart`)**
- **Purpose:** Receive deep link and set recovery session
- **Why:** Allows app to handle password reset flow
- **Runs on:** Flutter app

### **5. Reset Password Screen (`flutter/lib/screens/auth/reset_password_screen.dart`)**
- **Purpose:** UI for user to enter new password
- **Why:** Provides user-friendly interface
- **Runs on:** Flutter app

---

## Why This Approach Works

1. **No Redirect URL Matching Issues:** We don't rely on Supabase's redirect URL validation
2. **Server-Side Verification:** Token verification happens on server, more reliable
3. **Multiple Interception Points:** Middleware catches tokens at multiple stages
4. **Deep Linking:** Seamless transition from web to app
5. **Error Handling:** Each step has error handling and fallbacks

---

## Troubleshooting

### If reset link doesn't work:
1. **Check middleware logs** - Is it intercepting?
2. **Check API logs** - Is token verification working?
3. **Check browser console** - Are tokens in hash?
4. **Check app logs** - Is deep link received?

### Common Issues:
- **Token expired:** Request new reset email
- **Middleware not running:** Check Vercel deployment
- **Deep link not opening app:** Check app_links configuration
- **Session not set:** Check AuthService.setRecoverySession()

---

## Summary

The password reset flow uses a **multi-layered approach**:
1. **Middleware** catches tokens server-side (fastest)
2. **API route** verifies tokens and extracts session tokens
3. **Web page** bridges to app via deep link
4. **App** receives deep link and sets recovery session
5. **User** enters new password and completes reset

This approach is **robust** because it has multiple fallback points and doesn't rely on Supabase's redirect URL matching.

