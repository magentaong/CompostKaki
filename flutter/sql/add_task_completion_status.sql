-- Add completion_status field to tasks table
-- This tracks whether a completed task has been checked by owner or reverted

-- Add completion_status column (pending_check, checked, reverted, or NULL for non-completed tasks)
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS completion_status TEXT CHECK (completion_status IN ('pending_check', 'checked', 'reverted'));

-- Add completed_at timestamp to track when task was completed
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add reverted_at timestamp to track when task was reverted
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS reverted_at TIMESTAMP WITH TIME ZONE;

-- Add checked_at timestamp to track when task was checked by owner
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS checked_at TIMESTAMP WITH TIME ZONE;

-- Update existing completed tasks to have pending_check status
UPDATE tasks
SET completion_status = 'pending_check'
WHERE status = 'completed' AND completion_status IS NULL;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_tasks_completion_status ON tasks(completion_status) WHERE completion_status IS NOT NULL;

