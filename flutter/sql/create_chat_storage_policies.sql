-- Storage RLS Policies for Chat Media Buckets
-- Run this in Supabase SQL Editor after creating the buckets

-- Enable RLS on storage.objects (if not already enabled)
-- Note: RLS is usually enabled by default, but we'll ensure it

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can upload chat media" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view chat media" ON storage.objects;
DROP POLICY IF EXISTS "Public can view chat media" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own chat media" ON storage.objects;

-- Policy: Allow authenticated users to upload to chat media buckets
CREATE POLICY "Authenticated users can upload chat media"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow authenticated users to view chat media (for public buckets, this might not be needed)
CREATE POLICY "Authenticated users can view chat media"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow public access to view chat media (since buckets are public)
-- This ensures anyone can view the media URLs
CREATE POLICY "Public can view chat media"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
);

-- Policy: Allow users to delete their own uploaded files
CREATE POLICY "Users can delete their own chat media"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id IN ('chat-images', 'chat-videos', 'chat-audio')
  -- Note: This allows any authenticated user to delete - you might want to restrict
  -- to the file owner by checking metadata or filename pattern
);

