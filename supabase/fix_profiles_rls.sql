-- Fix RLS policies to allow reading friends' profiles
-- Run this in your Supabase SQL Editor

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

