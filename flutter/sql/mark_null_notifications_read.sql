-- Mark all notifications with NULL bin_id as read
-- This will hide them from badges since we can't determine which bin they belong to
-- New notifications will be created properly with bin_id

UPDATE user_notifications
SET is_read = true
WHERE bin_id IS NULL;

-- Verify the update
SELECT 
  type,
  COUNT(*) FILTER (WHERE bin_id IS NULL AND is_read = true) as marked_read,
  COUNT(*) FILTER (WHERE bin_id IS NULL AND is_read = false) as still_unread,
  COUNT(*) FILTER (WHERE bin_id IS NOT NULL) as has_bin_id
FROM user_notifications
GROUP BY type;

