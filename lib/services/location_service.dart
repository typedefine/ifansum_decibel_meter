import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_amap/fl_amap.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
/// Provides location string and simple provider selection
/// (Gaode inside China, Google outside).
class LocationService{


  // Optional: set these keys if you want to use provider web APIs.
  // If empty, the service falls back to the device geocoder.
  static const String gaodeApiKeyIOS = '6c25a6db38dbd9862d1e89e1ededc39c';
  static const String gaodeApiKeyAndroid = '0c4797b3334be3c1d48832329e6bea5e';
  static const String googleApiKeyIOS = 'AIzaSyB6WK9JB_zjDTc-XytwS30pURX5Nkbyd2Q';
  static const String googleApiKeyAndroid = 'AIzaSyArPwNM1vWGBSTFlHCh1mk4gCZy0Q0OhS8';

  static LocationService? _instance;

  LocationService._internal(){
    init();
  }

  factory LocationService(){
    _instance ??= LocationService._internal();
    return _instance!;
  }

  Future<void> initAMap() async{
    final bool r = await FlAMap().setAMapKey(
        iosKey: gaodeApiKeyIOS,
        androidKey: gaodeApiKeyAndroid);
    if (r) print('高德地图ApiKey设置成功');

    /// 初始化AMap
    final bool data = await FlAMapLocation().initialize();
    if (data) {
      print('初始化成功');
    }
  }

  LocationService init(){
     // AMapFlutterLocation.setApiKey(gaodeApiKeyAndroid, gaodeApiKeyIOS);
     initAMap();
    if(Platform.isIOS){
      _gaodeApiKey = gaodeApiKeyIOS;
      _googleApiKey = googleApiKeyIOS;
    }else if(Platform.isAndroid){
      _gaodeApiKey =  gaodeApiKeyAndroid;
      _googleApiKey = googleApiKeyAndroid;
    }else{

    }
    _locale = ui.PlatformDispatcher.instance.locale;
    // _isInChinaMainland = _locale.countryCode == 'CN';
     _initRegionCode();
    return this;
  }

  int _time = 0;
  Locale _locale = Locale('en', 'US');
  Future<void> setLocale(Locale locale) async {
    if(locale.languageCode == _locale.languageCode
        && locale.countryCode == _locale.countryCode) {
      return;
    }
    // _isInChinaMainland = locale.countryCode != 'TW' && locale.languageCode == 'zh';
    _locale = locale;
    if(_latitude != 0 && _longitude != 0){
      _reverseGeocodeGaode(_latitude, _longitude);
    }
  }

  /// 高德纬度
  double _latitude = 0.0;
  /// 高德经度
  double _longitude =0.0;

  bool _isInChinaMainland = true;
  bool get isInChina => _isInChinaMainland;
  String _gaodeApiKey = '';
  String get gaodeApiKey => _gaodeApiKey;
  String _googleApiKey = '';
  String get googleApiKey => _googleApiKey;
  String _currentLocation = '';
  String get currentLocation => _currentLocation;
  String _cityArea = '';
  String get cityArea => _cityArea;

  /// Last provider used: 'gaode' or 'google'.
  String _provider = 'google';
  String get provider => _provider;

/*
  Future<String> getLocationFromAMap() async {

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      _isInChina = await _isInChinaByIp();
      _provider = _isInChina ? 'gaode' : 'google';
      _cityArea = _isInChina ? '中国' : 'Location unavailable';
      _currentLocation = _cityArea;
      return _currentLocation;
    }

    // 1. 创建定位对象
    AMapFlutterLocation location = AMapFlutterLocation();

    // 2. 设置定位参数（可选）
    location.setLocationOption(AMapLocationOption(
      onceLocation: true,        // 单次定位，适合你的场景
      needAddress: true,         // 是否需要地址信息（如果不需要可以关掉）
      locationMode: AMapLocationMode.Hight_Accuracy, // 高精度模式
    ));

    // 3. 监听定位结果（单次定位只需要监听一次）
    Completer<Map<String, Object>> completer = Completer();
    StreamSubscription<Map<String, Object>>? subscription;

    subscription = location.onLocationChanged().listen((Map<String, Object> result) {
      // 定位成功后，用 Completer 返回结果
      if (!completer.isCompleted) {
        completer.complete(result);
        subscription?.cancel();
      }
    });

    // 4. 启动定位
    location.startLocation();

    // 5. 设置超时（例如10秒）
    Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('定位超时'));
        subscription?.cancel();
      }
    });

    try {
      final result = await completer.future;
      return result.toString();
    } catch (e) {
      print('定位失败: $e');
      _currentLocation = 'Location unavailable';
      _cityArea = _currentLocation;
      return _currentLocation;
    } finally {
      // 停止定位
      location.stopLocation();
    }
  }
 */

  Future<bool> requestLocationPermission() async {
    try {
      // 检查权限状态
      PermissionStatus status = await Permission.location.status;
      print('当前定位权限状态: $status');

      if (status.isGranted) {
        print('✅ 定位权限已授予');
        return true;
      }

      if (status.isDenied) {
        print('📝 请求定位权限...');
        PermissionStatus result = await Permission.location.request();
        print('权限请求结果: $result');
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        print('❌ 定位权限被永久拒绝');
        // 引导用户去设置页面
        bool opened = await openAppSettings();
        print('设置页面打开结果: $opened');
        return false;
      }

      if (status.isRestricted) {
        print('❌ 定位权限受限制');
        return false;
      }

      return false;
    } catch (e) {
      print('权限请求异常: $e');
      return false;
    }
  }

