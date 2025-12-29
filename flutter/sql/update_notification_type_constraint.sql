-- Update the CHECK constraint on user_notifications.type to include task_accepted and task_reverted
-- This script should be idempotent

-- First, drop the existing constraint if it exists
ALTER TABLE user_notifications 
DROP CONSTRAINT IF EXISTS user_notifications_type_check;

-- Add the updated constraint with all notification types
ALTER TABLE user_notifications 
ADD CONSTRAINT user_notifications_type_check 
CHECK (type IN (
  'message', 
  'join_request', 
  'activity', 
  'help_request', 
  'bin_health', 
  'task_completed', 
  'task_accepted', 
  'task_reverted'
));

