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

---

### Embedding-driven Assignments (Cohorts)

Use existing user embeddings and cluster assignments to create interest-aware cohorts that map to tables. This augments the admin flow without changing client contracts.

- Source data
  - Reuse vectors and `cluster_id` generated during `LoadingPage` via `embedUserYouTubeProfile(...)` and `assignClusterForUser()`; stored in Supabase.
  - Optional: compute centroids and similarities with pgvector for higher quality grouping.

- v1 cohorting (simple and reliable)
  - Cohorts A/B/C = stable partition of users into three groups using one of:
    - `cluster_id % 3`, or
    - nearest of 3 preselected centroids (k-means K=3), then balance counts.
  - Persist (optional, for admin targeting and audit):
    - `segments` (id: 'A'|'B'|'C', name, criteria jsonb)
    - `user_segments` (user_id, segment_id)
  - Admin selects audience `segment` ('A','B','C') to switch tables per cohort.

- Rotation schedule (3 rounds)
  - Round 1: A→X, B→Y, C→Z
  - Round 2: A→Y, B→Z, C→X
  - Round 3: A→Z, B→X, C→Y
  - Implement as a precomputed map in the admin UI or a helper in the switch function.

- APIs & contracts
  - Unchanged. `POST /api/admin/assignment/switch` already supports `audience: segment`.

- Migration (optional to enable segments)
  - Add `segments`, `user_segments`, optionally `assignment_segment` if we later store per-segment current table.
  - Pre-event script/function to populate cohorts from embeddings and ensure near-equal sizes.

- Testing
  - Dry-run cohorting on sample users; verify near-equal split and interest coherence.
  - Run the “Final Manual Test: 6-User Rotation” with two users per cohort to validate rotation and realtime behavior.

### Strict Execution Checklist for Cursor (follow in order, no steps skipped)

Read carefully. Perform each step exactly as written, commit between phases, and run listed tests before advancing. Do not auto-refactor unrelated code. Keep auth and loading UX unchanged.

#### Phase 0 — Skeleton navigation and pages (no backend calls)

1) Add pages and services (skeletons only)
   - Create `lib/pages/assignment_page.dart` with a static UI that renders: "Go to Table X" and a small placeholder history. No network.
   - Create `lib/pages/admin_switch_page.dart` with disabled [X][Y][Z] buttons, audience dropdown (all), message input, and a disabled "Send & Notify".
   - Create `lib/services/assignment_service.dart` with stubbed methods that return static data and a `Stream` controller for fake events.
   - Create `lib/services/push_service.dart` with no-op methods (`requestPermission`, `registerToken`).

2) Update routing (only target screen changes)
   - Edit `lib/pages/auth_gate.dart`: replace `CommunityPage` with `AssignmentPage` in the final branch.
   - Edit `lib/pages/loading_page.dart`: change `_navigateToCommunity()` to navigate to `AssignmentPage` (rename helper accordingly).
   - Do not delete `CommunityPage`/`ServerPage` yet; just remove them from primary navigation.

3) Build & manual sanity test
   - Run the app; sign in → ensure `LoadingPage` still works; on continue, the `AssignmentPage` appears with static text.

Definition of Done (Phase 0)
- App flow: Login → Loading → Assignment (static). No crashes. No regressions to login/loading.

Tests to run (Phase 0)
```bash
flutter analyze
flutter test  # should pass (even if no tests yet)
```

---

#### Phase 1 — API contracts + realtime (in-memory/stub backend)

1) Edge Functions (stubs)
   - Create directories:
     - `supabase/functions/assignment-current/index.ts`
     - `supabase/functions/assignment-switch/index.ts`
   - Implement in-memory variable `current_table` initialized to 'X'.
   - `GET assignment-current`: return `{ table_label: current_table, updated_at: now, scope: 'global' }`.
   - `POST assignment-switch` (admin-only): validate input, update `current_table`, publish realtime event `assignment.changed` with `{ table_label, ts }`, return success. For now, skip DB and push.

2) Realtime channel
   - Use a broadcast channel named `assignment`.
   - Publisher: `assignment-switch` after updating `current_table`.

