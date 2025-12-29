# Testing Notifications - Complete Guide

## Prerequisites Checklist

- [ ] Database tables created (`user_notifications`, `user_fcm_tokens`, `notification_preferences`)
- [ ] Database triggers created (for auto-creating notifications)
- [ ] Firebase project configured
- [ ] `firebase_options.dart` generated
- [ ] APNs configured (iOS)
- [ ] Supabase Edge Function deployed
- [ ] App running on physical device (push notifications don't work on simulator)

## Step 1: Test In-App Badges

### 1.1 Send a Test Message

1. Open the app on your device
2. Navigate to a bin chat
3. Send a message
4. **Expected:** Badge should appear on Home tab

### 1.2 Check Badge Clearing

1. Open the chat screen
2. **Expected:** Badge should clear automatically

### 1.3 Test Other Notification Types

**Join Request (Admin only):**
1. Have another user request to join your bin
2. **Expected:** Badge appears on admin panel icon

**New Activity:**
1. Have someone log an activity in a bin
2. **Expected:** Badge appears (clears when viewing bin detail)

**Help Request:**
1. Have someone post a help request
2. **Expected:** Badge appears on Tasks tab

## Step 2: Test Push Notifications

### 2.1 Verify FCM Token is Saved

Run this SQL in Supabase SQL Editor:

```sql
SELECT * FROM user_fcm_tokens WHERE user_id = 'your-user-id';
```

**Expected:** Should see your FCM token(s)

### 2.2 Send Test Push via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **compostkaki-eaf61**
3. Go to **Cloud Messaging** → **Send your first message**
4. Enter:
   - **Notification title:** "Test Notification"
   - **Notification text:** "Testing push notifications"
5. Click **Send test message**
6. Enter your FCM token (from database query above)
7. Click **Test**

**Expected:** Notification should appear on your device

### 2.3 Test via Database Trigger

Send a message in a bin chat, then check:

1. **Database:** Verify notification was created:
   ```sql
   SELECT * FROM user_notifications 
   WHERE user_id = 'your-user-id' 
   ORDER BY created_at DESC 
   LIMIT 5;
   ```

2. **Device:** Check if push notification was received

3. **Function Logs:** Check Edge Function logs:
   ```bash
   supabase functions logs send-push-notification
   ```

## Step 3: Test Notification Preferences

1. Open app → Profile → Settings → Notification Preferences
2. Toggle off "Push Messages"
3. Send a message
4. **Expected:** Badge appears, but no push notification
5. Toggle back on
6. Send another message
7. **Expected:** Both badge and push notification appear

## Step 4: Test Background Notifications

1. **Close the app** (swipe up, don't just minimize)
2. Have someone send a message in a bin you're part of
3. **Expected:** Push notification appears even when app is closed
4. Tap the notification
5. **Expected:** App opens to the relevant screen

## Step 5: Test Foreground Notifications

1. **Keep app open** (in foreground)
2. Have someone send a message
3. **Expected:** 
   - Badge updates immediately
   - Push notification may or may not show (depends on implementation)
   - Check console logs for "Foreground message received"

## Troubleshooting

### Badges Not Showing

1. Check Supabase Realtime connection:
   ```sql
   -- Verify notifications exist
   SELECT COUNT(*) FROM user_notifications WHERE is_read = false;
   ```

2. Check notification preferences:
   ```sql
   SELECT * FROM notification_preferences WHERE user_id = 'your-user-id';
   ```

3. Verify Realtime subscription is active (check app logs)

### Push Notifications Not Received

1. **Check FCM token:**
   ```sql
   SELECT * FROM user_fcm_tokens WHERE user_id = 'your-user-id';
   ```

2. **Check Edge Function logs:**
   ```bash
   supabase functions logs send-push-notification --tail
   ```

3. **Verify APNs configuration:**
   - Firebase Console → Cloud Messaging → Apple app configuration
   - Should show "Status: Active"

4. **Check device settings:**
   - Settings → Notifications → CompostKaki
   - Ensure notifications are enabled

5. **Test with Firebase Console:**
   - Send test message directly from Firebase Console
   - If this works, issue is with Edge Function
   - If this doesn't work, issue is with APNs/FCM setup

### Edge Function Errors

1. **Check function logs:**
   ```bash
   supabase functions logs send-push-notification
   ```

2. **Common errors:**
   - `401 Unauthorized` → Check FCM_SERVER_KEY secret
   - `Invalid token` → FCM token expired or invalid
   - `Network error` → Check function URL and network

## Success Criteria

✅ Badges appear when notifications are created  
✅ Badges clear when viewing relevant screens  
✅ Push notifications received on device  
✅ Push notifications work in background  
✅ Notification preferences work correctly  
✅ No errors in function logs  

## Next Steps After Testing

Once everything works:
1. ✅ Monitor function logs for production issues
2. ✅ Set up error alerting
3. ✅ Document any custom configurations
4. ✅ Train team on notification system

