import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  LocationService._();

  static const String _kOptInKey = 'location_opt_in';
  static const String _kLastUpdateMsKey = 'location_last_update_ms';
  static const String _kLastGeohashKey = 'location_last_geohash';
  static const Duration _minInterval = Duration(minutes: 15);

  static Future<bool> get isOptedIn async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true unless user opts out explicitly (can change via settings later)
    return prefs.getBool(_kOptInKey) ?? true;
  }

  static Future<void> setOptIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOptInKey, value);
  }

  static Future<bool> _rateLimitAllows() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kLastUpdateMsKey);
    if (lastMs == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    return elapsed >= _minInterval.inMilliseconds;
  }

  static Future<void> _rememberUpdate(String geohash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastUpdateMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(_kLastGeohashKey, geohash);
  }

  static Future<LocationPermission> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  static Future<bool> maybeUpdateLocation({int geohashPrecision = 5}) async {
    try {
      if (Supabase.instance.client.auth.currentUser == null) return false;
      if (!await isOptedIn) return false;
      if (!await _rateLimitAllows()) return false;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final perm = await ensurePermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }

      // Try last known first (fast), else current with low accuracy
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );
      final gh = _encodeGeohash(pos.latitude, pos.longitude, geohashPrecision);
      await _upsertLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        geohash: gh,
        precision: geohashPrecision,
      );
      await _rememberUpdate(gh);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _upsertLocation({
    required double latitude,
    required double longitude,
    required String geohash,
    required int precision,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client.from('user_locations').upsert({
      'user_id': uid,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'precision': precision,
    });
  }

  // Simple geohash encoder (base32) for our needs
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static String _encodeGeohash(double lat, double lon, int precision) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    int bit = 0, ch = 0;
    bool isEven = true;
    StringBuffer geohash = StringBuffer();
    while (geohash.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (lon > mid) {
          ch |= 1 << (4 - bit);
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat > mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }
}
