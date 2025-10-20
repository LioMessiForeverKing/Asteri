### Table Switching & Admin-triggered Push — Implementation Plan

This document defines how we will add a master-controlled, real‑time table assignment system with optional push notifications, while preserving existing login and loading experiences.

---

### 1) Repo Recon

- Relevant auth and routing files
  - `lib/services/auth_service.dart` — Google OAuth + Supabase session. Keep unchanged.
  - `lib/pages/auth_gate.dart` — decides `SignInPage` vs `LoadingPage` vs `CommunityPage`. We will later route to `AssignmentPage` instead of `CommunityPage`.
  - `lib/main.dart` — Supabase initialization and app root.

- Loading (keep as‑is)
  - `lib/pages/loading_page.dart` — Interest graph pipeline and final navigation. UX remains; only the post‑loading navigation target will change to `AssignmentPage`.

- Timer (no changes)
  - `lib/pages/timer_page.dart` — Countdown UI; not touched.

- "Community/Profile" surfaces to replace in navigation
  - `lib/pages/community_page.dart` — Will be replaced in navigation by `AssignmentPage`.
  - `lib/pages/server_page.dart` — Chat-like demo; removed from primary nav.
  - `lib/services/profile_service.dart` — Can stay; not on main path.

- Services used by loading
  - `lib/services/youtube_service.dart`, `lib/services/openai_service.dart` — Used by `LoadingPage`; leave intact.

- Supabase Edge Functions (present, unrelated to table switching)
  - `supabase/functions/assign_cluster`, `embed_youtube`, `summarize_passions` — No changes needed.

---

### 2) Information Architecture

- User screens
  - Login (`SignInPage`) → Loading (`LoadingPage`) → Assignment (`AssignmentPage`).
  - Assignment shows a single instruction: “Go to Table X/Y/Z”, updates in real time, and keeps a tiny history (last two).

- Admin control surface
  - Route: `/admin/switch` → `AdminSwitchPage` (minimal UI) in the Flutter app.
  - Backend enforces access (admin role); client may hide the route for non‑admins but must not rely on that for security.

---

### 3) Data Model (minimal)

Recommendation: v1 uses a global assignment. Later we can add segment‑based assignments without breaking clients.

- `users` (reuse Supabase auth)
  - `id` uuid (from auth), `auth_provider` text, `last_seen` timestamptz, `interests` jsonb (optional future).

- `push_tokens`
  - `id` uuid pk, `user_id` uuid fk, `platform` text ('ios'|'android'|'web'), `token` text, `created_at` timestamptz, `revoked_at` timestamptz nullable.

- `assignment_global`
  - `id` int pk (1 row enforced), `current_table` text enum ('X'|'Y'|'Z'), `updated_at` timestamptz, `source` text ('admin').

- `broadcasts`
  - `id` uuid pk, `payload` jsonb ({ table_label, audience, message? }), `audience` text ('all'|'segment'), `status` text ('queued'|'sent'|'failed'|'partial'), `created_at` timestamptz, `error` text nullable.

Optional (future)
- `segments`, `assignment_segment`, `user_segments` for cohort targeting.

---

### 4) APIs & Contracts

APIs will be implemented as Supabase Edge Functions. For clarity, we use `/api/...` aliases here:

- GET `/api/assignment/current`
  - Response 200:
    ```json
    { "table_label": "X", "updated_at": "2025-10-20T08:21:00Z", "scope": "global" }
    ```
  - Errors: 500.

- POST `/api/admin/assignment/switch` (admin‑only)
  - Request:
    ```json
    { "table_label": "Y", "audience": "all", "message": "Head to Table Y now" }
    ```
  - Side effects: persist to `assignment_global` (or segment), insert into `broadcasts` (status flow), publish realtime `assignment.changed`, trigger push.
  - Response 200:
    ```json
    { "ok": true, "broadcast_id": "uuid", "table_label": "Y", "audience": "all", "published_at": "2025-10-20T08:22:11Z" }
    ```
  - Errors: 400, 401, 403, 409, 500.

- POST `/api/push/register`
  - Request:
    ```json
    { "platform": "ios", "token": "fcm_or_apns_token", "web": { "endpoint": "optional", "p256dh": "optional", "auth": "optional" } }
    ```
  - Response 200: `{ "ok": true }`
  - Errors: 400, 401, 500.

- POST `/api/push/test` (admin‑only)
  - Request:
    ```json
    { "user_id": "uuid-or-null", "token": "optional", "message": "Test notification" }
    ```
  - Response 200: `{ "ok": true, "result": "sent" }`
  - Errors: 400, 401, 403, 500.

Notes
- Auth via Supabase JWT; admin role checked inside functions (user metadata or `user_roles` table).

---

### 5) Real‑time Delivery

