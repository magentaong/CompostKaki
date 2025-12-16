-- Enable Row Level Security on bin_messages table (if not already enabled)
ALTER TABLE bin_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can insert their own messages" ON bin_messages;
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON bin_messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON bin_messages;
DROP POLICY IF EXISTS "Bin owners can view all messages in their bins" ON bin_messages;

-- Policy: Users can insert messages where they are the sender
CREATE POLICY "Users can insert their own messages"
  ON bin_messages
  FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Policy: Users can view messages where they are the sender or receiver
CREATE POLICY "Users can view messages they sent or received"
  ON bin_messages
  FOR SELECT
  USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

-- Policy: Users can update messages where they are the receiver (for marking as read)
CREATE POLICY "Users can update messages they received"
  ON bin_messages
  FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Policy: Bin owners can view all messages in their bins (for admin view)
CREATE POLICY "Bin owners can view all messages in their bins"
  ON bin_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bins
      WHERE bins.id = bin_messages.bin_id
      AND bins.user_id = auth.uid()
    )
  );

