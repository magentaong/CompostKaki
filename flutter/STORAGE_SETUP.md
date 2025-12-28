# Storage Buckets Setup Guide

## Problem
If you're getting errors when trying to send photos/videos in chat, it's likely because the storage buckets don't exist in Supabase.

## Solution: Create Storage Buckets

### Step 1: Go to Supabase Dashboard
1. Open your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar

### Step 2: Create Required Buckets

Create these **3 buckets** (all should be **PUBLIC**):

#### 1. `chat-images`
- **Name:** `chat-images`
- **Public bucket:** ✅ Yes (checked)
- **File size limit:** 10 MB (or as needed)
- **Allowed MIME types:** `image/*`

#### 2. `chat-videos`
- **Name:** `chat-videos`
- **Public bucket:** ✅ Yes (checked)
- **File size limit:** 100 MB (or as needed)
- **Allowed MIME types:** `video/*`

#### 3. `chat-audio`
- **Name:** `chat-audio`
- **Public bucket:** ✅ Yes (checked)
- **File size limit:** 10 MB (or as needed)
- **Allowed MIME types:** `audio/*`

### Step 3: Set Storage Policies (Optional but Recommended)

For each bucket, you may want to set RLS policies:

#### For `chat-images`, `chat-videos`, and `chat-audio`:

**INSERT Policy (Allow authenticated users to upload):**
```sql
CREATE POLICY "Authenticated users can upload chat media"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('chat-images', 'chat-videos', 'chat-audio'));
```

**SELECT Policy (Allow authenticated users to view):**
```sql
CREATE POLICY "Authenticated users can view chat media"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id IN ('chat-images', 'chat-videos', 'chat-audio'));
```

**DELETE Policy (Allow users to delete their own uploads):**
```sql
CREATE POLICY "Users can delete their own chat media"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Step 4: Verify

After creating the buckets:
1. Try sending a photo in the chat
2. If it still fails, check the error message - it should now be more descriptive
3. Verify the bucket names match exactly: `chat-images`, `chat-videos`, `chat-audio`

## Troubleshooting

### Error: "Bucket not found"
- Make sure the bucket name matches exactly (case-sensitive)
- Verify the bucket is created in the correct Supabase project

### Error: "Permission denied"
- Check that the bucket is set to **Public**
- Verify RLS policies allow authenticated users to upload

### Error: "File too large"
- Increase the file size limit in bucket settings
- Or compress images before uploading

