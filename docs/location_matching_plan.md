## Location-Based Interest Matching Plan

This plan adds privacy-conscious device location to improve matching: connect users with similar interests who are physically nearby. It covers product flow, permissions, schema, RLS, mobile configuration, client logic, proximity calculations, and rollout/testing.

### Goals
- **Respect privacy**: Ask only when needed; store minimal, coarsened location; clear user consent and controls.
- **Accurate enough to be useful**: City/neighborhood-level precision is sufficient for matching (0.5–10 km radius buckets).
- **Performant matching**: Combine distance with existing interest similarity (embeddings/cluster) to sort nearby peers.
- **Fresh on app open**: Refresh location automatically on app open/resume (with sensible rate limits and no repeated prompts).

---

## 1) Product & UX

- **When to ask**
  - Prompt after initial graph creation (or on first visit to the "Community" tab): “Share approximate location to find people near you who share your interests.”
  - Offer Skip; re-prompt later with a lightweight reminder if skipped.
- **Setting controls**
  - Profile Settings: toggle “Share location for matching” with precision dropdown: Off / Approximate (city) / Precise (street-level).
  - Allow “Update location now” action.
- **Transparency**
  - Explain what’s collected (coarse lat/lng rounded or geohash) and how it’s used (matching only), stored, and retention.

---

## 2) Mobile Permissions & Configuration

### iOS (Info.plist)
- Add keys with human-friendly rationale:
  - `NSLocationWhenInUseUsageDescription`
  - (Optional) `NSLocationAlwaysAndWhenInUseUsageDescription` if we ever add background updates (not needed initially)
- Respect Precise vs Approximate choice. Start with When-In-Use only.

### Android (AndroidManifest.xml)
- Add permissions:
  - `ACCESS_COARSE_LOCATION` (approximate)
  - `ACCESS_FINE_LOCATION` (precise)
  - Only if background needed later: `ACCESS_BACKGROUND_LOCATION`
- Handle runtime permission requests; detect if Location Services are disabled and show enable prompt.

### Flutter dependencies
- Use `geolocator` (or `location`) for cross-platform location and permissions.
- Optional: `geocoding` for reverse geocoding (city, country) if needed in UI copy, not stored by default.

---

## 3) Data Model (Supabase)

We’ll store both a quick-match geospatial key and optional numeric lat/lng.

```sql
-- Locations table keyed to auth.users
create table if not exists public.user_locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  latitude double precision,
  longitude double precision,
  -- 5–7 char geohash (approx 4.9km down to 153m); configurable by precision
  geohash text,
  precision smallint not null default 5 check (precision between 3 and 8),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.user_locations enable row level security;
drop policy if exists "read own location" on public.user_locations;
create policy "read own location" on public.user_locations
  for select using (auth.uid() = user_id);

drop policy if exists "upsert own location" on public.user_locations;
create policy "upsert own location" on public.user_locations
  for insert with check (auth.uid() = user_id);

drop policy if exists "update own location" on public.user_locations;
create policy "update own location" on public.user_locations
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Indexes for proximity filtering by geohash prefix
create index if not exists idx_user_locations_geohash on public.user_locations(geohash);
```

Notes:
- For stricter privacy, store only `geohash` (rounded) and omit lat/lng; compute distance approximately from geohash neighbors.
- If high-fidelity distance is required in the future, consider PostGIS and `geography(Point,4326)` with `ST_DWithin`.

---

## 4) Client Flow (Flutter)

### Request & Save
0. On app open/resume: if user opted-in and last update is stale, attempt refresh (no extra prompt if already granted).
1. Prompt user → request permission via `geolocator` (only when first needed or when the user enables sharing).
2. Fetch position with desired accuracy (approximate by using low `LocationAccuracy` or rounding).
3. Compute a geohash at chosen precision (e.g., 5–6 chars default).
4. Upsert `public.user_locations { user_id, lat, lng, geohash, precision }`.
5. Cache locally (timestamp and last geohash). Refresh if:
   - Last update > 24h, or
   - App moved > 200m (compare last vs new), or
   - User taps “Update now”.

### Precision options
- Off: delete row in `user_locations` or set nulls; user excluded from proximity matching.
- Approximate: round lat/lng and use geohash length 5 (≈4.9 km cell).
- Precise: geohash length 7 (≈153 m cell) and LocationAccuracy.high (with consent).

### UI hooks
- Profile Settings: “Share location for matching” (Off/Approx/Precise), “Update now”, last updated timestamp.
- Community/Discover list: show distance chip if both parties share location.

### App open refresh strategy
- Triggers: app launch, app becomes active (resumed), auth session changes.
- Debounce/rate limit: at most one refresh every 15 minutes unless user explicitly taps “Update now”.
- Steps on trigger:
  - If sharing disabled → no-op.
  - Check permission state; if denied → surface unobtrusive CTA in Community, no system prompt.
  - Try `getLastKnownPosition`; if sufficiently fresh (<30m old) and moved >200m since last stored, use it.
  - Otherwise call `getCurrentPosition` with timeout (e.g., 8s) and `LocationAccuracy.low` for approximate; fall back gracefully.
  - Round/encode to geohash, upsert if changed.