  Future<String> getLocationFromAMap() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      // _isInChinaMainland = await _isInChinaByIp();
      _initRegionCode();
      _provider = _isInChinaMainland ? 'gaode' : 'google';
      _cityArea = _isInChinaMainland ? '中国' : 'Location unavailable';
      _currentLocation = _cityArea;
      return _currentLocation;
    }
    try {
      return await startLocation();
    } catch (e) {
      print('定位失败: $e');
      _currentLocation = 'Location unavailable';
      _cityArea = _currentLocation;
      return _currentLocation;
    } finally {
      FlAMapLocation().stopLocation();
    }
  }


  Future<String> startLocation() async {
    try {
      bool isStarted = await FlAMapLocation().startLocation();
      if (isStarted) {
        // 获取一次定位
        return await getOnceLocation();
      } else {
        Future.delayed(Duration(seconds: 3), () async {
          return await startLocation();
        });
      }
    } catch(e){
      print('定位异常: $e');
    }
    return await startLocation();
  }


  // 获取单次定位
  Future<String> getOnceLocation() async {
    try {
      if(_time > 8){
        return '';
      }
      _time++;
      AMapLocation? location = await FlAMapLocation().getLocation();
      if (location != null) {
        _latitude = location.latitude!;
        _longitude = location.longitude!;
        _time = 0;
        String mark = '中国';
        if(_locale.languageCode == 'zh'){
          if(_locale.countryCode == 'CN'||(_locale.countryCode != 'HK' && _locale.countryCode != 'TW')){
            mark = '中国';
          }
          // else if(_locale.countryCode == 'HK'){
          //   mark = '香港';
          // }else if(_locale.countryCode == 'TW'){
          //   mark = '台湾';
          // }
        }
        _isInChinaMainland = location.country == mark;
        _currentLocation = (location.city! + location.district!);
        _cityArea = _currentLocation;
        if(location.country == '中国'&& _locale.languageCode == 'zh' && _locale.countryCode == 'CN'){
          // 停止定位
          // FlAMapLocation().stopLocation();
          return _currentLocation;
        }else{
          return await _reverseGeocodeGaode(_latitude, _longitude);
        }

      } else {
        Future.delayed(Duration(seconds: 2), () {
          return getOnceLocation();
        });
      }
    } catch (e) {
      print('获取定位异常: $e');
      _currentLocation = 'Location unavailable';
      _cityArea = _currentLocation;
    }
    return _currentLocation;
  }


  Future<String> getCurrentLocation() async {
    if(_isInChinaMainland){
      return await getLocationFromAMap();
    }else{
      return await getCurrentLocationFromGoogle();
    }
  }

  Future<void> _initRegionCode() async{
    _isInChinaMainland = await _isInChinaByIp() || (_locale.languageCode == 'zh'
        || _locale.countryCode == 'CN') ;
  }


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
  Future<String> getCurrentLocationFromGoogle() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        // _isInChinaMainland = (_locale.languageCode == 'zh'
        //     || _locale.countryCode == 'CN') && await _isInChinaByIp();
        _initRegionCode();
        _provider = _isInChinaMainland ? 'gaode' : 'google';
        _cityArea = _isInChinaMainland ? '中国' : 'Location unavailable';
        _currentLocation = _cityArea;
        return _currentLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15)
        ),
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
    } catch (e) {
      print('定位失败: $e');
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
    } catch (_) {

    }
    return true;
  }

  String _getLanguageCode(){
    String languageCode = 'zh';
    if(_locale.languageCode == 'en'){
      languageCode = 'en';
    }else if(_locale.languageCode == 'zh'){
      if(_locale.languageCode == 'CN'){
        languageCode = 'zh';
      }else{
        languageCode = 'zh_TW';
      }
    }
    return languageCode;
  }

  Future<String> _reverseGeocodeGaode(double lat, double lon) async {
    _currentLocation = _currentLocation??'Location unavailable';
    try {
      String languageCode = _getLanguageCode();
      String webGaodeApikey= 'ad930ae448b4aa2f442d0121e1006a99';
      final uri = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo'
        '?location=$lon,$lat&key=$webGaodeApikey&radius=1000&extensions=base&language=$languageCode',
      );//gaodeApiKey
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return _currentLocation;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final regeocode = data['regeocode'] as Map<String, dynamic>?;
      final addressComponent =
          regeocode?['addressComponent'] as Map<String, dynamic>?;
      final city = addressComponent?['city'];
      final district = addressComponent?['district'];
      final cityStr = city is String ? city : '';
      final districtStr = district is String ? district : '';
      final out = (cityStr + districtStr).trim();
      _currentLocation = out.isEmpty ? _currentLocation : out;
      _cityArea = _currentLocation;
      return _currentLocation;
    } catch (_) {
      _cityArea = _currentLocation;
    }
    return _currentLocation;
  }

  Future<String?> _reverseGeocodeGoogle(double lat, double lon) async {
    _currentLocation = _currentLocation??'Location unavailable';
    try {
      String languageCode = _getLanguageCode();
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lon&key=$googleApiKey&language=$languageCode',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return _currentLocation;
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
          _currentLocation = out.isEmpty ? _currentLocation : out;
          _cityArea = _currentLocation;
          return _currentLocation;
        }
      }
    } catch (_) {
      _cityArea = _currentLocation;
    }
    return _currentLocation;
  }
}

