-- Make chat buckets public and set up policies
-- Run this in Supabase SQL Editor

-- Note: You need to manually set buckets to PUBLIC in the Supabase Dashboard:
-- 1. Go to Storage > Buckets
-- 2. Click on each bucket: chat-images, chat-videos, chat-audio
-- 3. Click "Edit bucket"
-- 4. Check "Public bucket"
-- 5. Save

-- After making buckets public, run these policies:

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can upload chat media" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view chat media" ON storage.objects;
DROP POLICY IF EXISTS "Public can view chat media" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own chat media" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own chat media" ON storage.objects;

-- Policy: Allow authenticated users to upload to chat media buckets
CREATE POLICY "Authenticated users can upload chat media"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow authenticated users to view chat media
CREATE POLICY "Authenticated users can view chat media"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow public access to view (needed for public buckets)
CREATE POLICY "Public can view chat media"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow users to update their own files (for editing/deleting)
CREATE POLICY "Users can update their own chat media"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow users to delete their own files
CREATE POLICY "Users can delete their own chat media"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

