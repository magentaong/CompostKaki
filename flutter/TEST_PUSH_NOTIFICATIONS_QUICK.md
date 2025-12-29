# Quick Guide: Test Push Notifications

## Prerequisites ✅

- [x] Push Notifications enabled in Xcode
- [x] APNs key uploaded to Firebase
- [x] App running on **physical device** (simulator doesn't support push)

## Method 1: Test via Firebase Console (Easiest) 🚀

### Step 1: Get Your FCM Token

1. **Run your app** on a physical device
2. **Check console logs** - you should see:
   ```
   ✅ FCM token obtained and saved: ...
   ```

3. **Or check database:**
   - Go to Supabase Dashboard → SQL Editor
   - Run:
   ```sql
   SELECT fcm_token, device_type, created_at 
   FROM user_fcm_tokens 
   WHERE user_id = 'your-user-id'
   ORDER BY created_at DESC 
   LIMIT 1;
   ```
   - Copy the `fcm_token` value

### Step 2: Send Test Notification from Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **compostkaki-eaf61**
3. In left sidebar, click **"Engage"** → **"Cloud Messaging"**
4. Click **"Send your first message"** or **"New notification"**
5. Fill in:
   - **Notification title:** "Test Push Notification"
   - **Notification text:** "Testing push notifications from Firebase"
6. Click **"Send test message"** (or "Test" button)
7. **Paste your FCM token** in the field
8. Click **"Test"**

### Step 3: Check Your Device

- **Expected:** Notification should appear on your device immediately
- If it works → Your setup is correct! ✅
- If it doesn't → Check troubleshooting below

---

## Method 2: Test via App (Real Scenario) 📱

### Step 1: Send a Message in Bin Chat

1. **Open app** on Device A
2. **Send a message** in a bin chat
3. **Expected:** 
   - Badge appears on Home tab ✅
   - Push notification appears (if app is in background) ✅

### Step 2: Test Background Notifications

1. **Close the app completely** (swipe up from app switcher)
2. **Have someone else send a message** in a bin you're part of
3. **Expected:** Push notification appears on your device
4. **Tap the notification**
5. **Expected:** App opens to the chat screen

### Step 3: Test Foreground Notifications

1. **Keep app open** (in foreground)
2. **Have someone send a message**
3. **Expected:** 
   - Badge updates immediately ✅
   - Push notification may or may not show (depends on iOS settings)

---

## Method 3: Test via Database Trigger (Advanced) 🔧

### Step 1: Verify Notification Was Created

Run in Supabase SQL Editor:
```sql
SELECT * FROM user_notifications 
WHERE user_id = 'your-user-id' 
ORDER BY created_at DESC 
LIMIT 5;
```

### Step 2: Check Edge Function Logs

If Edge Function is deployed, check logs:
```bash
supabase functions logs send-push-notification --tail
```

---

## Troubleshooting 🔍

### Push Notification Not Received?

1. **Check FCM token exists:**
   ```sql
   SELECT * FROM user_fcm_tokens WHERE user_id = 'your-user-id';
   ```
   - If empty → FCM initialization failed
   - Check console logs for errors

2. **Check device notification settings:**
   - Settings → Notifications → CompostKaki
   - Ensure notifications are **enabled**

3. **Check Firebase Console:**
   - Cloud Messaging → Apple app configuration
   - Should show **"Status: Active"** ✅

4. **Test with Firebase Console first:**
   - If Firebase Console test works → Issue is with Edge Function/triggers
   - If Firebase Console test fails → Issue is with APNs/FCM setup

5. **Check console logs:**
   - Look for: `✅ APNS token obtained`
   - Look for: `✅ FCM token obtained and saved`
   - If you see errors → Fix those first

### Common Errors

**"APNS token not available"**
- Push Notifications capability not enabled in Xcode
- Fix: Enable in Xcode → Signing & Capabilities

**"FCM token is null"**
- APNS token not ready yet
- Fix: Wait a few seconds, or check Xcode setup

**"401 Unauthorized" (Edge Function)**
- FCM_SERVER_KEY not set
- Fix: Set secret in Supabase Dashboard

---

## Success Checklist ✅

- [ ] FCM token saved in database
- [ ] Firebase Console test notification works
- [ ] Push notification received on device
- [ ] Notification works when app is closed
- [ ] Badge appears when notification created
- [ ] Badge clears when viewing relevant screen

---

## Next Steps

Once push notifications work:
1. ✅ Test all notification types (messages, join requests, activities, etc.)
2. ✅ Test notification preferences (disable/enable)
3. ✅ Monitor Edge Function logs for errors
4. ✅ Test on multiple devices

