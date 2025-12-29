# Quick Fix: Enable Legacy FCM API

## Why This is Needed

The edge function currently uses the Legacy FCM API endpoint. While deprecated, it still works and is simpler to set up.

## Steps to Enable Legacy API

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **compostkaki-eaf61**
3. Go to **Project Settings** → **Cloud Messaging** tab
4. Scroll down to **"Cloud Messaging API (Legacy)"** section
5. Click the **three dots (⋮)** next to it
6. Select **"Manage API in Google Cloud Console"**
7. In Google Cloud Console, click **"Enable"**

## After Enabling

The edge function will work with the `FCM_SERVER_KEY` secret you set in Supabase.

## Note

⚠️ **This is a temporary solution.** The Legacy API is deprecated and will be removed in the future. You should migrate to V1 API eventually, but this will get push notifications working immediately.

