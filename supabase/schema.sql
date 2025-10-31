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

-- ================================
-- Push notifications (device tokens)
-- ================================

create table if not exists public.user_push_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text check (platform in ('ios','android','web')),
  last_seen_at timestamptz not null default now(),
  primary key (token)
);

alter table public.user_push_tokens enable row level security;

-- Policies: users can manage their own tokens
drop policy if exists "upsert own token" on public.user_push_tokens;
drop policy if exists "insert own token" on public.user_push_tokens;
drop policy if exists "update own token" on public.user_push_tokens;
drop policy if exists "read own tokens" on public.user_push_tokens;
drop policy if exists "delete own token" on public.user_push_tokens;

-- INSERT policy for upsert
create policy "insert own token" on public.user_push_tokens
  for insert 
  with check (auth.uid() = user_id);

-- UPDATE policy for upsert (required!)
create policy "update own token" on public.user_push_tokens
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- SELECT policy
create policy "read own tokens" on public.user_push_tokens
  for select 
  using (auth.uid() = user_id);

-- DELETE policy
create policy "delete own token" on public.user_push_tokens
  for delete 
  using (auth.uid() = user_id);

-- Indexes
create index if not exists idx_user_push_tokens_user_id on public.user_push_tokens(user_id);


-- ================================
-- User profiles + avatar storage
-- ================================

-- Profiles table (keyed to auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 100),
  avatar_url text,
  star_color text not null check (star_color ~ '^#(?:[0-9a-fA-F]{3}){1,2}$'),
  interests text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Updated-at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer as $$
begin
  new.updated_at = now();
  return new;
end;$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;

-- Allow each user to read their own profile
drop policy if exists "select_own_profile" on public.profiles;
create policy "select_own_profile"
on public.profiles for select
using (auth.uid() = id);

-- Allow users to read profiles of their friends (accepted friend requests)
drop policy if exists "select_friend_profiles" on public.profiles;
create policy "select_friend_profiles"
on public.profiles for select
using (
  exists (
    select 1 from public.friend_requests fr
    where fr.status = 'accepted'
      and (
        (fr.sender_id = auth.uid() and fr.receiver_id = profiles.id)
        or
        (fr.receiver_id = auth.uid() and fr.sender_id = profiles.id)
      )
  )
);

-- Allow users to read profiles of users who sent them pending friend requests
drop policy if exists "select_pending_request_profiles" on public.profiles;
create policy "select_pending_request_profiles"
on public.profiles for select
using (
  exists (
    select 1 from public.friend_requests fr
    where fr.status = 'pending'
      and fr.receiver_id = auth.uid()
      and fr.sender_id = profiles.id
  )
);

-- Allow each user to insert their own profile
drop policy if exists "insert_own_profile" on public.profiles;
create policy "insert_own_profile"
on public.profiles for insert
with check (auth.uid() = id);

-- Allow each user to update their own profile
drop policy if exists "update_own_profile" on public.profiles;
create policy "update_own_profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- ================================
-- Storage bucket for profile avatars
-- ================================

-- Create public bucket (compatible with older storage versions)
insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true)
on conflict (id) do nothing;

-- Public read from the bucket
drop policy if exists "profile_images_public_read" on storage.objects;
create policy "profile_images_public_read"
on storage.objects for select
using (bucket_id = 'profile-images');

-- Owners (authenticated users) can insert their own objects
drop policy if exists "profile_images_insert_own" on storage.objects;
create policy "profile_images_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'profile-images' and owner = auth.uid()
);

-- Owners can update their own objects
drop policy if exists "profile_images_update_own" on storage.objects;
create policy "profile_images_update_own"
on storage.objects for update
using (
  bucket_id = 'profile-images' and owner = auth.uid()
)
with check (
  bucket_id = 'profile-images' and owner = auth.uid()
);

-- Owners can delete their own objects
drop policy if exists "profile_images_delete_own" on storage.objects;
create policy "profile_images_delete_own"
on storage.objects for delete
using (
  bucket_id = 'profile-images' and owner = auth.uid()
);

-- ================================
-- Storage bucket for message images
-- ================================

