-- Create password_reset_otps table for storing OTP codes
CREATE TABLE IF NOT EXISTS password_reset_otps (
  email TEXT PRIMARY KEY,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on expires_at for cleanup queries
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_expires_at ON password_reset_otps(expires_at);

-- Add RLS policies (optional - adjust based on your security needs)
ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;

-- Policy: Allow service role to manage OTPs (for API routes)
-- Note: Service role bypasses RLS, so this is mainly for documentation
-- Drop policy if it exists, then create it
DROP POLICY IF EXISTS "Service role can manage OTPs" ON password_reset_otps;
CREATE POLICY "Service role can manage OTPs"
  ON password_reset_otps
  FOR ALL
  USING (true)
  WITH CHECK (true);

