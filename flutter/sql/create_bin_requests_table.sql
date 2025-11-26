-- Create bin_requests table
CREATE TABLE IF NOT EXISTS bin_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bin_id UUID NOT NULL REFERENCES bins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(bin_id, user_id, status)
);

-- Create index on bin_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_bin_requests_bin_id ON bin_requests(bin_id);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_bin_requests_user_id ON bin_requests(user_id);

-- Create index on status for filtering pending requests
CREATE INDEX IF NOT EXISTS idx_bin_requests_status ON bin_requests(status) WHERE status = 'pending';

-- Create composite index for common queries (bin_id + status)
CREATE INDEX IF NOT EXISTS idx_bin_requests_bin_status ON bin_requests(bin_id, status);

-- Enable Row Level Security
ALTER TABLE bin_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own requests
CREATE POLICY "Users can view their own requests"
  ON bin_requests
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can create their own requests
CREATE POLICY "Users can create their own requests"
  ON bin_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Bin owners can view all requests for their bins
CREATE POLICY "Bin owners can view requests for their bins"
  ON bin_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bins
      WHERE bins.id = bin_requests.bin_id
      AND bins.user_id = auth.uid()
    )
  );

-- Policy: Bin owners can update requests for their bins (approve/reject)
CREATE POLICY "Bin owners can update requests for their bins"
  ON bin_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bins
      WHERE bins.id = bin_requests.bin_id
      AND bins.user_id = auth.uid()
    )
  );

-- Policy: Bin owners can delete requests for their bins (when rejecting)
CREATE POLICY "Bin owners can delete requests for their bins"
  ON bin_requests
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM bins
      WHERE bins.id = bin_requests.bin_id
      AND bins.user_id = auth.uid()
    )
  );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_bin_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER update_bin_requests_updated_at
  BEFORE UPDATE ON bin_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_bin_requests_updated_at();

-- Add comment to table
COMMENT ON TABLE bin_requests IS 'Stores join requests for bins. Users request to join, admins approve/reject.';

