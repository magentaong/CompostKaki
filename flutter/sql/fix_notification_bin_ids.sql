-- Fix existing notifications that have NULL bin_id
-- This script backfills bin_id from the reference_id (message_id, activity_id, etc.)

-- Fix message notifications: Get bin_id from bin_messages table
UPDATE user_notifications un
SET bin_id = bm.bin_id
FROM bin_messages bm
WHERE un.type = 'message'
  AND un.bin_id IS NULL
  AND un.reference_id = bm.id;

-- Fix activity notifications: Get bin_id from bin_logs table
UPDATE user_notifications un
SET bin_id = bl.bin_id
FROM bin_logs bl
WHERE un.type = 'activity'
  AND un.bin_id IS NULL
  AND un.reference_id = bl.id;

-- Fix join_request notifications: Get bin_id from bin_requests table
UPDATE user_notifications un
SET bin_id = br.bin_id
FROM bin_requests br
WHERE un.type = 'join_request'
  AND un.bin_id IS NULL
  AND un.reference_id = br.id;

-- Fix help_request notifications: Get bin_id from tasks table
UPDATE user_notifications un
SET bin_id = t.bin_id
FROM tasks t
WHERE un.type = 'help_request'
  AND un.bin_id IS NULL
  AND un.reference_id = t.id;

-- Fix bin_health notifications: bin_id should be in reference_id (it's the bin_id itself)
UPDATE user_notifications un
SET bin_id = un.reference_id
WHERE un.type = 'bin_health'
  AND un.bin_id IS NULL
  AND un.reference_id IS NOT NULL;

-- Show summary of fixes
SELECT 
  type,
  COUNT(*) FILTER (WHERE bin_id IS NULL) as still_null,
  COUNT(*) FILTER (WHERE bin_id IS NOT NULL) as has_bin_id,
  COUNT(*) as total
FROM user_notifications
GROUP BY type
ORDER BY type;

