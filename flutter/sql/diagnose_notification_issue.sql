-- Diagnostic query to understand why notifications have NULL bin_id

-- Check notifications without bin_id
SELECT 
  id,
  type,
  reference_id,
  bin_id,
  title,
  body,
  created_at
FROM user_notifications
WHERE bin_id IS NULL
ORDER BY created_at DESC
LIMIT 20;

-- Check if reference_ids exist in source tables
-- For messages
SELECT 
  un.id as notification_id,
  un.type,
  un.reference_id,
  un.bin_id,
  bm.id as message_exists,
  bm.bin_id as message_bin_id
FROM user_notifications un
LEFT JOIN bin_messages bm ON un.reference_id = bm.id
WHERE un.type = 'message' 
  AND un.bin_id IS NULL
LIMIT 10;

-- For activities
SELECT 
  un.id as notification_id,
  un.type,
  un.reference_id,
  un.bin_id,
  bl.id as log_exists,
  bl.bin_id as log_bin_id
FROM user_notifications un
LEFT JOIN bin_logs bl ON un.reference_id = bl.id
WHERE un.type = 'activity' 
  AND un.bin_id IS NULL
LIMIT 10;

