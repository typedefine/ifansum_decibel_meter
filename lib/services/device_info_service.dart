import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceString() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return '${info.utsname.machine} \u00b7 iOS ${info.systemVersion}';
      } else if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.model} \u00b7 Android ${info.version.release}';
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