3) Client service wiring
   - In `lib/services/assignment_service.dart`, implement real `fetchCurrent()` calling the function URL and `subscribeAssignment()` using Supabase Realtime.
   - In `lib/pages/assignment_page.dart`, replace stub with real fetch+subscribe and small history (max 2).

4) Admin UI enablement
   - In `lib/pages/admin_switch_page.dart`, enable the buttons to call `AssignmentService.adminSwitch(...)`. UI remains available, but server still enforces admin.

Definition of Done (Phase 1)
- Admin switch changes the label on all connected clients within ~1s via realtime. No DB writes yet. Push is not involved.

Tests to run (Phase 1)
```bash
# Start functions locally (supabase CLI) and app
# In a separate shell, call APIs:
curl -sS http://localhost:54321/functions/v1/assignment-current | jq
curl -sS -X POST http://localhost:54321/functions/v1/assignment-switch \
  -H 'Content-Type: application/json' \
  -d '{"table_label":"Y","audience":"all"}' | jq
# Verify clients update to Y in realtime
```

---

#### Phase 2 — Push token registration + test send

1) Client push setup abstraction
   - Expand `lib/services/push_service.dart` to request permission, obtain a token (platform-specific), and call `POST /api/push/register`.
   - On `AssignmentPage` mount (or after successful login), prompt for notifications; if granted, register token via the endpoint.

2) Edge Functions for push
   - Add `supabase/functions/push-register/index.ts` to save `{ user_id, platform, token, web? }` into `push_tokens`.
   - Add `supabase/functions/push-test/index.ts` (admin-only) to send a test push to a chosen token/user; log result (stdout for now).

3) Minimal provider integration (keep real-send optional until Phase 3)
   - Wire the client to register tokens successfully.
   - `push-test` can be a no-op send at this phase or return a simulated success to validate the flow.

Definition of Done (Phase 2)
- Client can obtain permission and register a token server-side. Admin can invoke `push-test` and get a successful response path.

Tests to run (Phase 2)
```bash
# Register (from device logs confirm request). Also directly:
curl -sS -X POST http://localhost:54321/functions/v1/push-register \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <user_jwt>' \
  -d '{"platform":"web","token":"demo-token"}' | jq

# Admin-only test send (expect ok)
curl -sS -X POST http://localhost:54321/functions/v1/push-test \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <admin_jwt>' \
  -d '{"token":"demo-token","message":"Hello"}' | jq
```

---

#### Phase 3 — Persistence + push delivery (production wiring)

1) Database: add tables and policies (update `supabase/schema.sql`)
   - Create `assignment_global`, `push_tokens`, `broadcasts` with indices and RLS as defined above.
   - Seed `assignment_global` with id=1 and a default `current_table`.

2) Edge Functions: move from memory to DB
   - `assignment-current`: read from `assignment_global`.
   - `assignment-switch`: write to `assignment_global`, insert into `broadcasts`, publish realtime, trigger FCM push, then update `broadcasts.status`.

3) Push provider (FCM)
   - Load secrets from env; send notifications with payload containing `{ table_label, message? }`.
   - Mobile/web: ensure tapping the notification opens the app to `AssignmentPage`.

4) Client polish
   - Finalize `AssignmentPage` UI states (loading, offline, history, haptic).
   - Admin page: display last 5 broadcasts or at least last `updated_at` and target label.

Definition of Done (Phase 3)
- Admin switch persists to DB, fires realtime, and (if configured) sends FCM. Clients update instantly; optional push is received on at least one platform.

Tests to run (Phase 3)
```bash
# DB verification
psql $SUPABASE_DB_URL -c "select current_table, updated_at from assignment_global;"

# API behavior
curl -sS http://localhost:54321/functions/v1/assignment-current | jq
curl -sS -X POST http://localhost:54321/functions/v1/assignment-switch \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <admin_jwt>' \
  -d '{"table_label":"Z","audience":"all","message":"Go to Z"}' | jq

# Push delivery (observe device/browser)
```

---

#### Phase 4 — Security, rate limits, docs, and sign-off

