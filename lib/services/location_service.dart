import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Provides location string and simple provider selection
/// (Gaode inside China, Google outside).
class LocationService {
  // Optional: set these keys if you want to use provider web APIs.
  // If empty, the service falls back to the device geocoder.
  static const String gaodeApiKey = '';
  static const String googleApiKey = '';

  String _currentLocation = '';
  String get currentLocation => _currentLocation;
  String _cityArea = '';
  String get cityArea => _cityArea;

  /// Last provider used: 'gaode' or 'google'.
  String _provider = 'google';
  String get provider => _provider;

  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current location string.
  ///
  /// If location permission is granted, uses GPS + reverse geocoding.
  /// If permission is not granted, falls back to IP-based country check
  /// and sets provider to Gaode for China, Google otherwise.
  Future<String> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        final isChina = await _isInChinaByIp();
        _provider = isChina ? 'gaode' : 'google';
        _cityArea = isChina ? '中国' : 'Location unavailable';
        _currentLocation = _cityArea;
        return _currentLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Very rough provider selection: assume China if countryCode == CN.
      if (placemarks.isNotEmpty &&
          (placemarks.first.isoCountryCode?.toUpperCase() == 'CN')) {
        _provider = 'gaode';
      } else {
        _provider = 'google';
      }

      // Prefer provider reverse geocoding if API keys are configured.
      if (_provider == 'gaode' && gaodeApiKey.isNotEmpty) {
        final city = await _reverseGeocodeGaode(
          position.latitude,
          position.longitude,
        );
        if (city != null && city.isNotEmpty) {
          _cityArea = city;
          _currentLocation = _cityArea;
          return _currentLocation;
        }
      }
      if (_provider == 'google' && googleApiKey.isNotEmpty) {
        final city = await _reverseGeocodeGoogle(
          position.latitude,
          position.longitude,
        );
        if (city != null && city.isNotEmpty) {
          _cityArea = city;
          _currentLocation = _cityArea;
          return _currentLocation;
        }
      }

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? '';
        final subLocality = place.subLocality ?? '';
        final admin = place.administrativeArea ?? '';
        _cityArea = (locality + subLocality).trim();
        if (_cityArea.isEmpty) {
          _cityArea = (admin + locality).trim();
        }
        _currentLocation = _cityArea;
      } else {
        _currentLocation =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _cityArea = _currentLocation;
      }
    } catch (_) {
      _currentLocation = 'Location unavailable';
      _cityArea = _currentLocation;
    }

    return _currentLocation;
  }

  Future<bool> _isInChinaByIp() async {
    try {
      final resp =
          await http.get(Uri.parse('https://ipapi.co/json/')).timeout(
        const Duration(seconds: 5),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final code = (data['country_code'] as String?)?.toUpperCase();
        return code == 'CN';
      }
    } catch (_) {}
    return false;
  }

  Future<String?> _reverseGeocodeGaode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo'
        '?location=$lon,$lat&key=$gaodeApiKey&radius=1000&extensions=base',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final regeocode = data['regeocode'] as Map<String, dynamic>?;
      final addressComponent =
          regeocode?['addressComponent'] as Map<String, dynamic>?;
      final city = addressComponent?['city'];
      final district = addressComponent?['district'];
      final cityStr = city is String ? city : '';
      final districtStr = district is String ? district : '';
      final out = (cityStr + districtStr).trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseGeocodeGoogle(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lon&key=$googleApiKey&language=en',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'];
      if (results is List && results.isNotEmpty) {
        final comp = (results.first as Map<String, dynamic>)['address_components'];
        if (comp is List) {
          String? locality;
          String? sublocality;
          for (final c in comp) {
            final m = c as Map<String, dynamic>;
            final types = m['types'];
            if (types is List) {
              if (types.contains('locality')) {
                locality = m['long_name'] as String?;
              }
              if (types.contains('sublocality') ||
                  types.contains('sublocality_level_1')) {
                sublocality = m['long_name'] as String?;
              }
            }
          }
          final out = ((locality ?? '') + (sublocality ?? '')).trim();
          return out.isEmpty ? null : out;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

