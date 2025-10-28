## Profile Backend Integration Plan

This plan sets up the backend and flow to require each user to complete their profile (real profile picture, real display name, and a preferred star color) before continuing past the profile screen. It includes database schema, RLS policies, storage bucket creation, and the frontend workflow checklist.

### Goals
- **Require completion**: User must provide a profile picture, name, and star color before tapping Continue.
- **Persist profile**: Store profile in `public.profiles` keyed to `auth.users.id`.
- **Store images**: Upload profile avatars to a dedicated Storage bucket with appropriate RLS.

---

## 1) Supabase SQL — Profiles table + RLS

Paste the following in Supabase SQL Editor and run it.

```sql
-- 1. Table
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 100),
  avatar_url text, -- store a Storage path like: profiles/<user_id>/avatar.<ext>
  star_color text not null check (star_color ~ '^#(?:[0-9a-fA-F]{3}){1,2}$'), -- HEX #RGB or #RRGGBB
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Updated-at trigger
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

-- 3. RLS
alter table public.profiles enable row level security;

-- Allow each user to read their own profile
drop policy if exists "select_own_profile" on public.profiles;
create policy "select_own_profile"
on public.profiles for select
using (auth.uid() = id);

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
```

Notes:
- `avatar_url` should store the Storage path (recommended), not a public URL. This lets you switch between public/signed URLs later.
- If you want all users to be able to view each other’s profiles, add a broader SELECT policy. The above is “own-only” by default.

---

## 2) Supabase SQL — Storage bucket + RLS

Create a public bucket for profile images and add RLS to allow public reads and user-only writes.

```sql
-- 1. Bucket
select storage.create_bucket('profile-images', public => true);

-- 2. Policies on storage.objects
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
```

Recommended object key for the avatar:
- `profiles/<user_id>/avatar.<ext>` (e.g., `profiles/5d3f.../avatar.jpg`)

If you prefer private images, set `public => false` and omit the public read policy; serve avatars with signed URLs instead.

---

## 3) Frontend flow checklist (Profile screen)

- **Block Continue until valid**:
  - Name present and 1–100 chars.
  - Star color is a valid HEX string `#RGB` or `#RRGGBB`.
  - A profile image file selected and upload completed.

- **On screen open (authenticated)**:
  - Try to fetch `public.profiles` by `auth.uid()`.
  - If exists, prefill fields (name, star color, load avatar image by building a public URL or fetching signed URL from `avatar_url` path).

- **On image selection**:
  - Generate a deterministic key: `profiles/<user_id>/avatar.<ext>`.
  - Upload to `profile-images` bucket with `upsert = true`.
  - Store the object path (not the URL) locally for the pending profile save.

- **On Save/Continue**:
  - Validate inputs.
  - If `profiles` row doesn’t exist: `insert` with `{ id: auth.uid(), full_name, star_color, avatar_url: '<object-path>' }`.
  - Else: `update` the same fields.
  - Navigate forward only after a successful save.

- **On subsequent app opens**:
  - Fetch profile; if incomplete (any required field missing), force user back to the profile screen.

---

## 4) Rollout steps

1. Run the SQL in sections (1) and (2) in the Supabase SQL Editor.
2. Verify the `profile-images` bucket exists and policies are active.
3. In local/dev app, sign in and test the flow end-to-end:
   - Upload image → verify object path in bucket.
   - Save profile → verify row in `public.profiles`.
   - Refresh app → profile loads and Continue remains enabled.
4. Optionally backfill existing users:
   - Insert rows for existing `auth.users` where missing, then prompt users to complete missing fields upon next sign-in.

---

## 5) Implementation notes

- Prefer storing the object path (e.g., `profiles/<uid>/avatar.jpg`) in `avatar_url`.
- For public buckets, the public URL format is: `https://<project-ref>.supabase.co/storage/v1/object/public/profile-images/<object-path>`.
- For private buckets, request signed URLs at runtime when needed.
- Keep name and color updates idempotent; re-uploads should overwrite existing avatar.

---

## 6) Comprehensive Step-by-Step Implementation Plan

### Phase 1: Backend Setup (Supabase)

#### Step 1.1: Create Database Schema
1. **Open Supabase Dashboard** → Go to your project
2. **Navigate to SQL Editor** (left sidebar)
3. **Paste and execute the profiles table SQL** (from section 1 above)
4. **Verify table creation**:
   - Go to Table Editor → `public.profiles`
   - Confirm columns: `id`, `full_name`, `avatar_url`, `star_color`, `created_at`, `updated_at`
   - Verify foreign key constraint to `auth.users(id)`

