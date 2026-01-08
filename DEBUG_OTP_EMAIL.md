# Debug: Why OTP Emails Aren't Being Sent

## Most Likely Issues

### 1. Database Table Doesn't Exist ⚠️ **MOST LIKELY**
The `password_reset_otps` table needs to be created first.

**Fix:**
1. Go to Supabase Dashboard → SQL Editor
2. Run this SQL:
```sql
-- Create password_reset_otps table for storing OTP codes
CREATE TABLE IF NOT EXISTS password_reset_otps (
  email TEXT PRIMARY KEY,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on expires_at for cleanup queries
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_expires_at ON password_reset_otps(expires_at);

-- Add RLS policies
ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;

-- Drop policy if it exists, then create it
DROP POLICY IF EXISTS "Service role can manage OTPs" ON password_reset_otps;
CREATE POLICY "Service role can manage OTPs"
  ON password_reset_otps
  FOR ALL
  USING (true)
  WITH CHECK (true);
```

### 2. API Route Not Deployed Yet
The new API routes need to be deployed to Vercel.

**Check:**
1. Go to Vercel Dashboard → Your Project → Deployments
2. Make sure the latest deployment includes the new API routes
3. If not, push a new commit or manually redeploy

### 3. SendGrid API Key Not in Vercel
Even though you've received emails before, the new API route needs the key.

**Check:**
1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Look for `SENDGRID_API_KEY`
3. If missing, add it (see VERCEL_ENV_SETUP.md)
4. **Redeploy after adding**

### 4. Check Vercel Function Logs
The API route now returns proper error messages. Check the logs:

1. Go to Vercel Dashboard → Your Project → Functions
2. Click on `/api/auth/send-reset-otp`
3. Check the logs for errors

**Common errors you might see:**
- `Database table not found` → Run the SQL migration
- `SENDGRID_API_KEY not configured` → Add to Vercel env vars
- `SendGrid error: 401` → Invalid API key
- `SendGrid error: 403` → API key doesn't have permissions

## Quick Test Steps

1. **Run the SQL migration** (most important!)
2. **Check Vercel logs** when you request OTP
3. **Check SendGrid Activity Feed** to see if email was attempted
4. **Check your spam folder**

## What Changed

The old flow used Supabase's built-in `resetPasswordForEmail` which sent emails directly.

The new flow:
1. Calls custom API `/api/auth/send-reset-otp`
2. API stores OTP in database (needs `password_reset_otps` table)
3. API sends email via SendGrid

So you need:
- ✅ Database table (run migration)
- ✅ SendGrid API key in Vercel (if not already there)
- ✅ API route deployed

