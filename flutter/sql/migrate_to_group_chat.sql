-- Migration: Convert bin_messages from 1:1 chat to group chat
-- This removes receiver_id, is_read, and updates RLS policies

-- Step 1: Delete all existing messages (no backward compatibility needed)
DELETE FROM bin_messages;

-- Step 2: Drop ALL existing RLS policies first (must be done before dropping columns)
-- Use a DO block to dynamically drop all policies on bin_messages table
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on bin_messages table
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'bin_messages' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON bin_messages', r.policyname);
    END LOOP;
END $$;

-- Also explicitly drop known policies (in case pg_policies doesn't catch them all)
DROP POLICY IF EXISTS "Users can insert their own messages" ON bin_messages;
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON bin_messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON bin_messages;
DROP POLICY IF EXISTS "Bin owners can view all messages in their bins" ON bin_messages;
DROP POLICY IF EXISTS "Users can view their own messages" ON bin_messages;
DROP POLICY IF EXISTS "Users can send messages" ON bin_messages;
DROP POLICY IF EXISTS "Bin members can insert messages" ON bin_messages;
DROP POLICY IF EXISTS "Bin members can view messages" ON bin_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON bin_messages;

-- Step 3: Now drop receiver_id column (after policies are dropped)
ALTER TABLE bin_messages DROP COLUMN IF EXISTS receiver_id;

-- Step 4: Drop is_read column (read receipts not needed for group chat)
ALTER TABLE bin_messages DROP COLUMN IF EXISTS is_read;

-- Step 5: Add is_deleted column for soft deletes
ALTER TABLE bin_messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Step 6: Add edited_at column to track edits
ALTER TABLE bin_messages ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP WITH TIME ZONE;

-- Step 7: Create new RLS policies for group chat (after columns are updated)

-- Policy: Users can insert messages if they are bin members or bin owner
CREATE POLICY "Bin members can insert messages"
  ON bin_messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND (
      -- User is bin owner
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      -- User is a bin member
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  );

-- Policy: Users can view messages if they are bin members or bin owner
-- Note: Allow users to see their own messages even if deleted (for UPDATE operations)
CREATE POLICY "Bin members can view messages"
  ON bin_messages
  FOR SELECT
  USING (
    (
      is_deleted = FALSE 
      OR auth.uid() = sender_id  -- Allow users to see their own deleted messages (needed for UPDATE)
    ) AND (
      -- User is bin owner
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      -- User is a bin member
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  );

-- Policy: Users can update their own messages (for editing/deleting)
-- They must be the sender AND still be a bin member/owner
CREATE POLICY "Users can update their own messages"
  ON bin_messages
  FOR UPDATE
  USING (
    auth.uid() = sender_id AND (
      -- User is bin owner
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      -- User is a bin member
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    auth.uid() = sender_id AND (
      -- User is bin owner
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      -- User is a bin member
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  );

-- Policy: Users can delete their own messages (soft delete)
-- Note: We'll handle soft delete by updating is_deleted, which is covered by the update policy above

-- Step 8: Create index on bin_id for faster queries
CREATE INDEX IF NOT EXISTS idx_bin_messages_bin_id ON bin_messages(bin_id);
CREATE INDEX IF NOT EXISTS idx_bin_messages_created_at ON bin_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bin_messages_sender_id ON bin_messages(sender_id);

