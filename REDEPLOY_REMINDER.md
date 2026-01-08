# ⚠️ IMPORTANT: Redeploy After Environment Variable Changes

## Why Redeploy?

**Environment variables are only loaded at build/deploy time**, not at runtime.

When you update environment variables in Vercel:
- ✅ The new values are saved
- ❌ But running deployments still use the OLD values
- ✅ You MUST redeploy to use the new values

## How to Redeploy

### Option 1: Manual Redeploy (Fastest)
1. Go to **Vercel Dashboard** → Your Project
2. Click **Deployments** tab
3. Find the latest deployment
4. Click the **"..."** menu (three dots)
5. Click **Redeploy**
6. Wait 1-2 minutes for deployment to complete

### Option 2: Push a Commit (Automatic)
1. Make a small change (add a comment, update README, etc.)
2. Commit and push:
   ```bash
   git add .
   git commit -m "Trigger redeploy after env var update"
   git push
   ```
3. Vercel will automatically deploy with new environment variables

## Verify It Worked

After redeploy:
1. Try requesting password reset OTP
2. Check Vercel logs - should see `📧 [SEND OTP]` messages
3. Check SendGrid Activity Feed - should see email attempts
4. Check your email inbox - should receive OTP code

## Common Mistake

❌ **Wrong:** Update env vars → Test immediately → Doesn't work
✅ **Right:** Update env vars → **Redeploy** → Test → Works!

---

**You just updated `SUPABASE_SERVICE_ROLE_KEY` - make sure to redeploy!**

