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

