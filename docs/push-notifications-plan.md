## Push Notifications — Round Switching

Goal: Notify users when a round starts so they see “Go to Table …” without reopening the app.

### Overview
- Start simple with generic pushes (Option A), then upgrade to personalized messages (Option B) later.
- No database replication is required. Push complements our existing broadcast/polling.

### Option A vs Option B
- Option A (generic): Send one push to all devices, with data `{ round }`. Client computes the table or fetches it.
- Option B (personalized): Server maps each device to its user’s table and sends individualized pushes like “Go to Table X”.

---

## Step 1 — Firebase/FCM Setup
1) Create a Firebase project and enable Cloud Messaging.
2) Android:
   - Download `google-services.json` (app module).
   - Add the Google services Gradle plugin.
   - Android 13+: request `POST_NOTIFICATIONS` permission.
3) iOS:
   - Upload APNs key/certificate in Firebase → Cloud Messaging.
   - Enable Push Notifications + Background Modes (Remote notifications) in Xcode.
   - Add `GoogleService-Info.plist` to the iOS runner target.

Deliverables:
- Valid FCM credentials for both platforms.

---

## Step 2 — Database Table for Device Tokens
Create a table to store device tokens per user/device.

SQL:
```sql
create table if not exists public.user_push_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text check (platform in ('ios','android','web')),
  last_seen_at timestamptz not null default now(),
  primary key (token)
);

alter table public.user_push_tokens enable row level security;

-- Users can upsert their own tokens
drop policy if exists "upsert own token" on public.user_push_tokens;
create policy "upsert own token" on public.user_push_tokens
  for insert with check (auth.uid() = user_id);

drop policy if exists "read own tokens" on public.user_push_tokens;
create policy "read own tokens" on public.user_push_tokens
  for select using (auth.uid() = user_id);

drop policy if exists "delete own token" on public.user_push_tokens;
create policy "delete own token" on public.user_push_tokens
  for delete using (auth.uid() = user_id);
```

Notes:
- Edge Functions run with service role and can read all tokens when sending pushes.

---

## Step 3 — Store Credentials in Supabase
Add FCM credentials as Supabase Edge Function secrets.

Options:
- Legacy server key (simpler): `FCM_SERVER_KEY`.
- HTTP v1 (recommended long‑term): `GOOGLE_SERVICE_ACCOUNT_JSON` for scoped OAuth.

Example (server key):
```bash
supabase secrets set --project-ref <ref> FCM_SERVER_KEY="AAAA..."
```

---

## Step 4 — Client Registration Flow (Flutter)
What the app should do after login and on startup:
1) Request notification permission (iOS & Android 13+).
2) Get FCM token and upsert into `public.user_push_tokens` with `user_id` and `platform`.
3) Listen for token refresh and update the row.
4) On logout, delete the token row.
5) Add handlers:
   - Foreground: show an in‑app banner and update UI immediately.
   - Background/terminated: on notification tap, navigate to `AssignmentPage` and refresh current assignment.

Deliverables:
- Reliable token lifecycle: create, refresh, delete.

---

## Step 5 — Sending Pushes from the Server
Extend the existing `round-switch` function (or create a new `notify-round`):
1) After updating `public.current_round`, fetch device tokens from `public.user_push_tokens`.
2) Option A (ship first):
   - Build a multicast payload with notification:
     - title: "Round {{n}} started"
     - body: "Open Asteria to see your table"
     - data: `{ "round": "{{n}}" }`
   - Send in chunks (≤500 tokens per request) to FCM.
3) Option B (upgrade later):
   - Join `user_rounds` and `current_round` to compute `{ token -> table_label }`.
   - Send personalized notifications (title/body: “Go to Table X”, data includes `{ round, table_label }`).
4) Handle errors:
   - Remove invalid/expired tokens.
   - Log send stats (success/fail counts) for observability.

Notes:
- Keep our existing Supabase Realtime broadcast for live users; push is for background users.

---

## Step 6 — Client Receive Behavior
On receiving a push:
- Foreground: update the Assignment UI immediately; optionally show a lightweight banner.
- Background/terminated:
  - Display system notification.
  - On tap, route to `AssignmentPage` and call `assignment-current` to confirm the latest table.
  - If payload includes `round` only (Option A), compute the table locally from cached schedule or fetch via function.

---

## Step 7 — Admin UI Toggle
Enhance the Admin Switch page with a toggle:
- "Send push notification" (default: on). Pass `notify=true` to the function, so we can disable pushes for dry‑runs.

---

## Step 8 — Reliability & Privacy
- De‑duplicate tokens per device; prune on delivery errors.
- Respect user opt‑out (profile setting) by filtering tokens server‑side.
- Rate limit sends to avoid accidental spam; batch and retry with backoff.
- Secure secrets via Supabase function secrets only; never ship to clients.

---

## Step 9 — Testing Matrix
Test on real devices (simulators can’t receive APNs/FCM):
- iOS: foreground, background, terminated, locked screen.
- Android: foreground, background, terminated, doze mode.
- Multiple users across different tables for personalization.
- Notification tap routing to `AssignmentPage`.

---

## Step 10 — Rollout
1) Deploy DB changes and RLS policies.
2) Ship client with token lifecycle + handlers.
3) Add function secrets and deploy Edge Functions.
4) Enable admin toggle and run a staged test with a small cohort.
5) Monitor logs, prune invalid tokens, and then enable for all users.

---

## Future Enhancements
- Local time windows/quiet hours.
- Rich notifications with deep links and actions (e.g., “Show Map”).
- Migrate to FCM HTTP v1 with OAuth for better security and topic messaging.