1) Enforce admin role server-side on `assignment-switch` and `push-test`. Add simple per-user rate limits.
2) Validate Origin/Referer for admin POSTs when used from web.
3) Add README setup steps (env keys, platform configs).
4) Final acceptance review against criteria.

Definition of Done (Phase 4)
- All criteria in section 14 satisfied. Rollback tested: disabling push still leaves realtime working.

Tests to run (Phase 4)
```bash
# Negative tests (must fail):
# 1) Non-admin calling assignment-switch
curl -sS -X POST http://localhost:54321/functions/v1/assignment-switch \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <non_admin_jwt>' \
  -d '{"table_label":"X","audience":"all"}' | jq
# Expect 403

# 2) Invalid payload
curl -sS -X POST http://localhost:54321/functions/v1/assignment-switch \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <admin_jwt>' \
  -d '{"table_label":"Q"}' | jq
# Expect 400
```

---

### CI/Local test matrix (run before merging each phase)

- Lint/static analysis
  - `flutter analyze`
  - Consider `dart format --set-exit-if-changed .` in CI.

- Unit tests (add progressively)
  - Assignment service parses API response correctly.
  - Admin service blocks without admin token (mock).

- Integration checks
  - Realtime event causes UI update < 1s (log timestamps in client).
  - Push register endpoint stores token; test endpoint returns success.

- Manual E2E
  - Admin sets Y → all clients show “Go to Table Y” and receive push if enabled.

---

### Rollback Procedure

- Disable push sending by toggling an env flag in functions; keep realtime enabled.
- If functions fail, clients still render the last fetched assignment. Admin page should display error status for broadcasts.

---

### Instruction to Cursor

Cursor, follow these steps in very strict manner:
- Execute phases strictly in order: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4.
- After each numbered step, run the listed tests and stop if any fail.
- Do not refactor unrelated code.
- Do not change `SignInPage`, `LoadingPage` visuals, or the timer.
- Keep commits small and labeled by phase and step.
- If a step requires credentials or external config, annotate the file and pause for keys rather than hardcoding.

---

### Final Manual Test: 6-User Rotation (Acceptance Exercise)

This test is intentionally manual to mimic the real event experience with multiple concurrent clients.

Prerequisites
- 6 distinct signed-in sessions (any mix of iOS, Android, and Web). For Web, use separate browsers or profiles/Incognito so each holds its own session and push permission.
- Admin account with access to `/admin/switch`.
- Push configured on at least one platform (others may rely on realtime only).

Procedure
1) Prepare clients
   - Open the app on 6 devices/sessions and sign in with Google.
   - Ensure each client is on `AssignmentPage` and shows the same current label (e.g., X).
2) Round 1: Switch to X
   - From `/admin/switch`, choose `X`, audience `all`, message "Go to Table X" and Send.
   - Verify on all 6 clients:
     - The label updates to “Go to Table X” within ~1s (realtime).
     - Push notification arrives on devices with push enabled.
3) Round 2: Switch to Y
   - Send `Y` to `all` with an optional message.
   - Verify all 6 clients update to Y and the history shows the previous table.
4) Round 3: Switch to Z
   - Send `Z` to `all`.
   - Verify all 6 clients update to Z and the history lists last two (X, then Y) in the correct order.
5) Timing metrics
   - For each round, record `published_at` (admin response) and the first on-screen update time on a representative client. Target average time-to-switch ≤ 1 second.
6) Offline case (resilience)
   - Put one client offline before a switch; perform a switch; bring it back online and confirm it reconciles to the latest label via initial GET or realtime catch-up.
7) Delivery outcomes
   - Check `broadcasts` for status and errors (if any). Confirm push success count aligns with the number of devices with push enabled.

Pass Criteria
- All 6 clients reflect X → Y → Z correctly, with history showing the last two assignments.
- Average time-to-switch ≤ 1s across rounds (realtime).
- Push notifications delivered on at least one configured platform; absence of push does not block realtime correctness.
- Offline client reconciles to the latest assignment when it reconnects.

Note: This is a manual test by design. Do not automate; run it at the end of Phase 3 before sign-off in Phase 4.