- Transport: Supabase Realtime broadcast channel `assignment`.
- Event: `assignment.changed` with payload `{ "table_label": "X|Y|Z", "ts": "ISO-8601" }`.
- Client (Assignment Screen):
  - On mount: fetch current assignment via GET.
  - Subscribe to channel; on event, update label instantly, append to on‑screen history (max 2), optionally vibrate/haptic.

---

### 6) Push Notification Strategy

- Default provider: Firebase Cloud Messaging (FCM) for iOS/Android/Web.
- Flutter libs (proposal; not installed yet): `firebase_core`, `firebase_messaging`, optional `flutter_local_notifications` for in‑app fallback.
- Web: FCM Web (service worker in `web/firebase-messaging-sw.js`). Provider‑agnostic abstraction so we can swap to native VAPID later.
- Server: Edge Functions invoke FCM HTTP v1 using service account secrets.

Required env/config
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, `FCM_SENDER_ID`, `FCM_VAPID_KEY` (web). Native platform configs (`GoogleService-Info.plist`, `google-services.json`).

---

### 7) Admin Control Surface

- Route/Page: `/admin/switch` → `AdminSwitchPage`.
- UI: buttons [X], [Y], [Z]; audience dropdown (all, placeholder for segments); optional message input; “Send & Notify”; list last 5 broadcasts with status.
- Access: backend‑enforced admin role; UI hiding is cosmetic only.
- Audit: insert row into `broadcasts` with final status and error details if any.

---

### 8) Assignment Screen UX Spec

- Minimal, readable, full‑bleed card.
- Headline: “Go to Table X”.
- Subtle secondary line reserved for future copy.
- Small history: “Previously: Y → Z” (max two, most recent first).
- States: loading spinner on first fetch; offline banner with last known assignment; gentle notification permission prompt; haptic on change where available.

---

### 9) Security & Permissions

- Admin endpoints: Supabase JWT verification + role check; rate‑limited (e.g., 10/min per admin).
- CSRF: validate Origin/Referer for admin POSTs on web; native apps unaffected.
- RLS policies:
  - `assignment_global`: read for all; write admins only.
  - `push_tokens`: user can manage own tokens; admins read for delivery.
  - `broadcasts`: read admins.
- Data minimization: store only necessary tokens; add revoke/unregister.

---

### 10) Analytics & Logging

- Log on server: broadcast create/update, FCM responses.
- Log on client: receipt timestamps for `assignment.changed` events.
- KPIs: time‑to‑switch (admin click → UI update), push sent/failed counts, realtime receipt rate.

---

### 11) Testing Plan

- Unit: payload validation and role checks for admin APIs.
- Integration: Admin sets Y → DB persist → realtime publish → client UI updates and records receipt → push delivered.
- Manual: web/mobile permission flows, background/foreground push behavior, tap‑through opens Assignment Screen.

---

### 12) Migration Plan

- Navigation changes
  - Replace `CommunityPage` in `auth_gate.dart` and `loading_page.dart` with `AssignmentPage`.
  - Remove `ServerPage` from primary navigation.

- New Flutter files
  - `lib/pages/assignment_page.dart`
  - `lib/pages/admin_switch_page.dart`
  - `lib/services/assignment_service.dart`
  - `lib/services/push_service.dart`

- New Edge Functions
  - `supabase/functions/assignment-current/index.ts`
  - `supabase/functions/assignment-switch/index.ts`
  - `supabase/functions/push-register/index.ts`
  - `supabase/functions/push-test/index.ts`

- Database additions (extend `supabase/schema.sql`)
  - Tables: `assignment_global`, `broadcasts`, `push_tokens`; RLS policies and indices.

- Config keys
  - Add Firebase/FCM keys to environment; add native platform config files.

---

### 13) Work Breakdown (staged; no coding yet)

- Phase 0: Skeleton
  - `AssignmentPage` stub (reads current assignment via mock). `AdminSwitchPage` UI shell. Wire routing from `AuthGate` and `LoadingPage` to `AssignmentPage`.

- Phase 1: Contracts + in‑memory
  - Implement Edge Functions with in‑memory `current_table`; client subscribes to realtime channel stub.

- Phase 2: Push registration
  - Implement `POST /api/push/register`; client permission + token registration flows. `POST /api/push/test` for targeted test.

- Phase 3: Persistence + end‑to‑end
  - Move to Postgres tables; finalize switch API to persist, publish realtime, and trigger FCM; polish UI and admin log; add guards and rate limits.

- Phase 4: Docs & handoff
  - Update `README.md` with environment setup and admin usage.

---

### 14) Acceptance Criteria

- Endpoints, payloads, and file paths are fixed as defined above.
- Security model (admin role with Supabase) is documented and feasible.
- Push provider choice (FCM) and required env vars are enumerated.
- Rollback: if push is disabled, realtime updates still work via Supabase Realtime events.
