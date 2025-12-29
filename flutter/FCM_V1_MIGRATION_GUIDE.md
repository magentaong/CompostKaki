# FCM V1 API Migration Guide

## Overview

This guide helps you migrate from FCM Legacy API to FCM V1 API for push notifications.

## Why Migrate?

- ✅ Legacy API is deprecated (discontinued June 20, 2024)
- ✅ V1 API is the recommended and supported API
- ✅ Better security with OAuth2 tokens
- ✅ More features and better error handling

## Step 1: Get Service Account Key

1. **Go to Firebase Console:**
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Select your project: **compostkaki-eaf61**

2. **Navigate to Service Accounts:**
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select **"Project Settings"**
   - Go to **"Service Accounts"** tab

3. **Generate Private Key:**
   - Click **"Generate new private key"** button
   - A confirmation dialog will appear
   - Click **"Generate key"**
   - A JSON file will download automatically

4. **Save the JSON file securely:**
   - The file contains sensitive credentials
   - Never commit it to git
   - Never share it publicly
   - Keep it in a secure location

## Step 2: Enable FCM V1 API

1. **Go to Google Cloud Console:**
   - Visit [Google Cloud Console](https://console.cloud.google.com/)
   - Select project: **compostkaki-eaf61**

2. **Enable Firebase Cloud Messaging API:**
   - Go to **"APIs & Services"** → **"Library"**
   - Search for **"Firebase Cloud Messaging API"**
   - Click on it
   - Click **"Enable"** (if not already enabled)

## Step 3: Set Service Account Secret in Supabase

1. **Format the JSON (single line):**
   ```bash
   # If you have jq installed:
   cat path/to/service-account-key.json | jq -c
   
   # Or manually: Remove all line breaks and extra spaces
   ```

2. **Set the secret:**
   ```bash
   cd /Users/itzsihui/CompostKaki
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"compostkaki-eaf61",...}'
   ```

   **Important:** Replace the entire JSON content (all on one line) with your actual service account JSON.

## Step 4: Deploy Updated Edge Function

The edge function has been updated to use V1 API. Deploy it:

```bash
cd /Users/itzsihui/CompostKaki
supabase functions deploy send-push-notification
```

## Step 5: Verify Deployment

```bash
# Check function logs
supabase functions logs send-push-notification --tail
```

## Step 6: Test Push Notification

You can test using the Supabase SQL Editor or from your app:

```sql
-- Test by inserting a notification (this will trigger push notification)
INSERT INTO user_notifications (user_id, type, title, body, bin_id)
VALUES (
  'your-user-id-here',
  'message',
  'Test Notification',
  'Testing FCM V1 API',
  'your-bin-id-here'
);
```

## Troubleshooting

### Error: "FCM_SERVICE_ACCOUNT_JSON environment variable is not set"
- Make sure you set the secret: `supabase secrets set FCM_SERVICE_ACCOUNT_JSON='...'`
- Verify the secret is set: `supabase secrets list`

### Error: "Invalid service account JSON"
- Check the JSON is complete and valid
- Make sure it's all on one line (no line breaks)
- Verify it contains: `project_id`, `private_key`, `client_email`

### Error: "Failed to get access token"
- Verify the service account has Firebase Cloud Messaging API enabled
- Check the private key is correct (should start with `-----BEGIN PRIVATE KEY-----`)
- Ensure the service account email matches the JSON

### Error: "403 Forbidden"
- Go to Google Cloud Console → APIs & Services → Enabled APIs
- Verify "Firebase Cloud Messaging API" is enabled
- Check the service account has proper permissions

## What Changed?

### Before (Legacy API):
- Used `FCM_SERVER_KEY` (simple string)
- Endpoint: `https://fcm.googleapis.com/fcm/send`
- Authorization: `key=${FCM_SERVER_KEY}`

### After (V1 API):
- Uses `FCM_SERVICE_ACCOUNT_JSON` (full JSON)
- Endpoint: `https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`
- Authorization: OAuth2 Bearer token (generated from service account)

## Benefits of V1 API

1. **Better Security:** OAuth2 tokens expire automatically
2. **More Features:** Better error messages, more configuration options
3. **Future-Proof:** Legacy API is deprecated
4. **Better Performance:** More efficient API design

## Next Steps

After migration:
1. ✅ Test push notifications work
2. ✅ Monitor function logs for any errors
3. ✅ Update your documentation
4. ✅ Remove any references to Legacy API

