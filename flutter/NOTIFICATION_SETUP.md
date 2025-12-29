# Notification Setup Guide

This guide will help you set up push notifications and in-app badges for CompostKaki.

## Prerequisites

1. **Supabase Project**: You should already have this set up
2. **Firebase Project**: You'll need to create a Firebase project for FCM (Firebase Cloud Messaging)

## Step 1: Database Setup

Run these SQL scripts in your Supabase SQL Editor:

1. **Create notification tables**:
   ```sql
   -- Run: flutter/sql/create_notification_tables.sql
   ```

2. **Create notification triggers**:
   ```sql
   -- Run: flutter/sql/create_notification_triggers.sql
   ```

These scripts will:
- Create `user_notifications` table for tracking badges
- Create `user_fcm_tokens` table for storing FCM tokens
- Create `notification_preferences` table for user preferences
- Set up database triggers to automatically create notifications when events occur

## Step 2: Firebase Setup

### 2.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "CompostKaki" (or your preferred name)
4. Follow the setup wizard

### 2.2 Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter your iOS bundle ID (found in `ios/Runner.xcodeproj/project.pbxproj` or `ios/Runner/Info.plist`)
3. Download `GoogleService-Info.plist`
4. Place it in `flutter/ios/Runner/GoogleService-Info.plist`
5. Add to Xcode project (drag into Runner folder)

### 2.3 Add Android App to Firebase

1. In Firebase Console, click "Add app" → Android
2. Enter your Android package name (found in `android/app/build.gradle` as `applicationId`)
3. Download `google-services.json`
4. Place it in `flutter/android/app/google-services.json`

### 2.4 Enable Cloud Messaging API

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Enable Cloud Messaging API (if not already enabled)
3. Copy the **Server Key** (you'll need this for the Edge Function)

### 2.5 Configure iOS Push Notifications

1. In Firebase Console → Project Settings → Cloud Messaging → Apple app configuration
2. Upload your APNs certificate or key:
   - For development: Use APNs Authentication Key (recommended)
   - For production: Use APNs Certificate
3. Follow Firebase instructions to upload your certificate/key

### 2.6 Generate Firebase Options File

Run this command in your Flutter project:

```bash
cd flutter
flutter pub get
flutter pub run flutterfire_cli:configure
```

This will:
- Generate `lib/firebase_options.dart`
- Configure Firebase for both iOS and Android

**Note**: If `flutterfire_cli` is not installed, install it first:
```bash
dart pub global activate flutterfire_cli
```

## Step 3: Update Flutter Code

### 3.1 Initialize Firebase in main.dart

The code is already updated in `lib/main.dart`, but make sure `firebase_options.dart` exists:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... rest of initialization
}
```

### 3.2 iOS Configuration

1. **Enable Push Notifications capability**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Click "+ Capability" → Push Notifications
   - Click "+ Capability" → Background Modes
   - Check "Remote notifications"

2. **Update Info.plist** (if needed):
   - Add `UIBackgroundModes` with `remote-notification` value

### 3.3 Android Configuration

1. **Update `android/app/build.gradle`**:
   ```gradle
   dependencies {
       // ... existing dependencies
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```

2. **Update `android/build.gradle`**:
   ```gradle
   buildscript {
       dependencies {
           // ... existing dependencies
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

3. **Apply plugin in `android/app/build.gradle`**:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Step 4: Supabase Edge Function Setup

### 4.1 Create Edge Function

1. Install Supabase CLI (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

4. Create Edge Function:
   ```bash
   supabase functions new send-push-notification
   ```

5. Copy the Edge Function code from `supabase/functions/send-push-notification/index.ts` (create this file)

6. Set environment variables:
   ```bash
   supabase secrets set FCM_SERVER_KEY=your-firebase-server-key
   ```

7. Deploy the function:
   ```bash
   supabase functions deploy send-push-notification
   ```

### 4.2 Create Database Function to Call Edge Function

Run this SQL in Supabase SQL Editor:

```sql
-- Function to send push notification via Edge Function
CREATE OR REPLACE FUNCTION send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS void AS $$
DECLARE
  fcm_tokens TEXT[];
  token_record RECORD;
BEGIN
  -- Get all FCM tokens for the user
  SELECT ARRAY_AGG(fcm_token) INTO fcm_tokens
  FROM user_fcm_tokens
  WHERE user_id = p_user_id;

  -- Call Edge Function for each token (or batch them)
  -- Note: This is a simplified version. You may want to batch tokens.
  FOR token_record IN
    SELECT fcm_token FROM user_fcm_tokens WHERE user_id = p_user_id
  LOOP
    -- Call Edge Function via HTTP (you'll need to set up HTTP extension)
    -- Or use pg_net extension if available
    PERFORM net.http_post(
      url := 'https://your-project-ref.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
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
$$ LANGUAGE plpgsql;
```

**Note**: You may need to enable the `pg_net` extension or use a different method to call the Edge Function from PostgreSQL.

## Step 5: Test Notifications

1. **Test in-app badges**:
   - Send a message in a bin chat
   - Check if badge appears on Home tab
   - Open the chat and verify badge clears

2. **Test push notifications**:
   - Send a message while app is in background
   - Check if push notification appears
   - Tap notification and verify it opens the app

## Troubleshooting

### Badges not showing
- Check Supabase Realtime connection
- Verify `user_notifications` table has entries
- Check notification preferences

### Push notifications not working
- Verify FCM token is saved in `user_fcm_tokens` table
- Check Firebase Console → Cloud Messaging for errors
- Verify APNs certificate/key is uploaded (iOS)
- Check device logs for FCM errors

### Edge Function errors
- Check Supabase Dashboard → Edge Functions → Logs
- Verify FCM_SERVER_KEY secret is set
- Check function logs for detailed errors

## Next Steps

1. **Notification Preferences UI**: Create a settings screen for users to manage notification preferences
2. **Notification History**: Show users their notification history
3. **Rich Notifications**: Add images and actions to push notifications

## Files Created/Modified

- `flutter/sql/create_notification_tables.sql` - Database tables
- `flutter/sql/create_notification_triggers.sql` - Database triggers
- `flutter/lib/services/notification_service.dart` - Notification service
- `flutter/lib/widgets/notification_badge.dart` - Badge widget
- `flutter/lib/main.dart` - Firebase initialization
- `flutter/lib/screens/main/main_screen.dart` - Badge integration
- `flutter/lib/screens/bin/bin_detail_screen.dart` - Badge integration
- `flutter/lib/screens/bin/bin_chat_conversation_screen.dart` - Badge clearing

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Flutter Firebase Messaging Package](https://pub.dev/packages/firebase_messaging)

