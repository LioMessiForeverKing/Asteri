-- Fix RLS policies for user_push_tokens to support upsert (INSERT + UPDATE)
-- Run this in your Supabase SQL Editor

-- Enable RLS (should already be enabled)
alter table public.user_push_tokens enable row level security;

-- Drop existing policies
drop policy if exists "upsert own token" on public.user_push_tokens;
drop policy if exists "read own tokens" on public.user_push_tokens;
drop policy if exists "delete own token" on public.user_push_tokens;

-- Create INSERT policy
create policy "insert own token" on public.user_push_tokens
  for insert 
  with check (auth.uid() = user_id);

-- Create UPDATE policy (needed for upsert)
create policy "update own token" on public.user_push_tokens
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Create SELECT policy
create policy "read own tokens" on public.user_push_tokens
  for select 
  using (auth.uid() = user_id);

-- Create DELETE policy
create policy "delete own token" on public.user_push_tokens
  for delete 
  using (auth.uid() = user_id);

