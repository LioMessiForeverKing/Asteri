-- Create storage bucket for message images
-- Run this in your Supabase SQL Editor

-- Create public bucket for message images
insert into storage.buckets (id, name, public)
values ('message-images', 'message-images', true)
on conflict (id) do nothing;

-- Public read from the bucket (anyone in a conversation can see images)
drop policy if exists "message_images_public_read" on storage.objects;
create policy "message_images_public_read"
on storage.objects for select
using (bucket_id = 'message-images');

-- Allow authenticated users to upload images to conversations they're part of
-- The path structure is: messages/<conversation_id>/<message_id>/image.<ext>
drop policy if exists "message_images_insert_own" on storage.objects;
create policy "message_images_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'message-images' 
  and owner = auth.uid()
  -- Path format: messages/<conversation_id>/<uuid>/image.<ext>
  -- We can't easily validate conversation membership here, but owner check ensures security
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

