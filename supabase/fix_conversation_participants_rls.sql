-- Fix RLS policies for conversation_participants to allow seeing all participants in your conversations
-- Run this in your Supabase SQL Editor

-- The current "manage participation self" policy only allows seeing YOUR OWN participation
-- We need to also allow seeing OTHER participants in conversations you're part of

-- Drop existing SELECT policy
drop policy if exists "manage participation self" on public.conversation_participants;
drop policy if exists "read participants in own conversations" on public.conversation_participants;

-- Create new SELECT policy using a security definer function to avoid recursion
-- First create a helper function
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

-- Now create the policy using the function
create policy "read participants in own conversations" on public.conversation_participants
  for select 
  using (
    -- Allow if it's your own participation record
    user_id = auth.uid()
    or
    -- OR allow if you're a participant in this conversation (using security definer function to avoid recursion)
    public.user_is_participant_in_conversation(conversation_id)
  );

-- Grant execute on the function
grant execute on function public.user_is_participant_in_conversation(uuid) to authenticated;

-- Keep the other policies as-is
-- UPDATE, DELETE, INSERT policies remain the same

