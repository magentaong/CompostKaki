-- Create storage buckets for chat media
-- Run this in Supabase SQL Editor or Storage section

-- Note: Storage buckets are created in the Supabase Dashboard under Storage
-- This SQL file is for reference - you need to create buckets manually in the UI

-- Instructions:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Click "New bucket"
-- 3. Create these buckets with PUBLIC access:
--    - chat-images (for image messages)
--    - chat-videos (for video messages)  
--    - chat-audio (for audio recordings)

-- Storage bucket policies will be set automatically by Supabase
-- But you may need to configure RLS policies if needed

-- Example RLS policies (if needed):
-- Allow authenticated users to upload to chat-images
-- INSERT policy: authenticated users can upload
-- SELECT policy: authenticated users can view (for public buckets, this is automatic)