#### Step 1.2: Create Storage Bucket
1. **In Supabase Dashboard** → Go to Storage (left sidebar)
2. **Create new bucket**:
   - Name: `profile-images`
   - Public: ✅ (checked)
   - File size limit: 5MB (recommended)
   - Allowed MIME types: `image/jpeg,image/png,image/webp,image/gif`
3. **Execute storage policies SQL** (from section 2 above)
4. **Verify bucket creation**:
   - Check Storage → `profile-images` bucket exists
   - Test upload a dummy image to verify permissions

#### Step 1.3: Test Database Permissions
1. **Create test profile** (in SQL Editor):
   ```sql
   -- Replace with actual user ID from auth.users
   INSERT INTO public.profiles (id, full_name, star_color) 
   VALUES ('your-user-id-here', 'Test User', '#FF5733');
   ```
2. **Verify RLS policies work**:
   - Try to insert with different user ID (should fail)
   - Try to select other users' profiles (should fail for non-owners)

### Phase 2: Flutter Dependencies & Configuration

#### Step 2.1: Add Required Dependencies
1. **Open `pubspec.yaml`**
2. **Add/verify these dependencies**:
   ```yaml
   dependencies:
     supabase_flutter: ^2.0.0
     image_picker: ^1.0.4
     path_provider: ^2.1.1
     mime: ^1.0.4
   ```
3. **Run `flutter pub get`**

#### Step 2.2: Configure Supabase Client
1. **Check `lib/main.dart`** - ensure Supabase is initialized
2. **Verify environment variables** are set:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. **Test connection** with a simple query in debug console

### Phase 3: Create Profile Service

#### Step 3.1: Create Profile Model
1. **Create `lib/models/profile.dart`**:
   ```dart
   class Profile {
     final String id;
     final String fullName;
     final String? avatarUrl;
     final String starColor;
     final DateTime createdAt;
     final DateTime updatedAt;
     
     // Constructor, fromJson, toJson methods
   }
   ```

#### Step 3.2: Create Profile Service
1. **Create `lib/services/profile_service.dart`**:
   - `getProfile()` - fetch user's profile
   - `createProfile()` - insert new profile
   - `updateProfile()` - update existing profile
   - `uploadAvatar()` - upload image to storage
   - `getAvatarUrl()` - get public/signed URL for avatar

#### Step 3.3: Create Image Upload Service
1. **Create `lib/services/image_upload_service.dart`**:
   - `pickImage()` - image picker functionality
   - `uploadToStorage()` - upload to Supabase storage
   - `validateImage()` - check file size, type, etc.

### Phase 4: Update Profile Page UI

#### Step 4.1: Add Form Validation
1. **Create validation functions**:
   - `validateName()` - 1-100 characters
   - `validateStarColor()` - valid HEX format
   - `validateImage()` - file selected and uploaded

#### Step 4.2: Add Image Picker UI
1. **Add image picker button** to profile page
2. **Add image preview** widget
3. **Add loading states** for upload process
4. **Add error handling** for failed uploads

#### Step 4.3: Add Color Picker
1. **Add color picker widget** for star color selection
2. **Predefined color options** or custom color picker
3. **Visual preview** of selected color

#### Step 4.4: Update Continue Button Logic
1. **Disable Continue button** until all fields valid
2. **Add loading state** during save
3. **Add success/error feedback**
4. **Navigate to next screen** only after successful save

### Phase 5: Update App Flow

#### Step 5.1: Modify Auth Gate
1. **Update `lib/pages/auth_gate.dart`**:
   - After successful authentication, check if profile is complete
   - Redirect to profile page if incomplete
   - Redirect to home page if complete

#### Step 5.2: Add Profile Completion Check
1. **Create profile completion validator**:
   - Check if all required fields are present
   - Check if avatar is uploaded successfully
2. **Add to app startup flow**

#### Step 5.3: Update Navigation Logic
1. **Modify navigation** to respect profile completion
2. **Add profile completion check** before accessing main app features
3. **Add "Complete Profile" prompt** if user tries to skip

### Phase 6: Testing & Validation

