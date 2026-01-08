-- Check if used_at column exists in password_reset_otps table
-- Run this in Supabase SQL Editor

-- Check table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'password_reset_otps'
ORDER BY ordinal_position;

-- Check if used_at column exists
SELECT EXISTS (
  SELECT 1 
  FROM information_schema.columns 
  WHERE table_schema = 'public' 
    AND table_name = 'password_reset_otps' 
    AND column_name = 'used_at'
) as has_used_at_column;

-- Check current OTPs
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
WHERE email = 'ong.sihui1@gmail.com'
ORDER BY created_at DESC;
