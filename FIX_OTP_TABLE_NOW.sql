-- QUICK FIX: Run this in Supabase SQL Editor to create the table
-- This will work whether the table exists or not

-- Drop table if it exists (to start fresh)
DROP TABLE IF EXISTS password_reset_otps;

-- Create table with correct structure (supports multiple OTPs per email)
CREATE TABLE password_reset_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_password_reset_otps_email ON password_reset_otps(email);
CREATE INDEX idx_password_reset_otps_expires_at ON password_reset_otps(expires_at);
CREATE INDEX idx_password_reset_otps_email_created ON password_reset_otps(email, created_at DESC);
CREATE INDEX idx_password_reset_otps_unused ON password_reset_otps(email, expires_at) WHERE used_at IS NULL;

-- Enable RLS
ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;

-- Create RLS policy
DROP POLICY IF EXISTS "Service role can manage OTPs" ON password_reset_otps;
CREATE POLICY "Service role can manage OTPs"
  ON password_reset_otps
  FOR ALL
  USING (true)
  WITH CHECK (true);
