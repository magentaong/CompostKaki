# CompostConnect – Instructions & Feature Reference

## Theme & Problem Statement

**Theme:**
CompostConnect is a community-driven platform designed to empower urban residents—especially those in high-density cities like Singapore—to compost food waste efficiently, share knowledge, and build sustainable habits.

**Problem We're Solving:**
- Urban residents generate large amounts of food waste, but lack space, knowledge, or community support to compost effectively.
- There's a need for localized, practical guides and a supportive network to help beginners and enthusiasts succeed in composting.

**Target Segment:**
- Urban dwellers (e.g., HDB residents in Singapore, apartment/condo residents in other cities)
- Beginners interested in composting
- Community garden organizers
- Eco-conscious individuals seeking practical, local solutions

---

## Features & Flows

### 1. **Authentication (MVP)**
- **Sign Up / Sign In:** Users can register or log in with email and password.
- **No Email Verification (MVP):** Users can access the app immediately after sign-up (email confirmation is disabled for MVP).
- **Session Handling:** The app checks for an existing session and keeps users logged in until they sign out.
- **Sign Out:** Available from the profile screen.

**Flow:**
1. User lands on the app and sees a sign-in/sign-up form.
2. User registers or logs in.
3. On success, user is taken to the main app screens.

---

### 2. **Home Screen**
- **Welcome Banner:** App name, tagline, and quick access to notifications and profile.
- **Tabs:** Switch between "Piles" (personal compost pile log) and "Community" (forum posts).

**Flow:**
1. User sees a summary of their composting activity and community updates.
2. Can navigate to other features from here.

---

### 3. **Guides & Tips**
- **Guides:** Curated, step-by-step guides for composting in urban environments (e.g., Singapore-specific tips, HDB solutions, pest prevention, community composting).
- **Tips:** Quick, actionable advice for composting success.
- **Guide Detail:** Deep dive into a selected guide, with sections and illustrations.

**Flow:**
1. User selects "Guides" from the menu.
2. Browses available guides and tips.
3. Clicks on a guide for detailed instructions.

---

### 4. **Piles**
- **Personal Compost Pile Log:** Users can track their composting progress, add entries, and view past activity for their piles.
- **Add Entry:** Log new composting actions, observations, or issues for a pile.

**Flow:**
1. User navigates to "Piles".
2. Views timeline of past pile entries.
3. Adds a new entry (e.g., "Added kitchen scraps", "Turned pile", "Observed pests").

---

### 5. **Community Forum**
- **Q&A and Sharing:** Users can post questions, share experiences, and help others.
- **Voting & Replies:** Posts can be upvoted and replied to.
- **Tagging:** Posts are tagged for easy searching (e.g., "pests", "setup", "urban").

**Flow:**
1. User navigates to "Community".
2. Browses or searches posts.
3. Creates a new post or replies to existing ones.

---

### 6. **QR Scanner (Future/Optional)**
- **Scan Compost Pile QR Codes:** For community or shared composting setups, users can scan QR codes to log activity or check pile status.

**Flow:**
1. User selects "Scanner".
2. Scans a QR code on a compost bin/pile.
3. App fetches and displays relevant data or logs the action.

---

### 7. **Profile**
- **User Info:** Displays user's name, email, and composting stats (future enhancement).
- **Sign Out:** Button to log out.

---

## Design & Theme
- **Color Palette:** Greens, teals, and earth tones for a fresh, eco-friendly feel.
- **Typography:** Modern, clean sans-serif fonts (Geist).
- **UI:** Card-based layouts, rounded corners, soft shadows, and subtle gradients.
- **Mobile-First:** Optimized for mobile and small screens.

---

## MVP Limitations
- No social login (email/password only)
- No email verification (for fast onboarding)
- No advanced user profile or settings (yet)
- No real-time chat or notifications (yet)

---

## Future Enhancements (Ideas)
- Social login (Google, Apple, etc.)
- Push/email notifications
- Real-time updates (pile status, forum)
- Advanced analytics for composting progress
- Community leaderboards
- Integration with local recycling/composting programs

---

## Reference for AI Generation
- Use this document to understand the app's purpose, flows, and user experience.
- When generating new features, keep the eco-friendly, community-driven, and urban-focused theme in mind.
- Prioritize simplicity, clarity, and accessibility in all user flows. 