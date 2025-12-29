-- Fix double timezone conversion issue in bin_messages
-- Messages were stored with local time (Singapore UTC+8) but treated as UTC
-- Need to subtract 8 hours to correct them

-- Fix created_at timestamps (subtract 8 hours)
UPDATE bin_messages
SET created_at = created_at - INTERVAL '8 hours'
WHERE created_at IS NOT NULL;

-- Fix updated_at timestamps (subtract 8 hours)
UPDATE bin_messages
SET updated_at = updated_at - INTERVAL '8 hours'
WHERE updated_at IS NOT NULL;

-- Fix edited_at timestamps if they exist (subtract 8 hours)
UPDATE bin_messages
SET edited_at = edited_at - INTERVAL '8 hours'
WHERE edited_at IS NOT NULL;

-- Verify the fix
SELECT 
  id,
  message,
  created_at,
  updated_at,
  edited_at,
  created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Singapore' as created_at_sg
FROM bin_messages
ORDER BY created_at DESC
LIMIT 10;

