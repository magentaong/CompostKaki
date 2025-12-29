-- Create notification tables for tracking notifications and FCM tokens

-- Table to track user notifications (for badges and read/unread status)
CREATE TABLE IF NOT EXISTS user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('message', 'join_request', 'activity', 'help_request', 'bin_health', 'task_completed', 'task_accepted', 'task_reverted')),
  reference_id UUID, -- ID of the related record (message_id, request_id, task_id, bin_id, etc.)
  bin_id UUID REFERENCES bins(id) ON DELETE CASCADE,
  title TEXT,
  body TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for user_notifications
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_type ON user_notifications(type);
CREATE INDEX IF NOT EXISTS idx_user_notifications_bin_id ON user_notifications(bin_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_is_read ON user_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_user_notifications_created_at ON user_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_unread ON user_notifications(user_id, is_read) WHERE is_read = false;

-- Table to store FCM tokens for push notifications
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL UNIQUE,
  device_type TEXT CHECK (device_type IN ('ios', 'android')),
  device_info JSONB, -- Store additional device info if needed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for user_fcm_tokens
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON user_fcm_tokens(fcm_token);

-- Table for notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  -- Push notification preferences
  push_messages BOOLEAN DEFAULT true,
  push_join_requests BOOLEAN DEFAULT true,
  push_activities BOOLEAN DEFAULT true,
  push_help_requests BOOLEAN DEFAULT true,
  push_bin_health BOOLEAN DEFAULT true,
  -- In-app badge preferences (usually always enabled)
  badge_messages BOOLEAN DEFAULT true,
  badge_join_requests BOOLEAN DEFAULT true,
  badge_activities BOOLEAN DEFAULT true,
  badge_help_requests BOOLEAN DEFAULT true,
  badge_bin_health BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for notification_preferences
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- Enable Row Level Security
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_notifications
-- Users can view their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON user_notifications;
CREATE POLICY "Users can view their own notifications"
  ON user_notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON user_notifications;
CREATE POLICY "Users can update their own notifications"
  ON user_notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- System can insert notifications (via triggers/functions)
DROP POLICY IF EXISTS "System can insert notifications" ON user_notifications;
CREATE POLICY "System can insert notifications"
  ON user_notifications
  FOR INSERT
  WITH CHECK (true);

-- RLS Policies for user_fcm_tokens
-- Users can manage their own FCM tokens
DROP POLICY IF EXISTS "Users can manage their own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can manage their own FCM tokens"
  ON user_fcm_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for notification_preferences
-- Users can manage their own notification preferences
DROP POLICY IF EXISTS "Users can manage their own notification preferences" ON notification_preferences;
CREATE POLICY "Users can manage their own notification preferences"
  ON notification_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp for user_fcm_tokens
CREATE OR REPLACE FUNCTION update_user_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on user_fcm_tokens
DROP TRIGGER IF EXISTS update_user_fcm_tokens_updated_at ON user_fcm_tokens;
CREATE TRIGGER update_user_fcm_tokens_updated_at
  BEFORE UPDATE ON user_fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_user_fcm_tokens_updated_at();

-- Function to automatically update updated_at timestamp for notification_preferences
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on notification_preferences
DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_preferences_updated_at();

-- Comments
COMMENT ON TABLE user_notifications IS 'Stores notifications for users. Used for badges and tracking read/unread status.';
COMMENT ON TABLE user_fcm_tokens IS 'Stores FCM tokens for push notifications. One user can have multiple tokens (multiple devices).';
COMMENT ON TABLE notification_preferences IS 'Stores user preferences for notifications (push and badges).';

