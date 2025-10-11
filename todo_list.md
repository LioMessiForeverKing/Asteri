## Asteri MVP TODO (YouTube Focus)

### 1) Auth & Scopes
- [ ] Confirm Google OAuth client IDs match YouTube API project
- [x] Verify scope `https://www.googleapis.com/auth/youtube.readonly` is requested
- [x] Handle silent sign-in and token refresh on app start

### 2) Mobile App: YouTube Data Sync → Supabase
- [x] Fetch ALL subscriptions via pagination (already implemented)
- [x] Fetch liked videos via pagination, cap at 800 (already implemented)
- [x] Add retry/backoff on 429/5xx responses
- [x] Add sync timestamps per user (store last_successful_sync)
- [x] Add manual “Full sync to Supabase” UI action (already implemented)
- [x] Show counts and errors in UI (already implemented basic message)

### 3) Supabase Schema & RLS
- [x] Ensure tables exist (see README):
  - [x] `youtube_subscriptions(user_id, channel_id, title, thumbnail_url, inserted_at)`
  - [x] `youtube_liked_videos(user_id, video_id, title, channel_title, thumbnail_url, published_at, inserted_at)`
- [x] Enable RLS on both tables
- [x] Add RLS policies (select/insert/update) scoped to `auth.uid()`
- [x] Create indexes: `(user_id, channel_id)` and `(user_id, video_id)` where needed

### 4) Optional Enrichment (Improves embeddings later)
- [ ] Add `youtube_channels` table (id, title, description, thumbnails, updated_at)
- [ ] Add `youtube_videos` table (id, title, description, category_id, updated_at)
- [ ] Batch resolve channel descriptions via `channels.list`
- [ ] Batch resolve video descriptions via `videos.list`
- [ ] De-duplicate and cache results to save quota

### 5) Embedding Pipeline (Backend)
- [ ] Choose runtime: Supabase Edge Functions or small worker (Node/Python)
- [ ] Secure secrets: Supabase service key + OpenAI API key
- [ ] Table: `youtube_item_embeddings(id, user_id, source, item_id, vector, created_at)`
- [ ] Table: `user_embeddings(user_id, source='youtube', vector, updated_at)`
- [ ] Endpoint/Job: embed new subscriptions (channel titles/descriptions)
- [ ] Endpoint/Job: embed new liked videos (titles/descriptions)
- [ ] Batch embeddings and handle rate limiting
- [ ] Compute per-user vector: mean-pool; weight liked(0.6) + subs(0.4)
- [ ] Upsert into `user_embeddings` for source 'youtube'

### 6) Clustering Job (Backend)
- [ ] Input: 100 users’ `user_embeddings` (source 'youtube')
- [ ] Run K-Means with k=10, fixed seed for stability
- [ ] Table: `clusters(cluster_id, centroid_vector, created_at)`
- [ ] Table: `user_clusters(user_id, cluster_id, similarity_score, created_at)`
- [ ] Compute cosine similarity to centroids; store `similarity_score`
- [ ] Schedule nightly or on-demand clustering job

### 7) App/Product Surfaces
- [ ] Display assigned `cluster_id` in UI
- [ ] Show top contributing channels/videos (simple “why” explanation)
- [ ] Provide a refresh button to re-sync and re-embed (calls backend)

### 8) Monitoring, Quotas, Cost Controls
- [ ] Log YouTube API usage and failures (status, endpoint, duration)
- [ ] Log embedding counts/tokens per run
- [ ] Cap liked videos at 800 (configurable), fetch all subs
- [ ] Only embed deltas (new items since last run)

### 9) QA & Validation
- [ ] Verify subscription and liked counts for 2–5 test users
- [ ] Spot-check embedded vectors (non-zero norms)
- [ ] Validate clusters are ~10 users each and stable
- [ ] Run backfill for initial 100 users

### 10) Future (Not in current scope)
- [ ] Pinterest OAuth + data ingestion
- [ ] Pinterest embeddings (image + text), weighting and merge
- [ ] Multi-source final vector: `0.6*YouTube + 0.4*Pinterest`
- [ ] Unified clustering across sources


