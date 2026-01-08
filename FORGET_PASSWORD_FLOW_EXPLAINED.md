# Forget Password Flow - Complete Implementation Guide

## Overview
The forget password feature uses a **3-step OTP-based flow** entirely within the Flutter mobile app.

---

## Step-by-Step Flow

### **Step 1: User Requests OTP**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**User Action:**
1. Opens app → Navigate to Reset Password
2. Enters email address (e.g., `ong.sihui1@gmail.com`)
3. Taps "Send OTP Code"

**App Flow:**
```
ResetPasswordScreen._requestOTP()
  ↓
AuthService.requestPasswordResetOTP(email)
  ↓
POST https://compostkaki.vercel.app/api/auth/send-reset-otp
  Body: { email: "ong.sihui1@gmail.com" }
```

**Backend (`/api/auth/send-reset-otp`):**
1. ✅ Normalizes email to lowercase: `ong.sihui1@gmail.com`
2. ✅ Checks rate limiting (30 seconds between requests)
3. ✅ Generates 6-digit OTP (e.g., `428986`)
4. ✅ Stores in database:
   ```sql
   INSERT INTO password_reset_otps (
     email, 
     otp_code, 
     expires_at, 
     created_at
   ) VALUES (
     'ong.sihui1@gmail.com',
     '428986',
     NOW() + 10 minutes,
     NOW()
   )
   ```
5. ✅ Sends email via SendGrid with OTP code
6. ✅ Returns success

**Response:**
```json
{
  "success": true,
  "message": "OTP code sent to your email. Please check your inbox."
}
```

**App Updates:**
- Shows success message
- Moves to Step 2: OTP Entry screen

---

### **Step 2: User Enters OTP Code**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**User Action:**
1. Checks email for 6-digit code (e.g., `428986`)
2. Enters code in app
3. Taps "Verify OTP"

**App Flow:**
```
ResetPasswordScreen._verifyOTP()
  ↓
AuthService.verifyPasswordResetOTP(email, otpCode)
  ↓
POST https://compostkaki.vercel.app/api/auth/verify-reset-otp
  Body: { 
    email: "ong.sihui1@gmail.com",
    otpCode: "428986"
  }
```

**Backend (`/api/auth/verify-reset-otp`):**
1. ✅ Normalizes email to lowercase
2. ✅ Queries database for matching OTP:
   ```sql
   SELECT * FROM password_reset_otps
   WHERE email = 'ong.sihui1@gmail.com'
     AND otp_code = '428986'
     AND used_at IS NULL        -- Not used yet
     AND expires_at > NOW()     -- Not expired (UTC timezone)
   ORDER BY created_at DESC
   LIMIT 1
   ```
3. ✅ If OTP not found:
   - Checks if OTP exists but is used → Returns "OTP already used"
   - Checks if OTP exists but expired → Returns "OTP expired"
   - Otherwise → Returns "Invalid OTP code"
4. ✅ If OTP found:
   - Verifies user exists in Supabase
   - Generates recovery link using `admin.generateLink()`
   - Extracts recovery token
   - Verifies token to get session
   - **Marks OTP as used**: `UPDATE password_reset_otps SET used_at = NOW() WHERE id = ...`
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
- If success:
  - Sets Supabase session using tokens
  - Moves to Step 3: New Password screen
- If failure:
  - Shows error message
  - User can request new OTP

---

### **Step 3: User Sets New Password**

**Location:** `flutter/lib/screens/auth/reset_password_screen.dart`

**User Action:**
1. Enters new password
2. Confirms new password
3. Taps "Reset Password"

**App Flow:**
```
ResetPasswordScreen._resetPassword()
  ↓
AuthService.updatePassword(newPassword)
  ↓
Supabase Client: auth.updateUser({ password: newPassword })
```

**Backend (Supabase):**
- Updates user password (requires active session from Step 2)
- Session is already set, so password update succeeds

**App Updates:**
- Shows success message
- Navigates to main screen
- User is logged in with new password

---

## Database Schema

**Table:** `password_reset_otps`

```sql
CREATE TABLE password_reset_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,  -- UTC timezone
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ NULL          -- NULL = not used, timestamp = used
);
```

**Indexes:**
- `idx_password_reset_otps_email` on `email`
- `idx_password_reset_otps_expires_at` on `expires_at`
- `idx_password_reset_otps_email_created` on `email, created_at DESC`
- `idx_password_reset_otps_unused` on `email, expires_at` WHERE `used_at IS NULL`

---

## Key Features

### 1. **Multiple OTPs Per Email**
- ✅ Users can request multiple OTPs
- ✅ Each OTP is stored separately
- ✅ Only the most recent unused, non-expired OTP is checked

### 2. **Rate Limiting**
- ✅ Prevents requesting new OTP within 30 seconds
- ✅ Returns error: "Please wait X seconds before requesting another OTP code"

### 3. **Email Normalization**
- ✅ All emails converted to lowercase
- ✅ Prevents case-sensitivity issues

### 4. **Timezone Handling**
- ✅ All timestamps stored in UTC (`TIMESTAMPTZ`)
- ✅ Comparisons use UTC ISO strings
- ✅ No timezone conversion issues

### 5. **OTP Expiration**
- ✅ OTPs expire after 10 minutes
- ✅ Expired OTPs are automatically filtered out

### 6. **OTP Usage Tracking**
- ✅ OTPs marked as used (not deleted)
- ✅ Prevents reuse of OTP codes
- ✅ Audit trail maintained

---

## Troubleshooting

### Issue: "Invalid OTP code"

**Possible Causes:**
1. **OTP already used** - Check `used_at` column in database
2. **OTP expired** - Check `expires_at` vs current time
3. **Email mismatch** - Ensure email is normalized to lowercase
4. **OTP code typo** - Verify exact code from email
5. **Timezone issue** - Check Vercel logs for timezone comparison

**Check Vercel Logs:**
1. Go to Vercel Dashboard → Functions → `/api/auth/verify-reset-otp`
2. Look for logs starting with `🔐 [VERIFY OTP]`
3. Check:
   - Current time (UTC)
   - OTP expiration time
   - Whether OTP is used
   - Whether OTP is expired

**Check Database:**
```sql
SELECT 
  id,
  email,
  otp_code,
  expires_at,
  created_at,
  used_at,
  NOW() as current_time,
  expires_at < NOW() as is_expired,
  used_at IS NOT NULL as is_used
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
ORDER BY created_at DESC
LIMIT 5;
```

### Issue: "OTP already used"

**Solution:**
- Request a new OTP code
- The old OTP cannot be reused

### Issue: "OTP expired"

**Solution:**
- Request a new OTP code
- OTPs expire after 10 minutes

### Issue: Rate Limiting

**Solution:**
- Wait 30 seconds between OTP requests
- Error message shows remaining wait time

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

**Response (Rate Limited):**
```json
{
  "error": "Please wait 30 seconds before requesting another OTP code."
}
```

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

**Response (Failure):**
```json
{
  "error": "Invalid OTP code"
}
```

---

## Testing Checklist

- [ ] Request OTP → Email received
- [ ] Enter correct OTP → Verification succeeds
- [ ] Enter wrong OTP → Error shown
- [ ] Enter expired OTP → Error shown
- [ ] Enter used OTP → Error shown
- [ ] Request OTP twice within 30s → Rate limit error
- [ ] Request OTP after 30s → Success
- [ ] Verify OTP → Session created
- [ ] Set new password → Password updated
- [ ] Login with new password → Success

---

## Status
✅ All features implemented
✅ Timezone handling fixed
✅ Detailed logging added
✅ Ready for testing
