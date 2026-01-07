# Fix Email Template - Make Links Clickable

## Problem
Email shows "Reset Password" text but the link is **not clickable**. This means the email template is missing proper HTML anchor tags.

## Solution: Update Supabase Email Template

### Step 1: Go to Email Template
1. Go to **Supabase Dashboard**
2. Navigate to **Authentication** → **Email** → **Templates**
3. Click on **"Reset password"** template

### Step 2: Update Template HTML

**Current (Wrong - Not Clickable):**
```
Follow this link to reset your password: Reset Password
```

**Correct (Clickable Link):**
```html
<h2>Reset Password</h2>
<p>Follow this link to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
```

### Step 3: Full Template

Replace the entire template body with:

```html
<h2>Reset Password</h2>
<p>Follow this link to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #00796B; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">Reset Password</a></p>
<p>This link will expire in 1 hour.</p>
<p>If you didn't request this, please ignore this email.</p>
```

### Step 4: Subject Line
```
Reset Your Password
```

## Important Notes

### Must Use HTML Anchor Tag
- ✅ **Correct**: `<a href="{{ .ConfirmationURL }}">Reset Password</a>`
- ❌ **Wrong**: `Reset Password` (plain text)
- ❌ **Wrong**: `{{ .ConfirmationURL }}` (just the URL, not clickable)

### Must Use ConfirmationURL Variable
- ✅ **Correct**: `{{ .ConfirmationURL }}` (includes tokens automatically)
- ❌ **Wrong**: Hardcoded URL like `https://compostkaki.vercel.app/reset-password`

## Why Links Aren't Clickable

The email template is likely:
1. **Plain text** instead of HTML
2. **Missing `<a>` tag** around the link
3. **Using wrong variable** (not `{{ .ConfirmationURL }}`)

## After Updating Template

1. **Save the template** in Supabase
2. **Request a NEW password reset** (old emails won't update)
3. **Check new email** - link should be clickable
4. **Click link** - should work!

## Testing

After updating:
- ✅ Link should be **blue and underlined** (or styled button)
- ✅ **Clickable** in email client
- ✅ Opens browser/app when clicked
- ✅ Contains tokens in URL

## Summary

- ❌ **Current**: Plain text, not clickable
- ✅ **Fix**: Use HTML `<a>` tag with `{{ .ConfirmationURL }}`
- ✅ **Result**: Clickable link that works!

Update the template and request a new password reset email! 🎉