-- Create public bucket for message images
insert into storage.buckets (id, name, public)
values ('message-images', 'message-images', true)
on conflict (id) do nothing;

-- Public read from the bucket (anyone in a conversation can see images)
drop policy if exists "message_images_public_read" on storage.objects;
create policy "message_images_public_read"
on storage.objects for select
using (bucket_id = 'message-images');

-- Allow authenticated users to upload images
drop policy if exists "message_images_insert_own" on storage.objects;
create policy "message_images_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'message-images' 
  and owner = auth.uid()
);

-- Owners can update their own message images
drop policy if exists "message_images_update_own" on storage.objects;
create policy "message_images_update_own"
on storage.objects for update
using (
  bucket_id = 'message-images' and owner = auth.uid()
)
with check (
  bucket_id = 'message-images' and owner = auth.uid()
);

-- Owners can delete their own message images
drop policy if exists "message_images_delete_own" on storage.objects;
create policy "message_images_delete_own"
on storage.objects for delete
using (
  bucket_id = 'message-images' and owner = auth.uid()
);

-- ================================
-- Messaging (conversations + messages)
-- ================================

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz,
  inserted_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id bigint generated by default as identity primary key,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text,
  image_url text,
  created_at timestamptz not null default now(),
  constraint content_or_image check (content is not null or image_url is not null)
);

-- RLS
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- Policies: participants can see their conversations and messages
drop policy if exists "read own conversations" on public.conversations;
create policy "read own conversations" on public.conversations
  for select using (
    exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = id and p.user_id = auth.uid()
    )
  );

-- Allow users to create conversations (they'll add participants immediately after)
drop policy if exists "create conversations" on public.conversations;
drop policy if exists "insert conversations" on public.conversations;
drop policy if exists "users can create conversations" on public.conversations;

-- Create a policy that allows authenticated users to insert conversations
-- Using 'with check (true)' allows any authenticated user to insert
-- This matches PostgreSQL RLS best practices for permissive INSERT policies
create policy "create conversations" on public.conversations
  for insert 
  with check (true);

-- SELECT policy: Allow seeing all participants in conversations you're part of
-- This is needed to find shared conversations between users
-- Using a security definer function to avoid infinite recursion

-- Create helper function first
create or replace function public.user_is_participant_in_conversation(conv_id uuid)
returns boolean
language plpgsql
security definer
stable
as $$
begin
  return exists (
    select 1 from public.conversation_participants
    where conversation_id = conv_id
      and user_id = auth.uid()
  );
end;
$$;

grant execute on function public.user_is_participant_in_conversation(uuid) to authenticated;

-- Drop existing policies
drop policy if exists "manage participation self" on public.conversation_participants;
drop policy if exists "read participants in own conversations" on public.conversation_participants;

-- Create the SELECT policy
create policy "read participants in own conversations" on public.conversation_participants
  for select 
  using (
    -- Allow if it's your own participation record
    user_id = auth.uid()
    or
    -- OR allow if you're a participant in this conversation (using security definer function to avoid recursion)
    public.user_is_participant_in_conversation(conversation_id)
  );

drop policy if exists "update participation self" on public.conversation_participants;
create policy "update participation self" on public.conversation_participants
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "delete participation self" on public.conversation_participants;
create policy "delete participation self" on public.conversation_participants
  for delete using (user_id = auth.uid());

-- Allow inserting yourself as a participant
drop policy if exists "insert participation self" on public.conversation_participants;
create policy "insert participation self" on public.conversation_participants
  for insert with check (user_id = auth.uid());

-- Allow users to add friends as participants when creating conversations
-- This allows inserting the other user as a participant if they're friends
drop policy if exists "add friend as participant" on public.conversation_participants;
create policy "add friend as participant" on public.conversation_participants
  for insert with check (
    -- Allow if adding a friend (check if there's an accepted friend request)
    exists (
      select 1 from public.friend_requests fr
      where fr.status = 'accepted'
        and (
          (fr.sender_id = auth.uid() and fr.receiver_id = user_id)
          or
          (fr.receiver_id = auth.uid() and fr.sender_id = user_id)
        )
    )
  );

drop policy if exists "read own messages" on public.messages;
create policy "read own messages" on public.messages
  for select using (
    exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = messages.conversation_id and p.user_id = auth.uid()
    )
  );

drop policy if exists "insert own messages" on public.messages;
create policy "insert own messages" on public.messages
  for insert with check (
    sender_id = auth.uid() and exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = messages.conversation_id and p.user_id = auth.uid()
    )
  );

