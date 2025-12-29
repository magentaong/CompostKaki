# Deploy Supabase Edge Function for Push Notifications

## Prerequisites

1. ✅ Supabase project set up
2. ✅ Firebase project configured
3. ✅ FCM Server Key obtained from Firebase Console

## Step 1: Install Supabase CLI

```bash
# Install via npm (if you have Node.js)
npm install -g supabase

# Or via Homebrew (macOS)
brew install supabase/tap/supabase
```

## Step 2: Login to Supabase

```bash
supabase login
```

This will open a browser window for authentication.

## Step 3: Link Your Project

```bash
cd /Users/itzsihui/CompostKaki
supabase link --project-ref your-project-ref
```

**To find your project ref:**
- Go to Supabase Dashboard → Project Settings → General
- Look for **Reference ID** (format: `abcdefghijklmnop`)

## Step 4: Get Firebase Service Account Key (for V1 API)

**To get Service Account Key:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **compostkaki-eaf61**
3. Go to **Project Settings** → **Service Accounts** tab
4. Click **"Generate new private key"**
5. A JSON file will download - **keep this file secure!**
6. Copy the entire JSON content

**Important:** This JSON contains sensitive credentials. Never commit it to git or share it publicly.

## Step 5: Set FCM Service Account Secret

```bash
# Set the service account JSON as a secret
# Replace the content with your actual service account JSON (all on one line)
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"compostkaki-eaf61",...}'
```

**Note:** The JSON must be on a single line. You can use `jq` to format it:
```bash
# If you have jq installed:
cat path/to/service-account-key.json | jq -c | xargs -I {} supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{}'
```

## Step 6: Deploy Edge Function

```bash
cd /Users/itzsihui/CompostKaki
supabase functions deploy send-push-notification
```

## Step 7: Verify Deployment

```bash
# List deployed functions
supabase functions list

# Check function logs
supabase functions logs send-push-notification
```

## Step 8: Test the Function

You can test the function using curl or from your app:

```bash
# Get your Supabase anon key and project URL
curl -X POST \
  'https://your-project-ref.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "FCM_TOKEN_HERE",
    "title": "Test Notification",
    "body": "This is a test push notification"
  }'
```

## Step 9: Create Database Function to Call Edge Function

Run this SQL in Supabase SQL Editor:

```sql
-- Enable pg_net extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Function to send push notification via Edge Function
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
BEGIN
  -- Get Supabase project URL and anon key
  -- Replace with your actual values
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
```

**Note:** Replace `your-project-ref` and `your-supabase-anon-key` with actual values.

## Alternative: Use Supabase Database Webhooks

If `pg_net` extension is not available, you can use Supabase Database Webhooks instead:

1. Go to Supabase Dashboard → Database → Webhooks
2. Create a new webhook
3. Set trigger: `INSERT` on `user_notifications`
4. Set URL: `https://your-project-ref.supabase.co/functions/v1/send-push-notification`
5. Set HTTP method: `POST`
6. Add headers: `Authorization: Bearer YOUR_ANON_KEY`

## Troubleshooting

### Function deployment fails
- Check you're logged in: `supabase login`
- Verify project is linked: `supabase projects list`
- Check function code syntax

### Function returns 401 Unauthorized
- Verify FCM_SERVICE_ACCOUNT_JSON secret is set correctly
- Check the service account JSON is valid and complete
- Ensure the service account has Firebase Cloud Messaging API enabled
- Check Supabase anon key is correct

### Function returns 403 Forbidden
- Verify the service account has the "Firebase Cloud Messaging API" enabled in Google Cloud Console
- Check that the service account has proper permissions

### Push notifications not received
- Verify FCM token is saved in `user_fcm_tokens` table
- Check device has internet connection
- Verify APNs is configured (iOS)
- Check function logs for errors

## Next Steps

After deployment:
1. ✅ Test push notifications from database triggers
2. ✅ Verify notifications are received on devices
3. ✅ Monitor function logs for any issues

