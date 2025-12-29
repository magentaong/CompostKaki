# Quick Test: Push Notifications

## Step 1: Get Your User ID and FCM Token

Run this in Supabase SQL Editor:

```sql
-- Get your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Get your FCM token (replace with your user_id from above)
SELECT fcm_token, device_type, created_at 
FROM user_fcm_tokens 
WHERE user_id = 'your-user-id-here'
ORDER BY created_at DESC 
LIMIT 1;
```

**Note:** If you don't have an FCM token, make sure:
1. App is running on a **physical device** (not simulator)
2. App has requested notification permissions
3. Check app console logs for FCM token

## Step 2: Create a Test Notification

Run this SQL (replace `your-user-id` with your actual user ID):

```sql
-- Create a test notification (this will trigger push notification)
INSERT INTO user_notifications (user_id, type, title, body, bin_id)
VALUES (
  '7a1f0766-bba5-4c43-9ccb-42ccfe56d8be',  -- Replace with your user ID
  'message',
  'Test Push Notification',
  'This is a test push notification from the database!',
  NULL  -- Can be NULL for testing
);
```

## Step 3: Check Your Device

- **Expected:** Push notification should appear on your device
- **If app is closed:** Notification appears in notification center
- **If app is open:** Check if notification appears (may vary by iOS settings)

## Step 4: Check Edge Function Logs

```bash
cd /Users/itzsihui/CompostKaki
supabase functions logs send-push-notification --tail
```

Look for:
- ✅ `success: true` - Notification sent successfully
- ❌ Any errors - Check the error message

## Troubleshooting

### No notification received?

1. **Check FCM token exists:**
   ```sql
   SELECT * FROM user_fcm_tokens WHERE user_id = 'your-user-id';
   ```
   - If empty → FCM not initialized in app

2. **Check Edge Function logs:**
   ```bash
   supabase functions logs send-push-notification --tail
   ```
   - Look for errors

3. **Test with Firebase Console:**
   - Go to Firebase Console → Cloud Messaging
   - Send test message with your FCM token
   - If this works → Edge Function issue
   - If this fails → FCM/APNs setup issue

4. **Check device settings:**
   - Settings → Notifications → CompostKaki
   - Ensure notifications are enabled

### Common Errors

**"FCM_SERVICE_ACCOUNT_JSON not set"**
- Run: `supabase secrets list` to verify secret exists

**"Failed to get access token"**
- Check service account JSON is valid
- Verify FCM V1 API is enabled in Google Cloud Console

**"403 Forbidden"**
- FCM V1 API not enabled
- Go to Google Cloud Console → Enable "Firebase Cloud Messaging API"

