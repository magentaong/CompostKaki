# Resubmitting Your App After Rejection 📱

This guide walks you through resubmitting your app to the App Store after a rejection.

## Step 1: Review the Rejection Reason

1. **Check your email** - Apple sends detailed rejection reasons via email
2. **Go to App Store Connect** → Your App → **App Store** tab
3. Look for the **"Resolution Center"** section - this shows:
   - What was rejected
   - Specific issues to address
   - Steps to fix them

## Step 2: Address the Rejection Issues

Common rejection reasons and fixes:

### Privacy Policy Issues
- **Issue:** Missing or incomplete privacy policy
- **Fix:** Ensure your privacy policy URL is accessible and covers:
  - Data collection (user accounts, photos, location if used)
  - Third-party services (Supabase)
  - Data usage and storage
  - User rights

### App Functionality Issues
- **Issue:** App crashes, broken features, or incomplete functionality
- **Fix:** 
  - Test thoroughly on physical device
  - Fix any bugs or crashes
  - Upload a new build if fixes were made

### Missing Information
- **Issue:** Incomplete app description, missing screenshots, or missing support URL
- **Fix:** Complete all required fields in App Store Connect

### Guideline Violations
- **Issue:** App violates App Store Review Guidelines
- **Fix:** Review the specific guideline mentioned and make necessary changes

## Step 3: Upload a New Build (If Needed)

**If you made code changes to fix rejection issues:**

1. **Update version/build number** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+3  # Increment build number
   ```

2. **Build and upload:**
   ```bash
   cd /Users/itzsihui/CompostKaki/flutter
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

3. **Archive and upload in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Select **"Any iOS Device"**
   - **Product** → **Archive**
   - **Distribute App** → **App Store Connect** → **Upload**

**If no code changes needed** (e.g., only metadata fixes):
- You can use your existing build (1.0.0 build 2) that's already uploaded

## Step 4: Update App Store Listing (If Needed)

1. **Go to App Store Connect** → Your App → **App Store** tab
2. **Update any required fields:**
   - App description
   - Screenshots
   - Privacy policy URL
   - Support URL
   - Keywords
   - App icon

## Step 5: Resubmit for Review

1. **Go to App Store Connect** → Your App → **App Store** tab

2. **Select your version** (should show "Ready to Submit" or "Rejected")

3. **Select the build:**
   - If you uploaded a new build, wait for it to process (10-30 minutes)
   - Select the build from the dropdown

4. **Update "What's New in This Version":**
   - For resubmissions, mention what you fixed:
   ```
   Fixed issues identified in App Review:
   - [List the fixes you made]
   - Updated privacy policy
   - Fixed [specific issue]
   ```

5. **Answer App Review questions** (if prompted):
   - Does your app use encryption?
   - Does your app access user data?
   - Export compliance questions

6. **Add notes for reviewer** (if applicable):
   - In the "Notes" section, explain what you fixed
   - Reference the rejection reason if helpful
   - Provide test account credentials if needed

7. **Click "Submit for Review"**

## Step 6: Monitor Review Status

- **Check App Store Connect** regularly for status updates
- **Watch your email** for notifications
- **Typical review time:** 24-48 hours (can be faster for resubmissions)

## Quick Resubmission Checklist

- [ ] Reviewed rejection reason in Resolution Center
- [ ] Fixed all identified issues
- [ ] Uploaded new build (if code changes were made)
- [ ] Updated app metadata (if needed)
- [ ] Selected correct build in App Store Connect
- [ ] Updated "What's New" section
- [ ] Added reviewer notes (if helpful)
- [ ] Clicked "Submit for Review"

## If You Need to Respond to Apple

If you disagree with the rejection or need clarification:

1. **Go to Resolution Center** in App Store Connect
2. **Click "Reply"** to respond to the reviewer
3. **Be specific and professional** in your response
4. **Provide evidence** if you believe the rejection was incorrect

## Common Resubmission Scenarios

### Scenario 1: Only Metadata Issues (No Code Changes)
- Fix metadata in App Store Connect
- Use existing build
- Resubmit immediately

### Scenario 2: Code Changes Required
- Fix code issues
- Increment build number
- Upload new build
- Wait for processing
- Resubmit

### Scenario 3: Need to Provide More Information
- Add notes in Resolution Center
- Provide test account credentials
- Clarify app functionality
- Resubmit

## Tips for Successful Resubmission

1. **Address every point** mentioned in the rejection
2. **Be thorough** - don't skip any fixes
3. **Test your app** before resubmitting
4. **Be clear** in your notes to reviewers
5. **Don't rush** - make sure everything is fixed

## Need Help?

- Check [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Review [App Store Connect Help](https://help.apple.com/app-store-connect/)
- See your main submission guide: `APP_STORE_SUBMISSION.md`

---

Good luck with your resubmission! 🚀