#### Step 6.1: Unit Tests
1. **Test profile service methods**:
   - `getProfile()`, `createProfile()`, `updateProfile()`
   - `uploadAvatar()`, `getAvatarUrl()`
2. **Test validation functions**:
   - Name validation, color validation, image validation

#### Step 6.2: Integration Tests
1. **Test complete flow**:
   - Sign in → Profile page → Fill form → Upload image → Save → Continue
2. **Test edge cases**:
   - Network failures, invalid inputs, storage errors
3. **Test profile loading**:
   - App restart → Profile loads correctly

#### Step 6.3: User Acceptance Testing
1. **Test on different devices** (iOS, Android)
2. **Test with different image sizes/types**
3. **Test network conditions** (slow, offline, etc.)
4. **Test user experience** flow

### Phase 7: Error Handling & Edge Cases

#### Step 7.1: Network Error Handling
1. **Add retry logic** for failed uploads
2. **Add offline support** (queue uploads)
3. **Add user-friendly error messages**

#### Step 7.2: Data Validation
1. **Client-side validation** before API calls
2. **Server-side validation** (already in SQL constraints)
3. **Graceful handling** of validation errors

#### Step 7.3: Image Handling
1. **Image compression** for large files
2. **Image resizing** to standard dimensions
3. **Format conversion** if needed
4. **Cleanup** of old images when updating

### Phase 8: Performance Optimization

#### Step 8.1: Image Optimization
1. **Lazy loading** of profile images
2. **Caching** of uploaded images
3. **Progressive loading** for large images

#### Step 8.2: Database Optimization
1. **Add indexes** if needed for queries
2. **Optimize RLS policies** for performance
3. **Monitor query performance**

### Phase 9: Deployment & Monitoring

#### Step 9.1: Production Deployment
1. **Deploy to production** Supabase project
2. **Update environment variables** for production
3. **Test production flow** end-to-end

#### Step 9.2: Monitoring & Analytics
1. **Add error tracking** (Sentry, Crashlytics)
2. **Add analytics** for profile completion rates
3. **Monitor storage usage** and costs

#### Step 9.3: User Migration
1. **Create migration script** for existing users
2. **Add onboarding flow** for profile completion
3. **Send notifications** to complete profiles

### Phase 10: Documentation & Maintenance

#### Step 10.1: Code Documentation
1. **Add inline comments** to complex functions
2. **Create API documentation** for profile service
3. **Update README** with setup instructions

#### Step 10.2: User Documentation
1. **Create user guide** for profile setup
2. **Add help text** in the app
3. **Create FAQ** for common issues

---

## 7) Implementation Checklist

### Backend Setup
- [ ] Create `profiles` table with RLS policies
- [ ] Create `profile-images` storage bucket
- [ ] Test database permissions
- [ ] Verify storage bucket access

### Flutter Setup
- [ ] Add required dependencies
- [ ] Configure Supabase client
- [ ] Create profile model
- [ ] Create profile service
- [ ] Create image upload service

### UI Implementation
- [ ] Add form validation
- [ ] Add image picker UI
- [ ] Add color picker
- [ ] Update Continue button logic
- [ ] Add loading states and error handling

### App Flow
- [ ] Update auth gate
- [ ] Add profile completion check
- [ ] Update navigation logic
- [ ] Test complete user flow

### Testing
- [ ] Unit tests for services
- [ ] Integration tests for flow
- [ ] User acceptance testing
- [ ] Performance testing

### Deployment
- [ ] Deploy to production
- [ ] Monitor performance
- [ ] Handle user migration
- [ ] Create documentation

---

## 8) Common Issues & Solutions

### Issue: Image Upload Fails
**Solution**: Check storage bucket permissions, file size limits, and MIME type restrictions

### Issue: Profile Not Saving
**Solution**: Verify RLS policies, check user authentication, validate input data

### Issue: Profile Not Loading
**Solution**: Check database connection, verify user ID, handle null cases

### Issue: Continue Button Not Enabling
**Solution**: Verify validation logic, check all required fields are filled

### Issue: App Crashes on Profile Page
**Solution**: Add null safety checks, handle missing profile data gracefully

---

## 9) Success Metrics

- **Profile Completion Rate**: >90% of users complete profile
- **Upload Success Rate**: >95% of image uploads succeed
- **App Performance**: Profile page loads in <2 seconds
- **User Experience**: <3 taps to complete profile setup
- **Error Rate**: <1% of profile operations fail

