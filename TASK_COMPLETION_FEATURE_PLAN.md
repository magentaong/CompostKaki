# Task Completion Feature Implementation Plan

## Overview
This feature adds task completion verification, reverting, and comprehensive notifications.

## Database Changes

### 1. Add completion_status to tasks table
- `completion_status`: `pending_check`, `checked`, `reverted`, or NULL
- `completed_at`: Timestamp when task was completed
- `reverted_at`: Timestamp when task was reverted
- `checked_at`: Timestamp when task was checked by owner

### 2. Update notification types
- Add `task_accepted` notification type
- Add `task_reverted` notification type
- Keep existing `task_completed` type

## Feature Breakdown

### Phase 1: Database & Backend
1. ✅ SQL migration for completion_status
2. Add TaskService methods:
   - `checkTask()` - Owner confirms completion
   - `revertTask()` - Owner rejects completion, subtracts XP
3. Update `completeTask()` to set `completion_status = 'pending_check'` and `completed_at`

### Phase 2: UI - Tasks Page
1. Add "Completed Tasks" section (green highlight)
2. Filter completed tasks: `status == 'completed'`
3. Show completed tasks with green background/border
4. Update TaskCard to highlight completed tasks

### Phase 3: UI - Task Detail Dialog
1. Add "Checked" button (only for task owner, when `completion_status == 'pending_check'`)
2. Add "Revert" / "Not Done Properly" button (only for task owner, when `completion_status == 'pending_check'`)
3. Show completion details (who completed, when)

### Phase 4: Notifications
1. Add bell icon to AppBar (all screens, top right)
2. Show notification badge count
3. Create notification screen/page
4. Add notification triggers:
   - Task accepted → notify task owner
   - Task completed → notify task owner (already exists)
   - Task reverted → notify completer

### Phase 5: XP Logic
1. Track XP awarded on completion
2. On revert: Subtract XP from completer (same amount they earned)
3. Add XP subtraction method to XPService

## Implementation Order
1. Database schema (SQL)
2. TaskService methods (checkTask, revertTask)
3. Update completeTask to set completion_status
4. Update Tasks page UI (completed section)
5. Update TaskDetailDialog (buttons)
6. Add bell icon to AppBar
7. Create notification screen
8. Add notification triggers
9. XP subtraction logic


