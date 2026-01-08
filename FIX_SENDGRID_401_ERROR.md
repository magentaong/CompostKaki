# Fix SendGrid 401 Error

## Error Message
```
SendGrid error: 401
"The provided authorization grant is invalid, expired, or revoked"
```

## What This Means
The SendGrid API key in Vercel is either:
- ❌ Invalid/incorrect
- ❌ Expired
- ❌ Revoked/deleted

## Solution

### Step 1: Get a New SendGrid API Key

1. Go to [SendGrid Dashboard](https://app.sendgrid.com/)
2. Navigate to **Settings** → **API Keys**
3. Check if your existing API key is still there
   - If it's there but not working → Create a new one
   - If it's missing → It was deleted, create a new one
4. Click **Create API Key**
5. Give it a name (e.g., "CompostKaki Production")
6. Select **Full Access** (or at least "Mail Send" permissions)
7. Click **Create & View**
8. **Copy the API key immediately** (you won't be able to see it again!)

### Step 2: Update Vercel Environment Variable

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your **CompostKaki** project
3. Click **Settings** → **Environment Variables**
4. Find `SENDGRID_API_KEY`
5. Click the **pencil icon** to edit
6. Paste the **new** SendGrid API key
7. Make sure **Production**, **Preview**, and **Development** are selected
8. Click **Save**

### Step 3: Redeploy

**IMPORTANT:** You must redeploy for the new API key to take effect!

**Option A: Manual Redeploy**
1. Go to **Deployments** tab
2. Click **"..."** on latest deployment
3. Click **Redeploy**

**Option B: Push a Commit**
```bash
git commit --allow-empty -m "Trigger redeploy after SendGrid API key update"
git push
```

### Step 4: Test Again

After redeploy completes:
1. Try requesting password reset OTP again
2. Check Vercel logs - should see `📧 [SEND OTP] Email sent successfully via SendGrid`
3. Check your email inbox - should receive OTP code

---

## Why API Keys Get Revoked

- **Manual deletion** - Someone deleted it in SendGrid dashboard
- **Security rotation** - Best practice to rotate keys periodically
- **Account changes** - Changes to SendGrid account settings
- **Suspicious activity** - SendGrid may revoke keys for security

---

## Prevention

1. **Document your API keys** - Keep track of which keys are used where
2. **Use descriptive names** - Name keys clearly (e.g., "CompostKaki Production")
3. **Set up alerts** - Configure SendGrid to notify you of API key changes
4. **Regular rotation** - Rotate keys every 90 days (best practice)

---

## Quick Checklist

- [ ] Created new SendGrid API key
- [ ] Updated `SENDGRID_API_KEY` in Vercel
- [ ] Selected all environments (Production, Preview, Development)
- [ ] Redeployed Vercel project
- [ ] Tested password reset flow
- [ ] Received OTP email successfully