---

## 5) Matching Logic

We combine interest similarity with proximity.

### Inputs
- Interest similarity (existing): from `public.user_embeddings` cosine similarity or cluster proximity.
- Proximity: compute via geohash neighbors or Haversine on lat/lng.

### Candidate generation (efficient)
- Use geohash prefix to select users in same cell and neighboring cells (8 neighbors).
- Limit to N candidates per neighbor cell to cap cost (e.g., top 200).

### Scoring
```
score = w_interest * normalize(similarity) + w_distance * normalize(proximity)

where proximity = max(0, 1 - (distance_km / radius_km))
e.g., radius_km = 10, w_interest = 0.7, w_distance = 0.3
```

### Output
- Return sorted list with `{ user_id, similarity, distance_km, score }`.
- Use thresholding to hide very-low-score matches.

---

## 6) Backend Implementation (Supabase Edge Function)

Create an Edge Function `nearby_matches`:
- Input: `{ user_id, radius_km = 10, limit = 50 }` (defaults configurable).
- Steps:
  1. Read caller’s `user_locations` row; fail gracefully if missing.
  2. Build geohash neighbor set from caller’s geohash.
  3. Query `user_locations` where geohash in neighbors and `user_id != caller`.
  4. Join with `user_embeddings` (same `source='youtube'`) to compute similarity vs caller’s vector.
  5. Compute distance (approx by geohash or Haversine if lat/lng present).
  6. Score and sort; return top `limit`.
- RLS:
  - Function runs with service role; returns minimal fields (no raw coordinates if not necessary).

Security/Privacy:
- Return obfuscated distance (e.g., rounded to 0.1–1.0 km) and never the other user’s raw lat/lng without explicit consent.
- Enforce mutual visibility if required (both must enable sharing).

---

## 7) Analytics & Rate Limits

- Track opt-in rate, fetch success rate, average update age.
- Rate-limit updates (e.g., not more than once per 15 minutes) to conserve battery and avoid abuse.

---

## 8) Testing Plan

### Unit
- Geohash encode/decode and neighbor set generation.
- Scoring normalization and weighting.

### Integration
- Permission flows: granted, denied, permanently denied, services off.
- Upsert path to `user_locations` and retrieval in Edge Function.
- Matching correctness for crafted test data (near vs far, similar vs dissimilar interests).

### Manual/UAT
- On device: toggle approximate vs precise; verify distances and candidate set shift.
- Performance: match results < 300ms for 10km radius with 10k users in region (sampled dataset).

---

## 9) Rollout Steps

1. Add `geolocator` to `pubspec.yaml`; configure iOS `Info.plist` and Android Manifest permissions.
2. Create `public.user_locations` table, RLS, indexes; deploy SQL.
3. Implement client permission + one-shot update flow in Settings; add “Share location” toggle.
4. Add app-open refresh hook: in `main.dart`/`AuthGate`, and via `WidgetsBindingObserver` to capture `resumed`.
5. Implement Edge Function `nearby_matches` and secure it with service role; expose RPC wrapper if desired.
6. Integrate “Discover nearby” in Community: call function and display matches with distance chips.
7. Replace hardcoded stars on `StarMapPage` with live data (see Section 11).
8. Telemetry & error reporting; ship to a small beta cohort.
9. Expand to production after validation; monitor opt-in and match quality.

---

## 10) Future Enhancements

- Background/periodic location updates (with strict rate limits and opt-in).
- City-level bins to power local community feeds or events.
- Heatmap for cluster density (client computes from coarse buckets only).
- Privacy modes: “match by city only”, “hide distance”, “show within N km”.

---

## 11) Star Map Integration (Replace Hardcoded Stars)

Objective: populate `StarMapPage` with real users instead of static data.

Data sources
- Current user: `public.profiles` for `full_name`, `avatar_url`, `star_color`; user’s `user_locations` for geohash; embeddings for similarity.
- Nearby users: Edge Function `nearby_matches` returning `{ user_id, distance_km, similarity, score }`.

Client mapping
- For each result, fetch profile fields (batched select) to render:
  - Name → `StarData.name`
  - Avatar (public URL from `avatar_url` path) → `StarData.avatarUrl`
  - Color (`star_color`) → applied via `ColorFilter` for the star icon
  - Position: keep existing layout algorithm; use similarity/distance to vary size/pulse if desired

Realtime updates
- Subscribe to `public.profiles` changes for the current user to reflect star color/name/avatar updates live (already implemented for color).
- Optional: subscribe to location/profile changes of visible neighbors with a narrow channel or periodic refresh to avoid fan-out.

Fallbacks
- If location sharing is off, populate the map with cluster-similar users (top-N by interest similarity) without distance chips.
- If insufficient neighbors, blend cluster neighbors with any available nearby users to keep the map populated.

Performance
- Page-size results (e.g., 50–100 users), lazy image loading, and memoized profile lookups.
- Debounce refreshes and avoid over-subscribing realtime channels.
