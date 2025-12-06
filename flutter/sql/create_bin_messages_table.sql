-- Create bin_messages table for chat functionality
CREATE TABLE IF NOT EXISTS bin_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bin_id UUID NOT NULL REFERENCES bins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on bin_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_bin_messages_bin_id ON bin_messages(bin_id);

-- Create index on created_at for ordering messages
CREATE INDEX IF NOT EXISTS idx_bin_messages_created_at ON bin_messages(bin_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE bin_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages for bins they are members of
CREATE POLICY "Users can view messages for their bins"
  ON bin_messages
  FOR SELECT
  USING (
    -- User is bin owner
    EXISTS (
      SELECT 1 FROM bins
      WHERE bins.id = bin_messages.bin_id
      AND bins.user_id = auth.uid()
    )
    OR
    -- User is a member of the bin
    EXISTS (
      SELECT 1 FROM bin_members
      WHERE bin_members.bin_id = bin_messages.bin_id
      AND bin_members.user_id = auth.uid()
    )
  );

-- Policy: Users can send messages to bins they are members of
CREATE POLICY "Users can send messages to their bins"
  ON bin_messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      -- User is bin owner
      EXISTS (
        SELECT 1 FROM bins
        WHERE bins.id = bin_messages.bin_id
        AND bins.user_id = auth.uid()
      )
      OR
      -- User is a member of the bin
      EXISTS (
        SELECT 1 FROM bin_members
        WHERE bin_members.bin_id = bin_messages.bin_id
        AND bin_members.user_id = auth.uid()
      )
    )
  );

-- Policy: Users can update their own messages
CREATE POLICY "Users can update their own messages"
  ON bin_messages
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
  ON bin_messages
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_bin_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER update_bin_messages_updated_at
  BEFORE UPDATE ON bin_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_bin_messages_updated_at();

-- Enable realtime for bin_messages table
ALTER PUBLICATION supabase_realtime ADD TABLE bin_messages;

-- Add comment to table
COMMENT ON TABLE bin_messages IS 'Chat messages for each bin. Members can send and receive messages in real-time.';

