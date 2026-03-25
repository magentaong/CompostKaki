-- Owner's explanation when marking a completion as "not done properly"
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS revert_reason TEXT;

COMMENT ON COLUMN tasks.revert_reason IS 'Reason from task owner when rejecting a completion; shown when task is open again until a new completion is submitted';
