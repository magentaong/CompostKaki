# How to Add SENDGRID_API_KEY to Vercel

## Step-by-Step Instructions

### 1. Get Your SendGrid API Key
1. Go to [SendGrid Dashboard](https://app.sendgrid.com/)
2. Navigate to **Settings** → **API Keys**
3. Click **Create API Key**
4. Give it a name (e.g., "CompostKaki Production")
5. Select **Full Access** (or at least "Mail Send" permissions)
6. Click **Create & View**
7. **Copy the API key immediately** (you won't be able to see it again!

### 2. Add to Vercel Environment Variables

#### Option A: Via Vercel Dashboard (Recommended)
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your **CompostKaki** project
3. Click on **Settings** (gear icon)
4. Click on **Environment Variables** in the left sidebar
5. Click **Add New**
6. Enter:
   - **Key**: `SENDGRID_API_KEY`
   - **Value**: (paste your SendGrid API key)
   - **Environment**: Select **Production**, **Preview**, and **Development** (or just Production if you only want it in production)
7. Click **Save**
8. **IMPORTANT**: You need to redeploy for the changes to take effect!

#### Option B: Via Vercel CLI
```bash
# Install Vercel CLI if you haven't
npm i -g vercel

# Login to Vercel
vercel login

# Add the environment variable
vercel env add SENDGRID_API_KEY

# When prompted:
# - Enter your SendGrid API key
# - Select environments (Production, Preview, Development)

# Redeploy
vercel --prod
```

### 3. Redeploy Your Application
After adding the environment variable, you **must redeploy** for it to take effect:

1. Go to Vercel Dashboard → Your Project
2. Click on **Deployments** tab
3. Click the **"..."** menu on the latest deployment
4. Click **Redeploy**
5. Or push a new commit to trigger automatic deployment

### 4. Verify It's Working
1. Check Vercel deployment logs to see if the variable is loaded
2. Test the password reset flow in your app
3. Check SendGrid Activity Feed to see if emails are being sent

## Troubleshooting

### Still not receiving emails?
1. **Check SendGrid Activity Feed**:
   - Go to SendGrid Dashboard → Activity
   - Look for your email in the feed
   - Check if there are any errors

2. **Check Vercel Logs**:
   - Go to Vercel Dashboard → Your Project → Functions
   - Check the logs for `/api/auth/send-reset-otp`
   - Look for any errors

3. **Verify API Key Permissions**:
   - Make sure the API key has "Mail Send" permissions
   - Try creating a new API key with full access

4. **Check Spam Folder**:
   - Emails might be going to spam
   - Check your spam/junk folder

5. **Verify Sender Authentication**:
   - Make sure `compostkaki@gmail.com` is verified in SendGrid
   - Go to SendGrid → Settings → Sender Authentication

## Quick Test
After setting up, you can test by:
1. Requesting password reset from your app
2. Check SendGrid Activity Feed immediately
3. If email appears in SendGrid but not in inbox, check spam folder

