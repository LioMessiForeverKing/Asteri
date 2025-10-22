-- Core tables
-- Enable pgvector (run once per database)
create extension if not exists vector;
create table if not exists public.youtube_subscriptions (
  user_id uuid not null references auth.users(id) on delete cascade,
  channel_id text not null,
  title text,
  thumbnail_url text,
  inserted_at timestamptz default now(),
  primary key (user_id, channel_id)
);

create table if not exists public.youtube_liked_videos (
  user_id uuid not null references auth.users(id) on delete cascade,
  video_id text not null,
  title text,
  channel_title text,
  thumbnail_url text,
  published_at timestamptz,
  inserted_at timestamptz default now(),
  primary key (user_id, video_id)
);

-- Optional: track per-user sync timestamps and counts
create table if not exists public.user_sync_status (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_successful_sync timestamptz,
  subs_count integer,
  likes_count integer,
  updated_at timestamptz default now()
);

-- Per-user embedding vector (stores only aggregated user vector for YouTube)
-- text-embedding-3-large has 3072 dimensions
create table if not exists public.user_embeddings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  source text not null default 'youtube',
  vector vector(3072) not null,
  updated_at timestamptz default now()
);

-- RLS
alter table public.youtube_subscriptions enable row level security;
alter table public.youtube_liked_videos enable row level security;
alter table public.user_sync_status enable row level security;
alter table public.user_embeddings enable row level security;

-- youtube_subscriptions policies (drop if exists, then create)
drop policy if exists "own rows read" on public.youtube_subscriptions;
create policy "own rows read" on public.youtube_subscriptions
  for select using (auth.uid() = user_id);

drop policy if exists "own rows upsert" on public.youtube_subscriptions;
create policy "own rows upsert" on public.youtube_subscriptions
  for insert with check (auth.uid() = user_id);

drop policy if exists "own rows update" on public.youtube_subscriptions;
create policy "own rows update" on public.youtube_subscriptions
  for update using (auth.uid() = user_id);

-- youtube_liked_videos policies
drop policy if exists "own rows read" on public.youtube_liked_videos;
create policy "own rows read" on public.youtube_liked_videos
  for select using (auth.uid() = user_id);

drop policy if exists "own rows upsert" on public.youtube_liked_videos;
create policy "own rows upsert" on public.youtube_liked_videos
  for insert with check (auth.uid() = user_id);

drop policy if exists "own rows update" on public.youtube_liked_videos;
create policy "own rows update" on public.youtube_liked_videos
  for update using (auth.uid() = user_id);

-- user_sync_status policies
drop policy if exists "own row read" on public.user_sync_status;
create policy "own row read" on public.user_sync_status
  for select using (auth.uid() = user_id);

drop policy if exists "own row upsert" on public.user_sync_status;
create policy "own row upsert" on public.user_sync_status
  for insert with check (auth.uid() = user_id);

drop policy if exists "own row update" on public.user_sync_status;
create policy "own row update" on public.user_sync_status
  for update using (auth.uid() = user_id);

-- user_embeddings policies
drop policy if exists "own row read" on public.user_embeddings;
create policy "own row read" on public.user_embeddings
  for select using (auth.uid() = user_id);

drop policy if exists "own row upsert" on public.user_embeddings;
create policy "own row upsert" on public.user_embeddings
  for insert with check (auth.uid() = user_id);

drop policy if exists "own row update" on public.user_embeddings;
create policy "own row update" on public.user_embeddings
  for update using (auth.uid() = user_id);

-- Indexes
create index if not exists idx_youtube_subscriptions_user_id on public.youtube_subscriptions(user_id);
create index if not exists idx_youtube_liked_videos_user_id on public.youtube_liked_videos(user_id);
create index if not exists idx_user_embeddings_user_id on public.user_embeddings(user_id);

-- ================================
-- Assignment scheduling (Phase 3)
-- ================================

-- Stores the active round number for the event (1,2,3). Single row id=1.
create table if not exists public.current_round (
  id integer primary key default 1,
  round smallint not null default 1 check (round in (1,2,3)),
  updated_at timestamptz not null default now()
);

-- Each user's assigned table per round.
create table if not exists public.user_rounds (
  user_id uuid not null references auth.users(id) on delete cascade,
  round smallint not null check (round in (1,2,3)),
  table_label text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, round)
);

-- RLS
alter table public.current_round enable row level security;
alter table public.user_rounds enable row level security;

-- Anyone can read the current round (client needs to know which to show)
drop policy if exists "read current round" on public.current_round;
create policy "read current round" on public.current_round
  for select using (true);

-- Users can read only their own schedules
drop policy if exists "read own schedule" on public.user_rounds;
create policy "read own schedule" on public.user_rounds
  for select using (auth.uid() = user_id);

-- Note: Inserts/updates are performed by service role Edge Functions and bypass RLS.

-- Indexes
create index if not exists idx_user_rounds_user_id on public.user_rounds(user_id);
create index if not exists idx_user_rounds_round on public.user_rounds(round);

