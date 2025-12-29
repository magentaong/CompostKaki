-- Setup push notification trigger to call Edge Function
-- This should be run AFTER deploying the Edge Function

-- Enable pg_net extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Function to send push notification via Edge Function
-- Replace 'your-project-ref' and 'your-supabase-anon-key' with actual values
CREATE OR REPLACE FUNCTION send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS void AS $$
DECLARE
  token_record RECORD;
  function_url TEXT;
  supabase_anon_key TEXT;
  push_enabled BOOLEAN;
BEGIN
  -- Check if user has push notifications enabled for this notification type
  -- (This is a simplified check - you may want to pass the notification type)
  SELECT COALESCE(
    (SELECT push_messages FROM notification_preferences WHERE user_id = p_user_id),
    true
  ) INTO push_enabled;
  
  -- Skip if push notifications are disabled
  IF NOT push_enabled THEN
    RETURN;
  END IF;
  
  -- Get Supabase project URL and anon key
  -- TODO: Replace these with your actual values
  -- You can find these in Supabase Dashboard → Project Settings → API
  function_url := 'https://your-project-ref.supabase.co/functions/v1/send-push-notification';
  supabase_anon_key := 'your-supabase-anon-key';
  
  -- Get all FCM tokens for the user
  FOR token_record IN
    SELECT fcm_token FROM user_fcm_tokens WHERE user_id = p_user_id
  LOOP
    -- Call Edge Function via HTTP
    PERFORM net.http_post(
      url := function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || supabase_anon_key
      ),
      body := jsonb_build_object(
        'token', token_record.fcm_token,
        'title', p_title,
        'body', p_body,
        'data', p_data
      )
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to send push notification when notification is created
CREATE OR REPLACE FUNCTION trigger_send_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  push_pref BOOLEAN;
  notification_data JSONB;
BEGIN
  -- Check user's push notification preference for this notification type
  SELECT CASE NEW.type
    WHEN 'message' THEN COALESCE((SELECT push_messages FROM notification_preferences WHERE user_id = NEW.user_id), true)
    WHEN 'join_request' THEN COALESCE((SELECT push_join_requests FROM notification_preferences WHERE user_id = NEW.user_id), true)
    WHEN 'activity' THEN COALESCE((SELECT push_activities FROM notification_preferences WHERE user_id = NEW.user_id), true)
    WHEN 'help_request' THEN COALESCE((SELECT push_help_requests FROM notification_preferences WHERE user_id = NEW.user_id), true)
    WHEN 'bin_health' THEN COALESCE((SELECT push_bin_health FROM notification_preferences WHERE user_id = NEW.user_id), true)
    ELSE true
  END INTO push_pref;
  
  -- Only send push notification if enabled
  IF push_pref THEN
    -- Prepare notification data
    notification_data := jsonb_build_object(
      'notification_id', NEW.id,
      'type', NEW.type,
      'bin_id', NEW.bin_id,
      'reference_id', NEW.reference_id
    );
    
    -- Send push notification
    PERFORM send_push_notification(
      NEW.user_id,
      COALESCE(NEW.title, 'New Notification'),
      COALESCE(NEW.body, 'You have a new notification'),
      notification_data
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to send push notification when notification is inserted
DROP TRIGGER IF EXISTS send_push_on_notification_insert ON user_notifications;
CREATE TRIGGER send_push_on_notification_insert
  AFTER INSERT ON user_notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_send_push_notification();

COMMENT ON FUNCTION send_push_notification IS 'Sends push notification via Edge Function to user devices.';
COMMENT ON FUNCTION trigger_send_push_notification IS 'Trigger function to send push notification when notification is created.';

