# Debug OTP Verification Issue

## Quick Check: Verify Table Structure

Run this in Supabase SQL Editor to check if the table has the correct structure:

```sql
-- Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'password_reset_otps'
ORDER BY ordinal_position;
```

**Expected columns:**
- `id` (uuid)
- `email` (text)
- `otp_code` (text)
- `expires_at` (timestamptz)
- `created_at` (timestamptz)
- `used_at` (timestamptz, nullable)

## Check Recent OTPs

Run this to see what OTPs are in the database:

```sql
-- Check recent OTPs for your email
SELECT 
  id,
  email,
  otp_code,
  expires_at,
  created_at,
  used_at,
  CASE 
    WHEN used_at IS NOT NULL THEN 'USED'
    WHEN expires_at < NOW() THEN 'EXPIRED'
    ELSE 'VALID'
  END as status
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'  -- Replace with your email (lowercase)
ORDER BY created_at DESC
LIMIT 10;
```

## Common Issues

### Issue 1: Email Case Mismatch
**Problem**: Email stored as `Ong.Sihui1@gmail.com` but verified as `ong.sihui1@gmail.com`

**Fix**: The code normalizes emails to lowercase, but check if old OTPs were stored with different casing.

**Check**:
```sql
SELECT DISTINCT email FROM password_reset_otps;
```

### Issue 2: OTP Code Type Mismatch
**Problem**: OTP stored as number but compared as string (or vice versa)

**Fix**: The code converts OTP to string with `.toString().trim()`, but verify the stored value.

**Check**:
```sql
SELECT 
  otp_code,
  typeof(otp_code) as type,
  length(otp_code) as length
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
ORDER BY created_at DESC
LIMIT 1;
```

### Issue 3: OTP Already Used
**Problem**: OTP was already verified and marked as used

**Check**:
```sql
SELECT 
  otp_code,
  used_at,
  created_at
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
  AND otp_code = '589005'  -- Replace with your OTP
ORDER BY created_at DESC
LIMIT 1;
```

### Issue 4: OTP Expired
**Problem**: OTP expired (10 minutes)

**Check**:
```sql
SELECT 
  otp_code,
  expires_at,
  NOW() as current_time,
  expires_at < NOW() as is_expired
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
  AND otp_code = '589005'  -- Replace with your OTP
ORDER BY created_at DESC
LIMIT 1;
```

## Check Vercel Logs

After trying to verify OTP, check Vercel function logs:

1. Go to **Vercel Dashboard** → Your Project → **Functions**
2. Click on `/api/auth/verify-reset-otp`
3. Look for logs starting with `🔐 [VERIFY OTP]`

You should see:
- Email and OTP being verified
- Number of OTPs found for that email
- Recent OTPs with their status
- Whether a matching OTP was found

## Manual Test Query

Test the exact query the API uses:

```sql
-- This is the exact query the API runs
SELECT *
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'  -- lowercase!
  AND otp_code = '589005'  -- Your OTP code
  AND used_at IS NULL  -- Not used
  AND expires_at > NOW()  -- Not expired
ORDER BY created_at DESC
LIMIT 1;
```

If this returns no rows, check:
1. Is the email exactly `ong.sihui1@gmail.com` (lowercase)?
2. Is the OTP code exactly `589005` (no spaces)?
3. Is `used_at` NULL?
4. Is `expires_at` in the future?

## Next Steps

1. **Run the check queries above** to see what's in the database
2. **Check Vercel logs** after trying to verify OTP
3. **Share the results** so we can identify the exact issue

## Quick Fix: Test with Fresh OTP

1. Request a NEW OTP
2. Immediately check the database:
   ```sql
   SELECT * FROM password_reset_otps 
   WHERE email = 'ong.sihui1@gmail.com' 
   ORDER BY created_at DESC LIMIT 1;
   ```
3. Copy the exact `otp_code` value
4. Try verifying with that exact code
5. Check Vercel logs to see what happened
