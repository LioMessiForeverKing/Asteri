-- Comprehensive fix for conversations RLS issue
-- Run this entire script in your Supabase SQL Editor

-- Step 1: Verify RLS is enabled
alter table public.conversations enable row level security;

-- Step 2: Drop INSERT policies (keep SELECT policy for now)
drop policy if exists "create conversations" on public.conversations;
drop policy if exists "insert conversations" on public.conversations;
drop policy if exists "users can create conversations" on public.conversations;

-- Step 3: Create a security definer function to create conversations
-- This bypasses RLS and ensures authenticated users can create conversations
create or replace function public.create_conversation()
returns uuid
language plpgsql
security definer
as $$
declare
  new_id uuid;
begin
  -- Ensure user is authenticated
  if auth.uid() is null then
    raise exception 'User must be authenticated';
  end if;
  
  -- Insert the conversation
  insert into public.conversations (created_at)
  values (now())
  returning id into new_id;
  
  return new_id;
end;
$$;

-- Step 4: Grant execute permission to authenticated users
grant execute on function public.create_conversation() to authenticated;

-- Step 5: Recreate the SELECT policy (for reading conversations)
drop policy if exists "read own conversations" on public.conversations;
create policy "read own conversations" on public.conversations
  for select using (
    exists (
      select 1 from public.conversation_participants p
      where p.conversation_id = id and p.user_id = auth.uid()
    )
  );

-- Step 6: Also create a direct INSERT policy (as backup)
-- Try both approaches - function should work, but this is a fallback
create policy "create conversations" on public.conversations
  for insert 
  to authenticated
  with check (true);

-- Step 7: Verify the function and policy were created
-- Run these queries after executing the above:

-- Check if function exists:
-- SELECT routine_name, routine_type 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
--   AND routine_name = 'create_conversation';

-- Check if policy exists:
-- SELECT tablename, policyname, cmd, roles 
-- FROM pg_policies 
-- WHERE schemaname = 'public' 
--   AND tablename = 'conversations';

