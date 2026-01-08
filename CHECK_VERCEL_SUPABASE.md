# How to Check Vercel Supabase Configuration

## Step-by-Step Guide

### 1. Go to Vercel Dashboard
1. Open [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your **CompostKaki** project
3. Click on **Settings** (gear icon in the top right)

### 2. Check Environment Variables
1. In the left sidebar, click **Environment Variables**
2. Look for these Supabase-related variables:

**Required Variables:**
- `NEXT_PUBLIC_SUPABASE_URL` - Should be something like `https://xxxxx.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` - Should be a long string starting with `eyJ...`
- `SENDGRID_API_KEY` - Your SendGrid API key

### 3. Verify Supabase Project URL

**In Vercel:**
- Check the value of `NEXT_PUBLIC_SUPABASE_URL`
- It should match your Supabase project URL

**In Supabase Dashboard:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Look at **Project URL** - it should match what's in Vercel

**Example:**
- Vercel: `NEXT_PUBLIC_SUPABASE_URL = https://tqpjrlwdgoctacfrbanf.supabase.co`
- Supabase: Project URL = `https://tqpjrlwdgoctacfrbanf.supabase.co`
- ✅ They should match!

### 4. Verify Service Role Key

**In Vercel:**
- Check the value of `SUPABASE_SERVICE_ROLE_KEY`
- Click the eye icon to reveal it (if hidden)

**In Supabase Dashboard:**
1. Go to **Settings** → **API**
2. Look at **service_role** key (under "Project API keys")
3. Click **Reveal** to see it
4. Compare with Vercel - they should match

⚠️ **Important:** The `service_role` key has admin access - keep it secret!

### 5. Check Environment Scope

Make sure the environment variables are set for the right environments:
- **Production** - For production deployments
- **Preview** - For preview deployments (pull requests)
- **Development** - For local development

**To check:**
- In Vercel Environment Variables, look at the "Environment" column
- Make sure Production is checked (at minimum)

### 6. Verify After Changes

**After updating environment variables:**
1. **Redeploy** your project:
   - Go to **Deployments** tab
   - Click **"..."** on latest deployment
   - Click **Redeploy**
2. Or push a new commit to trigger auto-deploy

**Environment variables are only loaded at build time**, so you must redeploy after changing them!

---

## Common Issues

### Issue 1: Wrong Supabase Project
**Symptoms:**
- Users not found
- Database errors
- Authentication failures

**Fix:**
- Update `NEXT_PUBLIC_SUPABASE_URL` to correct project URL
- Update `SUPABASE_SERVICE_ROLE_KEY` to correct service role key
- Redeploy

### Issue 2: Missing Environment Variables
**Symptoms:**
- "Server configuration error"
- API routes return 500 errors

**Fix:**
- Add missing environment variables
- Redeploy

### Issue 3: Wrong Environment Scope
**Symptoms:**
- Works locally but not in production
- Works in preview but not production

**Fix:**
- Check environment variable scope
- Make sure Production is selected
- Redeploy

### Issue 4: Old Values Cached
**Symptoms:**
- Changes not taking effect
- Still using old values

**Fix:**
- Redeploy after changing environment variables
- Clear Vercel cache if needed

---

## Quick Verification Checklist

- [ ] `NEXT_PUBLIC_SUPABASE_URL` matches Supabase project URL
- [ ] `SUPABASE_SERVICE_ROLE_KEY` matches Supabase service_role key
- [ ] `SENDGRID_API_KEY` is set (for OTP emails)
- [ ] Environment variables are set for Production
- [ ] Project has been redeployed after any changes

---

## How to Find Your Supabase Project Details

### Method 1: Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. You'll see:
   - **Project URL** (for `NEXT_PUBLIC_SUPABASE_URL`)
   - **service_role** key (for `SUPABASE_SERVICE_ROLE_KEY`)

### Method 2: Check Your Code
Look in your codebase for:
- `.env.local` or `.env` files (local development)
- Any configuration files that might have the Supabase URL

---

## Testing After Verification

After verifying and updating environment variables:

1. **Redeploy** your Vercel project
2. **Test the OTP flow:**
   - Request password reset
   - Check Vercel logs for `📧 [SEND OTP]` messages
   - Verify OTP is sent via SendGrid
3. **Check SendGrid Activity Feed:**
   - Go to SendGrid Dashboard → Activity
   - Look for email attempts

---

## Need Help?

If you're still having issues:
1. Check Vercel Function Logs for specific errors
2. Compare Supabase project URL in both dashboards
3. Verify service role key matches
4. Make sure you redeployed after changes

