# Forget Password Flow - Current Implementation

## Overview
The password reset flow uses a **multi-layered approach** that handles tokens at multiple points (server-side middleware, client-side pages, and deep linking) to ensure reliable password reset across web and mobile.

---

## Step-by-Step Flow

### **Step 1: User Requests Password Reset (Flutter App)**

**Location:** `flutter/lib/services/auth_service.dart` → `resetPassword()`

**What happens:**
1. User enters email in the app
2. App calls `AuthService.resetPassword(email)`
3. App calls Supabase's `resetPasswordForEmail()` with `redirectTo: 'https://compostkaki.vercel.app/reset-password'`
4. Supabase generates a recovery token and sends password reset email

**Code:**
```dart
await _supabaseService.client.auth.resetPasswordForEmail(
  email,
  redirectTo: 'https://compostkaki.vercel.app/reset-password',
);
```

**Email sent contains:**
- Link to Supabase's verify endpoint
- Format: `https://tqpjrlwdgoctacfrbanf.supabase.co/auth/v1/verify?token=pkce_...&type=recovery&redirect_to=https://compostkaki.vercel.app/reset-password`

---

### **Step 2: User Clicks Email Link**

**What happens:**
1. User clicks link in email
2. Browser navigates to Supabase's verify endpoint
3. Supabase verifies the token (consumes it - one-time use)
4. Supabase redirects to `redirect_to` URL with one of:
   - **Success:** Tokens in hash: `#access_token=...&refresh_token=...`
   - **Error:** Error in hash: `#error=access_denied&error_code=...`

