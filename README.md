# takeapp
## Supabase schema

The app expects these tables to exist in your Supabase project:

```sql
-- youtube_subscriptions: one row per (user, channel)
create table if not exists public.youtube_subscriptions (
  user_id uuid not null references auth.users(id) on delete cascade,
  channel_id text not null,
  title text,
  thumbnail_url text,
  inserted_at timestamp with time zone default now(),
  primary key (user_id, channel_id)
);

-- youtube_liked_videos: one row per (user, video)
create table if not exists public.youtube_liked_videos (
  user_id uuid not null references auth.users(id) on delete cascade,
  video_id text not null,
  title text,
  channel_title text,
  thumbnail_url text,
  published_at timestamptz,
  inserted_at timestamp with time zone default now(),
  primary key (user_id, video_id)
);

-- RLS policies (adjust as needed)
alter table public.youtube_subscriptions enable row level security;
alter table public.youtube_liked_videos enable row level security;

create policy "own rows read" on public.youtube_subscriptions for select using (auth.uid() = user_id);
create policy "own rows upsert" on public.youtube_subscriptions for insert with check (auth.uid() = user_id);
create policy "own rows update" on public.youtube_subscriptions for update using (auth.uid() = user_id);

create policy "own rows read" on public.youtube_liked_videos for select using (auth.uid() = user_id);
create policy "own rows upsert" on public.youtube_liked_videos for insert with check (auth.uid() = user_id);
create policy "own rows update" on public.youtube_liked_videos for update using (auth.uid() = user_id);
```

Run this SQL in Supabase SQL editor before using the sync feature.

## Setup

1) Add your Supabase URL and anon key in `lib/utils/constants.dart`.
2) Add your Google OAuth Client IDs (Web and iOS) in `lib/utils/constants.dart`.
3) Ensure the Google OAuth project has YouTube Data API v3 enabled and the client IDs match.

# takeapp

A new Flutter project.
