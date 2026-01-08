-- Check timezone and OTP data
-- Run this in Supabase SQL Editor

-- Check current timezone settings
SHOW timezone;

-- Check OTPs with timezone info
SELECT 
  id,
  email,
  otp_code,
  expires_at,
  created_at,
  used_at,
  NOW() as current_time_utc,
  expires_at < NOW() as is_expired,
  used_at IS NOT NULL as is_used,
  CASE 
    WHEN used_at IS NOT NULL THEN 'USED'
    WHEN expires_at < NOW() THEN 'EXPIRED'
    ELSE 'VALID'
  END as status
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
ORDER BY created_at DESC
LIMIT 5;

-- Test the exact query the API uses
SELECT *
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
  AND otp_code = '428986'
  AND used_at IS NULL
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;

-- Check if OTP exists at all (ignore used_at and expires_at)
SELECT *
FROM password_reset_otps
WHERE email = 'ong.sihui1@gmail.com'
  AND otp_code = '428986'
ORDER BY created_at DESC
LIMIT 1;