-- RPC function for fetching conversation summaries
create or replace function public.fetch_conversation_summaries(uid uuid)
returns table (
  conversation_id text,
  other_user_id uuid,
  other_name text,
  other_avatar_url text,
  last_message text,
  last_at timestamptz,
  unread boolean
)
language plpgsql
security definer
as $$
begin
  return query
  with user_conversations as (
    select cp.conversation_id
    from public.conversation_participants cp
    where cp.user_id = uid
  ),
  latest_messages as (
    select distinct on (m.conversation_id)
      m.conversation_id,
      m.content as last_message,
      m.created_at as last_at,
      m.sender_id
    from public.messages m
    inner join user_conversations uc on uc.conversation_id = m.conversation_id
    order by m.conversation_id, m.created_at desc
  ),
  other_participants as (
    select
      cp.conversation_id,
      cp.user_id as other_user_id,
      p.full_name as other_name,
      p.avatar_url as other_avatar_url
    from public.conversation_participants cp
    inner join user_conversations uc on uc.conversation_id = cp.conversation_id
    inner join public.profiles p on p.id = cp.user_id
    where cp.user_id != uid
  ),
  unread_counts as (
    select
      cp.conversation_id,
      case when cp.last_read_at is null then true
           when cp.last_read_at < lm.last_at then true
           else false end as unread
    from public.conversation_participants cp
    inner join latest_messages lm on lm.conversation_id = cp.conversation_id
    where cp.user_id = uid
  )
  select
    lm.conversation_id,
    op.other_user_id,
    op.other_name,
    op.other_avatar_url,
    coalesce(lm.last_message, '📷 Photo') as last_message,
    lm.last_at,
    uc.unread
  from latest_messages lm
  inner join other_participants op on op.conversation_id = lm.conversation_id
  inner join unread_counts uc on uc.conversation_id = lm.conversation_id
  order by lm.last_at desc;
end;
$$;

-- Indexes
create index if not exists idx_conversation_participants_user on public.conversation_participants(user_id);
create index if not exists idx_messages_conversation on public.messages(conversation_id, created_at desc);

-- ================================
-- Friend requests (handshake before chatting)
-- ================================

create table if not exists public.friend_requests (
  id bigint generated by default as identity primary key,
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

alter table public.friend_requests enable row level security;

-- Sender or receiver can read the request
drop policy if exists "read own friend_requests" on public.friend_requests;
create policy "read own friend_requests" on public.friend_requests
  for select using (sender_id = auth.uid() or receiver_id = auth.uid());

-- Sender can insert a new request (cannot send to self)
drop policy if exists "insert own friend_requests" on public.friend_requests;
create policy "insert own friend_requests" on public.friend_requests
  for insert with check (sender_id = auth.uid() and sender_id <> receiver_id);

-- Receiver can update to accept/decline their incoming request
drop policy if exists "receiver manages incoming" on public.friend_requests;
create policy "receiver manages incoming" on public.friend_requests
  for update using (receiver_id = auth.uid())
  with check (receiver_id = auth.uid());

-- Sender can cancel while pending
drop policy if exists "sender cancels" on public.friend_requests;
create policy "sender cancels" on public.friend_requests
  for update using (sender_id = auth.uid() and status = 'pending')
  with check (sender_id = auth.uid());

create index if not exists idx_friend_requests_receiver on public.friend_requests(receiver_id, status);
create index if not exists idx_friend_requests_sender on public.friend_requests(sender_id, status);

-- ================================
-- User locations for proximity matching
-- ================================

create table if not exists public.user_locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  latitude double precision,
  longitude double precision,
  geohash text,
  precision smallint not null default 5 check (precision between 3 and 8),
  updated_at timestamptz not null default now()
);

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

create index if not exists idx_user_locations_geohash on public.user_locations(geohash);
