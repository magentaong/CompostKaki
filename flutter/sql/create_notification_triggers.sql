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

CREATE TRIGGER notify_help_request
  AFTER INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notify_help_request();

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
COMMENT ON FUNCTION trigger_notify_bin_health IS 'Trigger function to notify bin members when bin health deteriorates.';

