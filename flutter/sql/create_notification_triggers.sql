-- Create database triggers to automatically create notifications when events occur

-- Function to create notifications for bin members (excluding the actor)
CREATE OR REPLACE FUNCTION notify_bin_members(
  p_bin_id UUID,
  p_type TEXT,
  p_reference_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_exclude_user_id UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  member_record RECORD;
BEGIN
  -- Get all members of the bin (including owner)
  FOR member_record IN
    SELECT DISTINCT user_id
    FROM (
      SELECT user_id FROM bin_members WHERE bin_id = p_bin_id
      UNION
      SELECT user_id FROM bins WHERE id = p_bin_id
    ) AS all_members
    WHERE user_id != COALESCE(p_exclude_user_id, '00000000-0000-0000-0000-000000000000'::UUID)
  LOOP
    -- Check if user has notification preference enabled for this type
    IF EXISTS (
      SELECT 1 FROM notification_preferences np
      WHERE np.user_id = member_record.user_id
      AND (
        (p_type = 'message' AND np.badge_messages = true) OR
        (p_type = 'activity' AND np.badge_activities = true) OR
        (p_type = 'help_request' AND np.badge_help_requests = true) OR
        (p_type = 'bin_health' AND np.badge_bin_health = true)
      )
    ) OR NOT EXISTS (
      SELECT 1 FROM notification_preferences WHERE user_id = member_record.user_id
    ) THEN
      -- Default preferences: all enabled
      INSERT INTO user_notifications (user_id, type, reference_id, bin_id, title, body)
      VALUES (member_record.user_id, p_type, p_reference_id, p_bin_id, p_title, p_body);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to notify bin admin only
CREATE OR REPLACE FUNCTION notify_bin_admin(
  p_bin_id UUID,
  p_type TEXT,
  p_reference_id UUID,
  p_title TEXT,
  p_body TEXT
)
RETURNS void AS $$
DECLARE
  admin_user_id UUID;
BEGIN
  -- Get bin owner/admin
  SELECT user_id INTO admin_user_id
  FROM bins
  WHERE id = p_bin_id;

  IF admin_user_id IS NOT NULL THEN
    -- Check if admin has notification preference enabled
    IF EXISTS (
      SELECT 1 FROM notification_preferences np
      WHERE np.user_id = admin_user_id
      AND (
        (p_type = 'join_request' AND np.badge_join_requests = true)
      )
    ) OR NOT EXISTS (
      SELECT 1 FROM notification_preferences WHERE user_id = admin_user_id
    ) THEN
      -- Default preferences: enabled
      INSERT INTO user_notifications (user_id, type, reference_id, bin_id, title, body)
      VALUES (admin_user_id, p_type, p_reference_id, p_bin_id, p_title, p_body);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger: New message notification
CREATE OR REPLACE FUNCTION trigger_notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  sender_name TEXT;
BEGIN
  -- Get bin name
  SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
  
  -- Get sender name
  SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO sender_name
  FROM profiles WHERE id = NEW.sender_id;
  
  -- Notify all bin members except the sender
  PERFORM notify_bin_members(
    NEW.bin_id,
    'message',
    NEW.id,
    COALESCE(bin_name, 'Bin'),
    COALESCE(sender_name, 'Someone') || ' sent a message',
    NEW.sender_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_new_message ON bin_messages;
CREATE TRIGGER notify_new_message
  AFTER INSERT ON bin_messages
  FOR EACH ROW
  WHEN (NEW.is_deleted = false)
  EXECUTE FUNCTION trigger_notify_new_message();

-- Trigger: New join request notification (admin only)
CREATE OR REPLACE FUNCTION trigger_notify_join_request()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  requester_name TEXT;
BEGIN
  -- Only notify for pending requests
  IF NEW.status = 'pending' THEN
    -- Get bin name
    SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
    
    -- Get requester name
    SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO requester_name
    FROM profiles WHERE id = NEW.user_id;
    
    -- Notify bin admin only
    PERFORM notify_bin_admin(
      NEW.bin_id,
      'join_request',
      NEW.id,
      COALESCE(bin_name, 'Bin'),
      COALESCE(requester_name, 'Someone') || ' requested to join'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_join_request ON bin_requests;
CREATE TRIGGER notify_join_request
  AFTER INSERT ON bin_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notify_join_request();

-- Trigger: New activity notification
CREATE OR REPLACE FUNCTION trigger_notify_new_activity()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  logger_name TEXT;
  activity_type TEXT;
BEGIN
  -- Get bin name
  SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
  
  -- Get logger name
  SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO logger_name
  FROM profiles WHERE id = NEW.user_id;
  
  -- Get activity type
  activity_type := COALESCE(NEW.type, 'activity');
  
  -- Notify all bin members except the logger
  PERFORM notify_bin_members(
    NEW.bin_id,
    'activity',
    NEW.id,
    COALESCE(bin_name, 'Bin'),
    COALESCE(logger_name, 'Someone') || ' logged: ' || activity_type,
    NEW.user_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_new_activity ON bin_logs;
CREATE TRIGGER notify_new_activity
  AFTER INSERT ON bin_logs
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notify_new_activity();

-- Trigger: New help request notification
CREATE OR REPLACE FUNCTION trigger_notify_help_request()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  requester_name TEXT;
BEGIN
  -- Only notify for open tasks
  IF NEW.status = 'open' THEN
    -- Get bin name
    SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
    
    -- Get requester name
    SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO requester_name
    FROM profiles WHERE id = NEW.user_id;
    
    -- Notify all bin members except the requester
    PERFORM notify_bin_members(
      NEW.bin_id,
      'help_request',
      NEW.id,
      COALESCE(bin_name, 'Bin'),
      COALESCE(requester_name, 'Someone') || ' requested help',
      NEW.user_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_help_request ON tasks;
CREATE TRIGGER notify_help_request
  AFTER INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notify_help_request();

-- Trigger: Task accepted notification (notify task owner)
CREATE OR REPLACE FUNCTION trigger_notify_task_accepted()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  accepter_name TEXT;
  task_owner_id UUID;
BEGIN
  -- Only notify when status changes to 'accepted'
  IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
    -- Get task owner (user_id is the creator/owner of the task)
    task_owner_id := NEW.user_id;
    
    -- Get bin name
    SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
    
    -- Get accepter name (the person who accepted it - accepted_by)
    IF NEW.accepted_by IS NOT NULL THEN
      SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO accepter_name
      FROM profiles WHERE id = NEW.accepted_by;
    ELSE
      accepter_name := 'Someone';
    END IF;
    
    -- Notify task owner only (not the accepter)
    IF task_owner_id IS NOT NULL AND task_owner_id != NEW.accepted_by THEN
      -- Check if owner has notification preference enabled
      IF EXISTS (
        SELECT 1 FROM notification_preferences np
        WHERE np.user_id = task_owner_id
        AND (
          (np.badge_task_completed = true) -- Use task_completed preference for task-related notifications
        )
      ) OR NOT EXISTS (
        SELECT 1 FROM notification_preferences WHERE user_id = task_owner_id
      ) THEN
        -- Default preferences: enabled
        INSERT INTO user_notifications (user_id, type, reference_id, bin_id, title, body)
        VALUES (
          task_owner_id,
          'task_accepted',
          NEW.id,
          NEW.bin_id,
          COALESCE(bin_name, 'Bin'),
          COALESCE(accepter_name, 'Someone') || ' accepted your task'
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_task_accepted ON tasks;
CREATE TRIGGER notify_task_accepted
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'accepted')
  EXECUTE FUNCTION trigger_notify_task_accepted();

-- Trigger: Task completion notification (notify task owner)
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
          (np.badge_task_completed = true) -- Use task_completed preference for task-related notifications
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

DROP TRIGGER IF EXISTS notify_task_completion ON tasks;
CREATE TRIGGER notify_task_completion
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed')
  EXECUTE FUNCTION trigger_notify_task_completion();

-- Trigger: Task reverted notification (notify completer)
CREATE OR REPLACE FUNCTION trigger_notify_task_reverted()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  task_owner_name TEXT;
  completer_id UUID;
BEGIN
  -- Only notify when completion_status changes to 'reverted'
  IF NEW.completion_status = 'reverted' AND (OLD.completion_status IS NULL OR OLD.completion_status != 'reverted') THEN
    -- Get completer (the person who completed it - accepted_by before revert)
    completer_id := OLD.accepted_by;
    
    -- Get bin name
    SELECT name INTO bin_name FROM bins WHERE id = NEW.bin_id;
    
    -- Get task owner name
    IF NEW.user_id IS NOT NULL THEN
      SELECT COALESCE(first_name || ' ' || last_name, 'Task owner') INTO task_owner_name
      FROM profiles WHERE id = NEW.user_id;
    ELSE
      task_owner_name := 'Task owner';
    END IF;
    
    -- Notify completer only (not the task owner)
    IF completer_id IS NOT NULL AND completer_id != NEW.user_id THEN
      -- Check if completer has notification preference enabled
      IF EXISTS (
        SELECT 1 FROM notification_preferences np
        WHERE np.user_id = completer_id
        AND (
          (np.badge_task_completed = true) -- Use task_completed preference for task-related notifications
        )
      ) OR NOT EXISTS (
        SELECT 1 FROM notification_preferences WHERE user_id = completer_id
      ) THEN
        -- Default preferences: enabled
        INSERT INTO user_notifications (user_id, type, reference_id, bin_id, title, body)
        VALUES (
          completer_id,
          'task_reverted',
          NEW.id,
          NEW.bin_id,
          COALESCE(bin_name, 'Bin'),
          'Your task completion was reverted by ' || COALESCE(task_owner_name, 'task owner') || '. XP has been subtracted.'
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_task_reverted ON tasks;
CREATE TRIGGER notify_task_reverted
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.completion_status IS DISTINCT FROM NEW.completion_status AND NEW.completion_status = 'reverted')
  EXECUTE FUNCTION trigger_notify_task_reverted();

-- Trigger: Bin health deterioration notification
CREATE OR REPLACE FUNCTION trigger_notify_bin_health()
RETURNS TRIGGER AS $$
DECLARE
  bin_name TEXT;
  old_status TEXT;
  new_status TEXT;
BEGIN
  -- Only notify if health status changed and worsened
  old_status := COALESCE(OLD.health_status, 'Healthy');
  new_status := COALESCE(NEW.health_status, 'Healthy');
  
  -- Check if status worsened (Healthy -> Needs Attention -> Critical)
  IF (old_status = 'Healthy' AND new_status IN ('Needs Attention', 'Critical')) OR
     (old_status = 'Needs Attention' AND new_status = 'Critical') THEN
    
    -- Get bin name
    bin_name := COALESCE(NEW.name, 'Bin');
    
    -- Notify all bin members
    PERFORM notify_bin_members(
      NEW.id,
      'bin_health',
      NEW.id,
      bin_name,
      bin_name || ' health status: ' || new_status
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_bin_health ON bins;
CREATE TRIGGER notify_bin_health
  AFTER UPDATE ON bins
  FOR EACH ROW
  WHEN (OLD.health_status IS DISTINCT FROM NEW.health_status)
  EXECUTE FUNCTION trigger_notify_bin_health();

-- Comments
COMMENT ON FUNCTION notify_bin_members IS 'Creates notifications for all bin members (excluding specified user).';
COMMENT ON FUNCTION notify_bin_admin IS 'Creates notification for bin admin/owner only.';
COMMENT ON FUNCTION trigger_notify_new_message IS 'Trigger function to notify bin members of new messages.';
COMMENT ON FUNCTION trigger_notify_join_request IS 'Trigger function to notify bin admin of new join requests.';
COMMENT ON FUNCTION trigger_notify_new_activity IS 'Trigger function to notify bin members of new activities.';
COMMENT ON FUNCTION trigger_notify_help_request IS 'Trigger function to notify bin members of new help requests.';
COMMENT ON FUNCTION trigger_notify_task_accepted IS 'Trigger function to notify task owner when task is accepted.';
COMMENT ON FUNCTION trigger_notify_task_completion IS 'Trigger function to notify task owner when task is completed.';
COMMENT ON FUNCTION trigger_notify_task_reverted IS 'Trigger function to notify completer when task completion is reverted.';
COMMENT ON FUNCTION trigger_notify_bin_health IS 'Trigger function to notify bin members when bin health deteriorates.';

