-- Add task_completed notification type support
-- This script updates the database to support task completion notifications

-- 1. Update notification type constraint to include 'task_completed'
ALTER TABLE user_notifications
DROP CONSTRAINT IF EXISTS user_notifications_type_check;

ALTER TABLE user_notifications
ADD CONSTRAINT user_notifications_type_check 
CHECK (type IN ('message', 'join_request', 'activity', 'help_request', 'bin_health', 'task_completed'));

-- 2. Add new columns to notification_preferences table
ALTER TABLE notification_preferences
ADD COLUMN IF NOT EXISTS push_task_completed BOOLEAN DEFAULT true;

ALTER TABLE notification_preferences
ADD COLUMN IF NOT EXISTS badge_task_completed BOOLEAN DEFAULT true;

-- 3. Update existing preferences to have default values
UPDATE notification_preferences
SET 
  push_task_completed = COALESCE(push_task_completed, true),
  badge_task_completed = COALESCE(badge_task_completed, true)
WHERE push_task_completed IS NULL OR badge_task_completed IS NULL;

-- 4. Create the trigger function for task completion notifications
CREATE OR REPLACE FUNCTION trigger_notify_task_completion()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  completer_name TEXT;
  task_owner_id UUID;
BEGIN
  -- Only notify when status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Get task owner (user_id is the creator/owner of the task)
    task_owner_id := NEW.user_id;
    
    -- Get bin name
    SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
    
    -- Get completer name (the person who completed it - accepted_by)
    IF NEW.accepted_by IS NOT NULL THEN
      SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO completer_name
      FROM profiles WHERE id = NEW.accepted_by;
    ELSE
      completer_name := 'Someone';
    END IF;
    
    -- Notify task owner only (not the completer)
    IF task_owner_id IS NOT NULL AND task_owner_id != NEW.accepted_by THEN
      -- Check if owner has notification preference enabled
      IF EXISTS (
        SELECT 1 FROM notification_preferences np
        WHERE np.user_id = task_owner_id
        AND (
          (np.badge_task_completed = true)
        )
      ) OR NOT EXISTS (
        SELECT 1 FROM notification_preferences WHERE user_id = task_owner_id
      ) THEN
        -- Default preferences: enabled
        INSERT INTO user_notifications (user_id, type, reference_id, bin_id, title, body)
        VALUES (
          task_owner_id,
          'task_completed',
          NEW.id,
          NEW.bin_id,
          COALESCE(bin_name, 'Bin'),
          COALESCE(completer_name, 'Someone') || ' completed your task'
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for task completion
DROP TRIGGER IF EXISTS notify_task_completion ON tasks;
CREATE TRIGGER notify_task_completion
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed')
  EXECUTE FUNCTION trigger_notify_task_completion();

-- 6. Update push notification trigger to handle task_completed type
-- This is already handled in setup_push_notification_trigger.sql, but verify it includes:
-- WHEN 'task_completed' THEN COALESCE((SELECT push_task_completed FROM notification_preferences WHERE user_id = NEW.user_id), true)

COMMENT ON FUNCTION trigger_notify_task_completion IS 'Trigger function to notify task owner when task is completed.';

