## Discord-like Community MVP — Plan (Local-first)

### Goal
- On login, skip countdown and land on a Welcome screen: "Welcome Ayen" with a single assigned community: Music Community.
- Open a Discord-style server view where:
  - Header shows: Music Community, 1/3 users.
  - Member strip shows 1 active user (Ayen) and 2 inactive placeholders.
  - Text channels list (general, introductions) on overlay/modal.
  - Local-only chat: messages persist on device; no backend required for MVP.

### User Story (Happy Path)
1) Ayen signs in → immediately sees Welcome screen: "Welcome Ayen — based on your interests we added you to: Music Community" and an "Enter" button.
2) Tapping Enter opens a Discord-like server view with a messages panel and input at the bottom.
3) Ayen types messages; they appear instantly, persist locally, and survive app restarts.
4) Member count shows 1/3; two ghost members appear as inactive (greyed initials + "Inactive").

### Scope (MVP)
- Local-only data: no network writes; safe to demo offline.
- One community, one device, one user.
- Lightweight design aligned with Asteria theme.

---

## Architecture

### Data Models
- Community
  - id: string ("music")
  - name: string ("Music Community")
  - maxMembers: int (3)
  - members: List<Member> (first is current user)
- Member
  - id: string
  - displayName: string
  - initial: string
  - isActive: bool
- Message
  - id: string (local uuid)
  - communityId: string
  - authorId: string
  - authorName: string
  - text: string
  - createdAt: DateTime

### Local Storage
- Use shared_preferences or hive (prefer Hive if already present; else shared_preferences for speed).
- Keys:
  - community.messages.music = JSON array of Message
  - community.meta.music = Community metadata (name, members)

### Navigation Flow
- AuthGate: if signed in → WelcomeCommunityPage (feature flag). Else → SignInPage.
- WelcomeCommunityPage → ServerPage (Music) on Continue.
- TimerPage kept behind feature flag for quick rollback.

---

## UI/UX

### WelcomeCommunityPage
- Large greeting: "Welcome Ayen"
- Subheading: "Based on your interests, here’s your community"
- Card: Music Community
  - Icon: 🎵
  - Members: 1/3
  - Short blurb: "Share tracks, playlists, and discoveries"
- Primary button: "Enter Community"

### ServerPage (Discord-like)
- AppBar: Music Community — 1/3 users
- Body: Stack
  - Main column
    - Messages list (reverse chronological, newest at bottom)
    - Input row: TextField + Send button
  - Channels overlay (modal): general, introductions
- Members footer/row: circles for 3 slots
  - Slot 1: Ayen (initial A), active
  - Slot 2–3: Inactive placeholders (dimmed), labels "Inactive"

### Visual/Interaction Details
- Smooth fade/scale transitions (use AsteriaTheme animation utilities).
- Message bubbles: paper-card style with subtle elevation.
- Auto-scroll to bottom on send.

---

## Implementation Steps

### 0) Switch & Safety
- Add feature flag `showWelcomeFlow=true` (fallback to TimerPage).

### 1) Models & Storage
- Create models: Community, Member, Message.
- Local repository: `LocalCommunityStore` with methods:
  - loadCommunity(), saveCommunity()
  - loadMessages(), appendMessage()

### 2) Welcome Flow
- Create `WelcomeCommunityPage` with greeting and Music community card.
- Route from `AuthGate` to this page when flag enabled.

### 3) Server UI
- Reuse/extend `ServerPage` layout for Discord vibe.
- Add messages panel + input (local send → append + persist).
- Add members strip with 3 slots and states (active/inactive).
- Add channels overlay (UI only; both channels route to same list for MVP).

### 4) Persistence & UX Polish
- On send: write to local store, refresh list, scroll to bottom.
- On app start: hydrate from local store.
- Add small empty-state copy for new chat.

### 5) QA Checklist
- Welcome shows immediately after login.
- Member count shows 1/3 consistently.
- Messages persist across restarts.
- Offline works.
- Feature flag toggles back to TimerPage instantly.

---

## Future (Post-MVP)
- Replace local store with Supabase tables and real-time.
- Replace ghost members when real users join; show presence.
- AI-generated channel suggestions and prompts.
- Multi-community support from clustering pipeline.

---

## Deliverables
- WelcomeCommunityPage (new)
- ServerPage enhancements: local chat, members strip, channels overlay
- LocalCommunityStore (shared_preferences-based)
- Feature flag + AuthGate route update

---

## Rollback Plan
- Flip `showWelcomeFlow=false` to return to current Timer-based flow with no code changes to data.



