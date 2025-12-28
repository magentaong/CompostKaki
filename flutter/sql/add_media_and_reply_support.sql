-- Add media and reply-to-message support to bin_messages table
-- Run this after the group chat migration

-- Step 1: Add columns for media attachments
ALTER TABLE bin_messages 
  ADD COLUMN IF NOT EXISTS media_type TEXT CHECK (media_type IN ('image', 'video', 'audio', NULL)),
  ADD COLUMN IF NOT EXISTS media_url TEXT,
  ADD COLUMN IF NOT EXISTS media_thumbnail_url TEXT,
  ADD COLUMN IF NOT EXISTS media_size INTEGER, -- Size in bytes
  ADD COLUMN IF NOT EXISTS media_duration INTEGER, -- Duration in seconds (for video/audio)
  ADD COLUMN IF NOT EXISTS media_filename TEXT;

-- Step 2: Add reply-to-message support
ALTER TABLE bin_messages
  ADD COLUMN IF NOT EXISTS reply_to_message_id UUID REFERENCES bin_messages(id) ON DELETE SET NULL;

-- Step 3: Create index for reply-to lookups
CREATE INDEX IF NOT EXISTS idx_bin_messages_reply_to ON bin_messages(reply_to_message_id);

-- Step 4: Create index for media queries
CREATE INDEX IF NOT EXISTS idx_bin_messages_media_type ON bin_messages(media_type) WHERE media_type IS NOT NULL;

-- Step 5: Update RLS policies to allow reading replied-to messages
-- The existing SELECT policy should already cover this, but we ensure reply_to_message_id
-- can be accessed when inserting/updating messages

-- Note: The existing policies should work fine, but we might want to ensure
-- users can read messages they're replying to even if they're deleted
-- (for showing the reply preview). However, since we allow users to see
-- their own deleted messages, and non-deleted messages are visible to all members,
-- the current policy should be sufficient.

