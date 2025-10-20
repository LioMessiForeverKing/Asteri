import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static const String _kNameKey = 'profile_name';
  static const String _kEmailKey = 'profile_email';
  static const String _kPhotoKey = 'profile_photo';

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
}