**Possible redirects:**
- `https://compostkaki.vercel.app/reset-password#access_token=...&refresh_token=...` (success)
- `https://compostkaki.vercel.app/reset-password#error=access_denied&...` (error)
- `https://compostkaki.vercel.app?token=pkce_...&type=recovery` (if redirect_to doesn't match)

---

### **Step 3: Server-Side Middleware Intercepts (Vercel)**

**Location:** `middleware.ts`

**What happens (BEFORE React loads):**
1. Middleware runs on Vercel's server
2. Checks URL for password reset tokens or errors
3. If on home page (`/`) with token → redirects to `/reset-password` with token
4. If on home page (`/`) with error in hash → redirects to `/reset-password` with error

**Code:**
```typescript
// If on home page with token → redirect to reset-password
if (url.pathname === '/' && token && isRecoveryToken) {
  url.pathname = '/reset-password'
  url.searchParams.set('token', token)
  return NextResponse.redirect(url)
}

// If error in hash → redirect to reset-password
if (error && url.pathname === '/') {
  url.pathname = '/reset-password'
  return NextResponse.redirect(url)
}
```

**Key point:** This happens **server-side** before React loads, ensuring tokens are caught immediately.

---

### **Step 4: Client-Side Home Page Check (Backup)**

**Location:** `app/page.tsx`

**What happens (if middleware didn't catch it):**
1. React component loads
2. `useEffect` runs immediately (before render)
3. Checks for tokens or errors in URL
4. If found → immediately redirects to `/reset-password` using `window.location.replace()`

**Code:**
```typescript
useEffect(() => {
  const token = urlParams.get('token') || urlParams.get('code')
  const hash = window.location.hash
  
  // Check for errors in hash
  if (hash && hash.includes('error=')) {
    window.location.replace(`/reset-password${hash}`)
    return
  }
  
  // Check for tokens
  if (token && isRecoveryToken) {
    window.location.replace(`/reset-password?token=${token}&type=recovery`)
    return
  }
}, [])
```

**Key point:** This is a **backup** in case middleware doesn't catch it (e.g., client-side navigation).

---

### **Step 5: Reset Password Page Handles Token**

**Location:** `app/reset-password/page.tsx`

**What happens:**
1. Page loads and checks URL for tokens/errors
2. **If error in hash/query params:** Shows error message
3. **If token but no hash:** Redirects to server-side verification API
4. **If tokens in hash:** Creates deep link and shows "Tap to Open App" button

**Code:**
```typescript
// Check for errors first
if (errorParam) {
  setError(errorMessage)
  return
}

// If token but no hash → use server-side verification
if (token && !hash) {
  const verifyApiUrl = `/api/auth/verify-recovery?token=${token}&type=${type}`
  window.location.href = verifyApiUrl
  return
}

// If tokens in hash → create deep link
if (hash && accessToken && refreshToken) {
  const link = `compostkaki://reset-password#type=recovery&access_token=${accessToken}&refresh_token=${refreshToken}`
  setDeepLink(link)
  setTokensReady(true)
  // Show "Tap to Open App" button
}
```

---

### **Step 6: Server-Side Token Verification (If Needed)**

**Location:** `app/api/auth/verify-recovery/route.ts`

**What happens (if token but no hash):**
1. API route receives token
2. Uses Supabase Admin API (service role key) to verify token
3. Bypasses redirect URL matching issues
4. Creates recovery session and extracts tokens
5. Redirects back to `/reset-password` with tokens in hash

**Code:**
```typescript
// Call Supabase verify endpoint with admin key
const verifyResponse = await fetch(verifyUrl, {
  headers: {
    'apikey': supabaseServiceKey,
    'Authorization': `Bearer ${supabaseServiceKey}`,
  },
  redirect: 'manual'
})

// Extract tokens from redirect or create session
// Redirect with tokens in hash
return NextResponse.redirect(`${redirectTo}${hash}`)
```

**Key point:** Uses **admin API** to bypass redirect URL checks.

---

### **Step 7: "Tap to Open App" Button**

**Location:** `app/reset-password/page.tsx`

**What happens:**
1. Page detects tokens in hash
2. Creates deep link: `compostkaki://reset-password#type=recovery&access_token=...&refresh_token=...`
3. Shows "Tap to Open App" button
4. **For iOS in-app browsers:** Shows button immediately (iOS blocks auto-redirects)
5. **For other browsers:** Tries auto-opening after 300ms delay
6. If app doesn't open within 2 seconds → shows fallback options

**Fallback options:**
- "Open in Safari" (for iOS)
- "Continue on Web" (redirects to home)

---

### **Step 8: Deep Link Opens Flutter App**

**Location:** `flutter/lib/main.dart`

**What happens:**
1. `app_links` package receives deep link: `compostkaki://reset-password#...`
2. Parses tokens from hash fragment
3. Navigates to `/reset-password` route with tokens as query parameters
4. `ResetPasswordScreen` receives tokens

**Code:**
```dart
void _processDeepLink(Uri uri) {
  if (uri.scheme == 'compostkaki' && uri.host == 'reset-password') {
    final hash = uri.fragment // type=recovery&access_token=...&refresh_token=...
    final route = '/reset-password?$hash' // Convert hash to query params
    AppRouter.router.go(route)
  }
}
```

---

### **Step 9: Flutter App Sets Recovery Session**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**What happens:**
1. `ResetPasswordScreen` loads
2. `_handleDeepLink()` extracts tokens from route query parameters
3. Calls `AuthService.setRecoverySession(accessToken, refreshToken)`
4. Sets Supabase session using `setSession()`
5. User can now enter new password

**Code:**
```dart
final accessToken = uri.queryParameters['access_token']
final refreshToken = uri.queryParameters['refresh_token']

if (type == 'recovery' && accessToken != null && refreshToken != null) {
  final authService = context.read<AuthService>()
  await authService.setRecoverySession(accessToken, refreshToken)
}
```

---

### **Step 10: User Enters New Password**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**What happens:**
1. User enters new password and confirms it
2. Calls `AuthService.updatePasswordWithRecovery(newPassword)`
3. Supabase updates password and confirms email
4. User is logged in automatically
5. Navigates to main screen

**Code:**
```dart
await authService.updatePasswordWithRecovery(newPassword)
// Password updated, user logged in
context.go('/main')
```

---

## Key Design Decisions

### **1. Multi-Layer Token Interception**
- **Server-side middleware** catches tokens before React loads
- **Client-side home page** catches tokens as backup
- **Reset password page** handles tokens and errors

### **2. Server-Side Verification API**
- Uses Supabase Admin API to bypass redirect URL matching
- Handles cases where Supabase redirects with token instead of hash
- Creates recovery session server-side

### **3. Deep Linking**
- Custom URL scheme: `compostkaki://reset-password`
- Tokens passed in hash fragment (not query params)
- Converted to query params for Flutter app

### **4. "Tap to Open App" Button**
- Required for iOS (blocks auto-redirects)
- Shows immediately for iOS in-app browsers
- Auto-opens for other browsers with fallback

### **5. Error Handling**
- Errors detected at multiple points (middleware, home page, reset page)
- User-friendly error messages displayed
- Errors passed through URL hash/query params

---

## Files Involved

1. **Flutter:**
   - `flutter/lib/services/auth_service.dart` - Password reset request
   - `flutter/lib/main.dart` - Deep link handling
   - `flutter/lib/router/app_router.dart` - Route configuration
   - `flutter/lib/screens/auth/reset_password_screen.dart` - Password reset UI

2. **Next.js:**
   - `middleware.ts` - Server-side token interception
   - `app/page.tsx` - Client-side token interception
   - `app/reset-password/page.tsx` - Reset password page
   - `app/api/auth/verify-recovery/route.ts` - Server-side token verification

3. **Configuration:**
   - `flutter/ios/Runner/Info.plist` - iOS deep link scheme
   - `flutter/android/app/src/main/AndroidManifest.xml` - Android deep link intent

---

## Current Issues & Solutions

### **Issue: `access_denied` Error**
**Cause:** Supabase rejecting token verification
**Solution:** Using server-side Admin API to bypass redirect URL checks

### **Issue: Double Verification**
**Cause:** Token verified twice (email link + API)
**Solution:** Only verify once - read tokens from hash if already verified

### **Issue: iOS Deep Links Not Opening**
**Cause:** iOS blocks auto-redirects from in-app browsers
**Solution:** "Tap to Open App" button with user gesture

---

## Testing Checklist

- [ ] Request password reset from Flutter app
- [ ] Check email link format
- [ ] Click email link (should go to reset-password page)
- [ ] Verify "Tap to Open App" button appears
- [ ] Click button (should open Flutter app)
- [ ] Verify password reset screen loads
- [ ] Enter new password
- [ ] Verify password is updated and user is logged in
- [ ] Test error cases (expired token, invalid token)

