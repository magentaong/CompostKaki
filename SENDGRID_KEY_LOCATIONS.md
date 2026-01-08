# Where to Update SendGrid API Key

## For OTP Password Reset Flow

### ✅ Vercel (REQUIRED)
**Location:** Vercel Dashboard → Your Project → Settings → Environment Variables

**Variable:** `SENDGRID_API_KEY`

**Why:** The `/api/auth/send-reset-otp` route in Vercel calls SendGrid API directly to send OTP emails.

**Action:** ✅ **UPDATE THIS** - This is the only place needed for OTP emails.

---

## For Other Supabase Emails (Optional)

### ⚠️ Supabase SMTP Settings (OPTIONAL - Only if using)

**Location:** Supabase Dashboard → Authentication → Settings → SMTP Settings

**Why:** If you configured Supabase to use SendGrid SMTP for:
- Magic link emails
- Email confirmation emails
- Password reset emails (old flow)
- Other Supabase auth emails

**When to update:**
- ✅ Update if Supabase SMTP is configured with SendGrid
- ❌ Don't update if Supabase uses its built-in email service
- ❌ Don't update if Supabase SMTP uses a different provider (Gmail, etc.)

**How to check:**
1. Go to Supabase Dashboard → Authentication → Settings
2. Look for "SMTP Settings" or "Email Provider"
3. If it shows "SendGrid" or has SendGrid credentials → Update it
4. If it shows "Built-in" or another provider → Don't update

**Note:** The OTP password reset flow **does NOT use Supabase SMTP** - it uses the Vercel API route that calls SendGrid directly. So updating Supabase SMTP is only needed if you're using it for other emails.

---

## Summary

### For OTP Password Reset (Current Flow)
- ✅ **Vercel** - REQUIRED - Update `SENDGRID_API_KEY` environment variable
- ❌ **Supabase** - NOT NEEDED - OTP flow doesn't use Supabase SMTP

### For Other Supabase Emails (If Applicable)
- ⚠️ **Supabase SMTP** - OPTIONAL - Only if Supabase is configured to use SendGrid

---

## Quick Checklist

- [ ] Updated `SENDGRID_API_KEY` in Vercel ✅ (REQUIRED for OTP)
- [ ] Checked if Supabase SMTP uses SendGrid (optional)
- [ ] Updated Supabase SMTP if needed (optional)
- [ ] Redeployed Vercel after updating environment variable

---

## Current Setup

Based on your implementation:
- **OTP emails** → Sent via Vercel API route → SendGrid API (uses Vercel env var)
- **Other Supabase emails** → Check Supabase SMTP settings to see if SendGrid is used

**Bottom line:** For the OTP password reset flow, you **only need to update Vercel**. Supabase SMTP is separate and only needed if you're using it for other emails.

