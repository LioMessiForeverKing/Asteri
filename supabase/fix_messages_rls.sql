-- Fix RLS policies for messages table to ensure users can read their messages
-- Run this in your Supabase SQL Editor

-- Verify RLS is enabled
alter table public.messages enable row level security;

-- Drop existing policies
drop policy if exists "read own messages" on public.messages;
drop policy if exists "insert own messages" on public.messages;

-- Create SELECT policy - users can read messages from conversations they're part of
create policy "read own messages" on public.messages
  for select 
  using (
    exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = messages.conversation_id 
        and p.user_id = auth.uid()
    )
  );

-- Create INSERT policy - users can insert messages to conversations they're part of
create policy "insert own messages" on public.messages
  for insert 
  with check (
    sender_id = auth.uid() 
    and exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = messages.conversation_id 
        and p.user_id = auth.uid()
    )
  );

-- Verification query - run this to check if you can see messages:
-- SELECT m.*, cp.user_id as participant_user_id 
-- FROM public.messages m
-- JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
-- WHERE cp.user_id = auth.uid()
-- LIMIT 10;

