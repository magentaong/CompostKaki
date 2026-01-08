-- Update password_reset_otps table to allow multiple OTPs per email
-- This migration changes the schema to support multiple OTP requests
-- Works whether the old table exists or not

-- Step 1: Create new table structure with ID as primary key
CREATE TABLE IF NOT EXISTS password_reset_otps_new (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ NULL
);

-- Step 2: Copy existing data (if old table exists)
-- Use DO block to check if table exists before copying
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'password_reset_otps'
  ) THEN
    -- Old table exists, copy data
    INSERT INTO password_reset_otps_new (email, otp_code, expires_at, created_at)
    SELECT email, otp_code, expires_at, created_at
    FROM password_reset_otps;
  END IF;
END $$;

-- Step 3: Drop old table (if it exists)
DROP TABLE IF EXISTS password_reset_otps;

-- Step 4: Rename new table to original name
ALTER TABLE password_reset_otps_new RENAME TO password_reset_otps;

-- Step 5: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email ON password_reset_otps(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_expires_at ON password_reset_otps(expires_at);
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email_created ON password_reset_otps(email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_unused ON password_reset_otps(email, expires_at) WHERE used_at IS NULL;

-- Step 6: Re-enable RLS
ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;

-- Step 7: Recreate RLS policy
DROP POLICY IF EXISTS "Service role can manage OTPs" ON password_reset_otps;
CREATE POLICY "Service role can manage OTPs"
  ON password_reset_otps
  FOR ALL
  USING (true)
  WITH CHECK (true);
