# Complete Forget Password Flow - OTP Based

## Overview
The password reset flow uses a **3-step OTP (One-Time Password) process** entirely within the mobile app. No web app redirects or deep links needed.

## Architecture

### Components
1. **Flutter App** (`flutter/lib/screens/auth/reset_password_screen.dart`)
   - 3-step UI: Email → OTP → New Password
   
2. **Backend API Routes** (Next.js/Vercel)
   - `/api/auth/send-reset-otp` - Generates and sends OTP
   - `/api/auth/verify-reset-otp` - Verifies OTP and creates recovery session

3. **Database** (Supabase)
   - `password_reset_otps` table - Stores OTP codes temporarily

4. **Email Service** (SendGrid)
   - Sends OTP codes via email

---

## Step-by-Step Flow

### Step 1: User Requests Password Reset

**User Action:**
- Opens app → Profile → Settings → Reset Password
- Enters email address
- Taps "Send OTP Code"

**App Flow:**
```
ResetPasswordScreen (Step 0: Email)
  ↓
AuthService.requestPasswordResetOTP(email)
  ↓
POST https://compostkaki.vercel.app/api/auth/send-reset-otp
  Body: { email: "user@example.com" }
```

**Backend (`/api/auth/send-reset-otp`):**
1. Validates email format
2. Generates 6-digit OTP code (e.g., `123456`)
3. Stores OTP in `password_reset_otps` table:
   ```sql
   INSERT INTO password_reset_otps (email, otp_code, expires_at)
   VALUES ('user@example.com', '123456', NOW() + 10 minutes)
   ```
4. Sends email via SendGrid with OTP code
5. Returns success (always, even if user doesn't exist - security)

**Email Sent:**
```
Subject: CompostKaki - Password Reset Code

Your password reset code is:
123456

Enter this code in the app to reset your password.
This code will expire in 10 minutes.
```

**Response:**
```json
{
  "success": true,
  "message": "OTP code sent to your email. Please check your inbox."
}
```

**App Updates:**
- Shows success message
- Moves to Step 1: OTP Entry

---

### Step 2: User Enters OTP Code

**User Action:**
- Checks email for 6-digit code
- Enters code in app
- Taps "Verify OTP"

**App Flow:**
```
ResetPasswordScreen (Step 1: OTP)
  ↓
AuthService.verifyPasswordResetOTP(email, otpCode)
  ↓
POST https://compostkaki.vercel.app/api/auth/verify-reset-otp
  Body: { 
    email: "user@example.com",
    otpCode: "123456"
  }
```

**Backend (`/api/auth/verify-reset-otp`):**
1. Validates email and OTP code
2. Checks OTP in database:
   ```sql
   SELECT * FROM password_reset_otps
   WHERE email = 'user@example.com' 
   AND otp_code = '123456'
   ```
3. Verifies OTP hasn't expired (10 minutes)
4. **Checks if user exists** (case-insensitive email match)
5. If user doesn't exist → Returns "Invalid OTP code" (generic error)
6. If user exists:
   - Generates Supabase recovery link using `admin.generateLink()`
   - Extracts recovery token from link
   - Verifies token to get session tokens
   - Deletes used OTP from database
   - Returns session tokens

**Response (Success):**
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "v1.abc123..."
}
```

**Response (Failure):**
```json
{
  "error": "Invalid OTP code"
}
```

**App Updates:**
- If success: Sets session using tokens → Moves to Step 2: New Password
- If failure: Shows error message

---

### Step 3: User Sets New Password

**User Action:**
- Enters new password
- Confirms new password
- Taps "Reset Password"

**App Flow:**
```
ResetPasswordScreen (Step 2: Password)
  ↓
AuthService.updatePassword(newPassword)
  ↓
