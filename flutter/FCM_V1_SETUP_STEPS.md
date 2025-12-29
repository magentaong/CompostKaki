# Quick Setup: FCM V1 API Migration

## ✅ What's Done

1. ✅ Edge function updated to use FCM V1 API
2. ✅ Uses OAuth2 tokens (more secure)
3. ✅ Proper JWT signing implementation

## 📋 Steps to Complete

### Step 1: Get Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **compostkaki-eaf61**
3. Click ⚙️ → **Project Settings** → **Service Accounts** tab
4. Click **"Generate new private key"**
5. Click **"Generate key"** in the dialog
6. Save the downloaded JSON file securely

### Step 2: Enable FCM V1 API (if not already enabled)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **compostkaki-eaf61**
3. Go to **APIs & Services** → **Library**
4. Search for **"Firebase Cloud Messaging API"**
5. Click **Enable** (if not already enabled)

### Step 3: Set Service Account Secret

**Option A: Using jq (recommended)**
```bash
cd /Users/itzsihui/CompostKaki
cat path/to/service-account-key.json | jq -c | xargs -I {} supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{}'
```

**Option B: Manual (if no jq)**
1. Open the JSON file
2. Copy all content
3. Remove all line breaks (make it one line)
4. Run:
```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<paste-json-here>'
```

**Important:** The JSON must be on a single line with no line breaks.

### Step 4: Deploy Edge Function

```bash
cd /Users/itzsihui/CompostKaki
supabase functions deploy send-push-notification
```

### Step 5: Verify

```bash
# Check logs
supabase functions logs send-push-notification --tail
```

### Step 6: Test

Send a test notification from your app or via SQL:

```sql
-- This will trigger a push notification
INSERT INTO user_notifications (user_id, type, title, body, bin_id)
VALUES (
  'your-user-id',
  'message',
  'Test',
  'Testing V1 API',
  'your-bin-id'
);
```

## 🔍 Troubleshooting

### "FCM_SERVICE_ACCOUNT_JSON not set"
- Make sure you ran: `supabase secrets set FCM_SERVICE_ACCOUNT_JSON='...'`
- Check: `supabase secrets list`

### "Invalid service account JSON"
- Ensure JSON is on one line (no line breaks)
- Verify it contains: `project_id`, `private_key`, `client_email`
- Check for extra quotes or escaping issues

### "Failed to get access token"
- Verify FCM V1 API is enabled in Google Cloud Console
- Check the private_key in JSON is correct (should have `\n` for newlines)
- Ensure service account email matches

### "403 Forbidden"
- Go to Google Cloud Console → APIs & Services
- Verify "Firebase Cloud Messaging API" is enabled
- Check service account permissions

## 📝 What Changed

**Before (Legacy):**
- Secret: `FCM_SERVER_KEY` (simple string)
- Endpoint: `https://fcm.googleapis.com/fcm/send`
- Auth: `key=${FCM_SERVER_KEY}`

**After (V1):**
- Secret: `FCM_SERVICE_ACCOUNT_JSON` (full JSON)
- Endpoint: `https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`
- Auth: OAuth2 Bearer token (auto-generated)

## ✅ Benefits

- ✅ Future-proof (Legacy API deprecated)
- ✅ More secure (OAuth2 tokens expire)
- ✅ Better error messages
- ✅ More features available

