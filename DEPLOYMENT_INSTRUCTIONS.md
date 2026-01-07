# Password Reset - Deployment Instructions

## ✅ Changes Made

1. **`middleware.ts`** - NEW FILE
   - Intercepts requests BEFORE page loads
   - Detects password reset tokens
   - Redirects to reset-password page

2. **`app/page.tsx`** - UPDATED
   - Added token detection on home page
   - Immediate redirect using `window.location.href`

3. **`app/reset-password/page.tsx`** - UPDATED
   - Calls verify API when token detected

4. **`app/api/auth/verify-token/route.ts`** - NEW FILE
   - Verifies tokens server-side
   - Gets session tokens from Supabase
   - Redirects with tokens in hash

## 🚀 Deployment Steps

### Step 1: Commit Changes
```bash
git add .
git commit -m "Add password reset middleware and token verification"
```

### Step 2: Push to GitHub
```bash
git push origin main
```

### Step 3: Wait for Vercel Deployment
- Vercel will automatically deploy when you push to GitHub
- Check Vercel dashboard for deployment status
- Wait for deployment to complete (usually 1-2 minutes)

### Step 4: Test
1. **Request NEW password reset** from app (old links won't work)
2. **Click the email link**
3. **Should redirect to reset-password page** (via middleware)
4. **Then redirect to app** with tokens

## 🔍 How to Verify Deployment

1. Check Vercel logs:
   - Go to Vercel Dashboard → Your Project → Logs
   - Look for `🔄 [MIDDLEWARE]` logs when clicking reset link

2. Test the flow:
   - Click reset link
   - Should see redirect happen immediately
   - No flash of home page

## ⚠️ Important Notes

- **Middleware only works AFTER deployment** - it's server-side code
- **Old password reset links won't work** - request a new one
- **Test with a fresh reset email** after deployment

## 🐛 If Still Not Working

1. **Check Vercel logs** for middleware errors
2. **Verify middleware.ts is deployed** - check Vercel build logs
3. **Check browser console** for client-side errors
4. **Try incognito mode** to avoid cache issues

## 📝 Files Changed

- ✅ `middleware.ts` (NEW)
- ✅ `app/page.tsx` (UPDATED)
- ✅ `app/reset-password/page.tsx` (UPDATED)
- ✅ `app/api/auth/verify-token/route.ts` (NEW)
- ✅ `flutter/lib/services/auth_service.dart` (UPDATED)

