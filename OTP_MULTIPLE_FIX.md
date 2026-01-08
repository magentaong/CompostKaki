# OTP Multiple Requests & Verification Fix

## Problem
1. ❌ Only one OTP per email (database used `email` as PRIMARY KEY)
2. ❌ New OTP requests replaced old ones (UPSERT)
3. ❌ Verification failed if user requested a new OTP before using the old one
4. ❌ No rate limiting - users could spam OTP requests
5. ❌ Email case sensitivity issues

## Solution

### 1. Database Schema Update
**File**: `supabase/migrations/update_password_reset_otps_multiple.sql`

**Changes**:
- ✅ Removed `email` as PRIMARY KEY
- ✅ Added `id` (UUID) as PRIMARY KEY
- ✅ Added `used_at` timestamp to track when OTP was used
- ✅ Allows multiple OTPs per email
- ✅ Added indexes for better query performance

**To Apply**:
1. Go to Supabase Dashboard → SQL Editor
2. Run the migration: `supabase/migrations/update_password_reset_otps_multiple.sql`
3. Or use Supabase CLI: `supabase migration up`

### 2. Send OTP API Updates
**File**: `app/api/auth/send-reset-otp/route.ts`

**Changes**:
- ✅ **Rate Limiting**: Prevents requesting new OTP within 30 seconds
- ✅ **Multiple OTPs**: Uses `INSERT` instead of `UPSERT` - creates new OTP each time
- ✅ **Email Normalization**: Converts email to lowercase for consistency
- ✅ **Better Error Messages**: Returns 429 status with wait time if rate limited

**Rate Limiting Logic**:
```typescript
// Check if OTP was requested in last 30 seconds
// If yes, return error: "Please wait X seconds before requesting another OTP code."
```

### 3. Verify OTP API Updates
**File**: `app/api/auth/verify-reset-otp/route.ts`

**Changes**:
- ✅ **Multiple OTP Support**: Finds most recent unused, non-expired OTP
- ✅ **Email Normalization**: Converts email to lowercase
- ✅ **Soft Delete**: Marks OTP as `used_at` instead of deleting (audit trail)
- ✅ **Better Query**: Filters by `used_at IS NULL` and `expires_at > NOW()`

**Verification Logic**:
```typescript
// Find most recent unused, non-expired OTP for email
// Order by created_at DESC, limit 1
// Mark as used when verified
```

## How It Works Now

### Requesting OTP
1. User enters email → taps "Send OTP Code"
2. API checks: Was OTP requested in last 30 seconds?
   - ✅ **No**: Generate new OTP, store in DB, send email
   - ❌ **Yes**: Return error "Please wait X seconds..."
3. Each request creates a **new OTP row** (doesn't replace old ones)

### Verifying OTP
1. User enters OTP code → taps "Verify OTP"
2. API finds: Most recent unused, non-expired OTP for that email
3. If found and matches:
   - ✅ Mark OTP as used (`used_at = NOW()`)
   - ✅ Create recovery session
   - ✅ Return tokens
4. If not found:
   - ❌ Return "Invalid OTP code"

### Multiple OTPs Per User
- ✅ User can request multiple OTPs
- ✅ Each OTP is stored separately
- ✅ Only the most recent unused OTP is checked during verification
- ✅ Old OTPs remain in database (for audit trail)

## Database Schema

**Before**:
```sql
CREATE TABLE password_reset_otps (
  email TEXT PRIMARY KEY,  -- Only one OTP per email!
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**After**:
```sql
CREATE TABLE password_reset_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,  -- Multiple OTPs per email allowed!
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ NULL  -- Track when OTP was used
);
```

## Testing

### Test Case 1: Multiple OTP Requests
1. Request OTP → Receive email with code `123456`
2. Request OTP again (within 30s) → Should get rate limit error
3. Wait 30+ seconds → Request OTP again → Receive email with code `789012`
4. Both OTPs should be in database
5. Verify with `789012` → Should work ✅
6. Verify with `123456` → Should work ✅ (if not expired)

### Test Case 2: Rate Limiting
1. Request OTP → Success
2. Immediately request again → Error: "Please wait 30 seconds..."
3. Wait 30 seconds → Request again → Success

### Test Case 3: Email Case Sensitivity
1. Request OTP with `User@Example.com`
2. Verify OTP with `user@example.com` → Should work ✅
3. Both are normalized to lowercase

## Migration Steps

1. **Backup existing data** (if any):
   ```sql
   SELECT * FROM password_reset_otps;
   ```

2. **Run migration**:
   - Via Supabase Dashboard: SQL Editor → Paste migration SQL → Run
   - Via CLI: `supabase migration up`

3. **Verify migration**:
   ```sql
   -- Check table structure
   \d password_reset_otps
   
   -- Check indexes
   SELECT indexname FROM pg_indexes WHERE tablename = 'password_reset_otps';
   ```

4. **Test the flow**:
   - Request OTP
   - Check database - should see new row
   - Request OTP again (after 30s) - should see another row
   - Verify OTP - should mark as used

## Notes

- ⚠️ **Old OTPs are not deleted** - they remain for audit trail
- ⚠️ **Rate limiting is 30 seconds** - can be adjusted in code
- ⚠️ **OTP expiration is still 10 minutes** - unchanged
- ✅ **Email normalization** ensures case-insensitive matching
- ✅ **Multiple OTPs** allow users to request new codes if email is delayed

## Status
✅ All changes implemented
✅ Ready for migration
✅ Rate limiting: 30 seconds
✅ Multiple OTPs per email: Enabled
