-- Fix for delete message RLS policy issue
-- Run this after the main migration if delete is still failing

-- First, ensure SELECT policy allows users to see their own deleted messages
DROP POLICY IF EXISTS "Bin members can view messages" ON bin_messages;

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

-- Drop and recreate the UPDATE policy to ensure it works correctly
DROP POLICY IF EXISTS "Users can update their own messages" ON bin_messages;

-- Create UPDATE policy that allows users to update their own messages
-- This includes setting is_deleted = true (soft delete)
-- The WITH CHECK clause must allow the new row values, including is_deleted = true
CREATE POLICY "Users can update their own messages"
  ON bin_messages
  FOR UPDATE
  USING (
    -- User must be the sender and be a bin member/owner
    auth.uid() = sender_id 
    AND (
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    -- After update, user must still be the sender and bin member/owner
    -- Note: We don't check is_deleted here because that's just a data value, not a permission
    auth.uid() = sender_id
    AND (
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  );