Supabase Client: auth.updateUser({ password: newPassword })
```

**Backend (Supabase):**
- Updates user password (requires active session)
- Session is already set from Step 2

**App Updates:**
- Shows success message
- Signs out user
- Redirects to login screen
- User can now login with new password

---

## Security Features

### 1. Email Enumeration Prevention
- **Send OTP** always returns success, even if user doesn't exist
- Prevents attackers from discovering registered emails

### 2. OTP Expiration
- OTP codes expire after 10 minutes
- Prevents old codes from being used

### 3. One-Time Use
- OTP is deleted after successful verification
- Prevents reuse of OTP codes

### 4. User Verification
- User existence is checked during OTP verification
- Prevents creating sessions for non-existent users

### 5. Case-Insensitive Email Matching
- Email comparison is case-insensitive
- Handles "User@Example.com" vs "user@example.com"

---

## Database Schema

### `password_reset_otps` Table
```sql
CREATE TABLE password_reset_otps (
  email TEXT PRIMARY KEY,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Index:**
- `idx_password_reset_otps_expires_at` on `expires_at` (for cleanup queries)

**RLS Policy:**
- Service role can manage OTPs (for API routes)

---

## API Endpoints

### POST `/api/auth/send-reset-otp`

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "OTP code sent to your email. Please check your inbox."
}
```

**Response (Error):**
```json
{
  "error": "Valid email is required"
}
```

**Possible Errors:**
- `400`: Invalid email format
- `500`: Database error, SendGrid error, server configuration error

---

### POST `/api/auth/verify-reset-otp`

**Request:**
```json
{
  "email": "user@example.com",
  "otpCode": "123456"
}
```

**Response (Success):**
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "v1.abc123..."
}
```

**Response (Error):**
```json
{
  "error": "Invalid OTP code"
}
```

**Possible Errors:**
- `400`: Missing email/OTP, invalid OTP, expired OTP, user doesn't exist
- `500`: Failed to create recovery session, server configuration error

---

## Environment Variables Required

### Vercel Environment Variables
- `SENDGRID_API_KEY` - SendGrid API key for sending emails
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (for admin operations)

---

## Error Handling

### Common Errors

**1. "Failed to send password reset OTP"**
- **Cause**: Network error, API not deployed, SendGrid not configured
- **Fix**: Check network, verify API is deployed, add `SENDGRID_API_KEY` to Vercel

**2. "Invalid OTP code"**
- **Cause**: Wrong code, expired code, user doesn't exist
- **Fix**: Request new OTP, check email, verify user exists

**3. "OTP code has expired"**
- **Cause**: OTP older than 10 minutes
- **Fix**: Request new OTP

**4. "Database table not found"**
- **Cause**: `password_reset_otps` table doesn't exist
- **Fix**: Run SQL migration in Supabase

**5. "Email service not configured"**
- **Cause**: `SENDGRID_API_KEY` missing in Vercel
- **Fix**: Add SendGrid API key to Vercel environment variables

---

## Testing Checklist

- [ ] User can request OTP with valid email
- [ ] OTP email is received (check inbox and spam)
- [ ] OTP code is 6 digits
- [ ] User can verify correct OTP code
- [ ] User cannot verify wrong OTP code
- [ ] User cannot verify expired OTP code
- [ ] User can set new password after OTP verification
- [ ] User can login with new password
- [ ] Non-existent user gets generic success message (no email enumeration)
- [ ] OTP expires after 10 minutes
- [ ] OTP can only be used once

---

## Files Involved

### Flutter
- `flutter/lib/screens/auth/reset_password_screen.dart` - UI for 3-step flow
- `flutter/lib/services/auth_service.dart` - API calls and session management
- `flutter/lib/router/app_router.dart` - Navigation routes

### Backend
- `app/api/auth/send-reset-otp/route.ts` - Generate and send OTP
- `app/api/auth/verify-reset-otp/route.ts` - Verify OTP and create session

### Database
- `supabase/migrations/create_password_reset_otps.sql` - OTP storage table

---

## Current Status

✅ **Working:**
- OTP generation and storage
- Email sending via SendGrid
- OTP verification
- Password reset after verification

⚠️ **Known Issues:**
- User existence check might fail if `listUsers()` has pagination limits
- Need to ensure SendGrid API key is in Vercel environment variables

---

## Future Improvements

1. **Rate Limiting**: Limit OTP requests per email/IP
2. **OTP Cleanup**: Scheduled job to delete expired OTPs
3. **Email Templates**: Customize SendGrid email template
4. **SMS OTP**: Add SMS option as alternative to email
5. **Resend OTP**: Add "Resend OTP" button with cooldown

