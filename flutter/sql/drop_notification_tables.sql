-- Drop notification-related tables, triggers, functions, and policies
-- Run this before creating new notification tables

-- Drop triggers first (they depend on tables)
DROP TRIGGER IF EXISTS notify_new_message ON bin_messages;
DROP TRIGGER IF EXISTS notify_join_request ON bin_requests;
DROP TRIGGER IF EXISTS notify_new_activity ON bin_logs;
DROP TRIGGER IF EXISTS notify_help_request ON tasks;
DROP TRIGGER IF EXISTS notify_bin_health ON bins;
DROP TRIGGER IF EXISTS update_user_fcm_tokens_updated_at ON user_fcm_tokens;
DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;

-- Drop trigger functions
DROP FUNCTION IF EXISTS trigger_notify_new_message() CASCADE;
DROP FUNCTION IF EXISTS trigger_notify_join_request() CASCADE;
DROP FUNCTION IF EXISTS trigger_notify_new_activity() CASCADE;
DROP FUNCTION IF EXISTS trigger_notify_help_request() CASCADE;
DROP FUNCTION IF EXISTS trigger_notify_bin_health() CASCADE;

-- Drop helper functions
DROP FUNCTION IF EXISTS notify_bin_members(UUID, TEXT, UUID, TEXT, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS notify_bin_admin(UUID, TEXT, UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_user_fcm_tokens_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_notification_preferences_updated_at() CASCADE;

-- Drop any remaining functions related to notifications
DROP FUNCTION IF EXISTS send_push_notification(UUID, TEXT, TEXT, JSONB) CASCADE;

-- Drop tables (this will also drop all policies and indexes)
-- Note: CASCADE will drop dependent objects, but we've already dropped triggers/functions above
DROP TABLE IF EXISTS user_notifications CASCADE;
DROP TABLE IF EXISTS user_fcm_tokens CASCADE;
DROP TABLE IF EXISTS notification_preferences CASCADE;

-- Verify drops (uncomment to check - these should return 0 rows if successful)
-- SELECT COUNT(*) FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_name IN ('user_notifications', 'user_fcm_tokens', 'notification_preferences');
-- 
-- SELECT COUNT(*) FROM information_schema.triggers 
-- WHERE trigger_name LIKE 'notify_%' OR trigger_name LIKE 'update_%_updated_at';

