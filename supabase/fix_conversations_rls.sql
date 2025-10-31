-- Fix RLS policies to allow creating conversations with friends
-- Run this in your Supabase SQL Editor

-- First, verify RLS is enabled (should already be enabled, but just in case)
alter table public.conversations enable row level security;

-- Allow users to create conversations (they'll add participants immediately after)
-- Drop any existing policies first
drop policy if exists "create conversations" on public.conversations;
drop policy if exists "insert conversations" on public.conversations;
drop policy if exists "users can create conversations" on public.conversations;

-- Create a policy that allows authenticated users to insert conversations
-- Using 'with check (true)' allows any authenticated user to insert
-- This matches PostgreSQL RLS best practices for permissive INSERT policies
create policy "create conversations" on public.conversations
  for insert 
  with check (true);

-- First, drop ALL existing policies on conversation_participants to rebuild them
drop policy if exists "manage participation self" on public.conversation_participants;
drop policy if exists "update participation self" on public.conversation_participants;
drop policy if exists "delete participation self" on public.conversation_participants;
drop policy if exists "insert participation self" on public.conversation_participants;
drop policy if exists "add friend as participant" on public.conversation_participants;

-- Recreate "manage participation self" but only for SELECT, UPDATE, DELETE (not INSERT)
-- We'll handle INSERT separately
create policy "manage participation self" on public.conversation_participants
  for select using (user_id = auth.uid());

create policy "update participation self" on public.conversation_participants
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "delete participation self" on public.conversation_participants
  for delete using (user_id = auth.uid());

-- Allow inserting yourself as a participant
create policy "insert participation self" on public.conversation_participants
  for insert with check (user_id = auth.uid());

-- Allow users to add friends as participants when creating conversations
-- This allows inserting the other user as a participant if they're friends
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

-- Verification: Check if policies were created correctly
-- Run this query to verify the policy exists:
SELECT tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'conversations'
  AND cmd = 'INSERT';
  
-- If the above query returns no rows, the policy wasn't created. 
-- Try this simpler version as an alternative:
-- drop policy if exists "create conversations" on public.conversations;
-- create policy "create conversations" on public.conversations
--   for insert with check (true);

