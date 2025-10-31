import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import '../models/profile.dart';

class ProfileService {
  static const String _kNameKey = 'profile_name';
  static const String _kEmailKey = 'profile_email';
  static const String _kPhotoKey = 'profile_photo';
  static const String _bucket = 'profile-images';

  /// Load cached profile from local storage. Returns null if missing.
  static Future<Map<String, String>?> loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kNameKey);
    final email = prefs.getString(_kEmailKey);
    final photo = prefs.getString(_kPhotoKey);
    if (name == null || email == null) return null;
    return {'name': name, 'email': email, 'photo': photo ?? ''};
  }

  /// Fetch profile details from the current Supabase user metadata (populated by Google OAuth)
  /// and persist locally. Returns null if user not available.
  static Future<Map<String, String>?> fetchFromSupabaseAndCache() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final meta = user.userMetadata ?? <String, dynamic>{};
    final name =
        (meta['name'] ??
                meta['full_name'] ??
                user.email?.split('@').first ??
                '')
            .toString();
    final email = user.email ?? '';
    final photo = (meta['picture'] ?? meta['avatar_url'] ?? '').toString();

    final profile = {'name': name, 'email': email, 'photo': photo};
    await saveLocalProfile(profile);
    return profile;
  }

  /// Save profile to local storage
  static Future<void> saveLocalProfile(Map<String, String> profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile['name'] != null) {
      await prefs.setString(_kNameKey, profile['name']!);
    }
    if (profile['email'] != null) {
      await prefs.setString(_kEmailKey, profile['email']!);
    }
    if (profile['photo'] != null) {
      await prefs.setString(_kPhotoKey, profile['photo']!);
    }
  }

  // ==============================
  // Supabase-backed profile methods
  // ==============================

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) {
        // debugPrint('ProfileService: No profile found for user $userId');
        return null;
      }
      final profile = Profile.fromMap(Map<String, dynamic>.from(data));
      // debugPrint('ProfileService: Successfully loaded profile for $userId: ${profile.fullName}');
      return profile;
    } catch (e) {
      // debugPrint('ProfileService: Error fetching profile for $userId: $e');
      return null;
    }
  }

  static Future<bool> isProfileComplete(String userId) async {
    final profile = await getProfile(userId);
    return profile?.isComplete == true;
  }

  static Future<Profile> upsertProfile({
    required String userId,
    required String fullName,
    required String starColor,
    String? avatarPath,
    List<String>? interests,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'full_name': fullName,
      'star_color': starColor,
      if (avatarPath != null) 'avatar_url': avatarPath,
      if (interests != null) 'interests': interests,
    };

    final data = await _client
        .from('profiles')
        .upsert(payload, onConflict: 'id')
        .select()
        .single();

    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  static Future<String> uploadAvatarFromBytes({
    required String userId,
    required Uint8List bytes,
    String? fileName,
    String? contentType,
  }) async {
    final detectedType =
        contentType ?? lookupMimeType(fileName ?? '', headerBytes: bytes);
    final ext = _fileExtensionForMime(detectedType);
    final objectPath = 'profiles/$userId/avatar$ext';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return objectPath;
  }

  static String getPublicAvatarUrl(String objectPath) {
    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }

  static String _fileExtensionForMime(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/jpeg':
      default:
        return '.jpg';
    }
  }
}
