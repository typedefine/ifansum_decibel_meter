import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  // Locale
  Locale _locale = const Locale('zh', 'CN');
  Locale get locale => _locale;

  // Pro status
  bool _isPro = false;
  bool get isPro => _isPro;

  int _curPageIndex = 0;
  int get curPageIndex => _curPageIndex;

  // How many times photos/videos have been saved for non-pro users.
  int _mediaSaveCount = 0;
  int get mediaSaveCount => _mediaSaveCount;

  // For non-pro users: allow 3 full saves when recording > 20s.
  int _longRecordingTrialUsed = 0;
  int get longRecordingTrialUsed => _longRecordingTrialUsed;

  // Response frequency in milliseconds
  int _responseFrequencyMs = 500;
  int get responseFrequencyMs => _responseFrequencyMs;

  // Auto record
  bool _autoRecord = true;
  bool get autoRecord => _autoRecord;

  // Frequency weighting
  String _frequencyWeighting = 'A';
  String get frequencyWeighting => _frequencyWeighting;

  // Calibration
  double _calibration = 0.0;
  double get calibration => _calibration;

  void _loadSettings() {
    final localeCode = _prefs.getString('locale') ?? 'zh_CN';
    switch (localeCode) {
      case 'en':
        _locale = const Locale('en');
        break;
      case 'zh_TW':
        _locale = const Locale('zh', 'TW');
        break;
      default:
        _locale = const Locale('zh', 'CN');
    }
    _isPro = _prefs.getBool('is_pro') ?? false;
    _mediaSaveCount = _prefs.getInt('media_save_count') ?? 0;
    _longRecordingTrialUsed = _prefs.getInt('long_recording_trial_used') ?? 0;
    _responseFrequencyMs = _prefs.getInt('response_frequency_ms') ?? 500;
    _autoRecord = _prefs.getBool('auto_record') ?? true;
    _frequencyWeighting = _prefs.getString('frequency_weighting') ?? 'A';
    _calibration = _prefs.getDouble('calibration') ?? 0.0;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    String code = 'zh_CN';
    if (locale.languageCode == 'en') {
      code = 'en';
    } else if (locale.countryCode == 'TW') {
      code = 'zh_TW';
    }
    await _prefs.setString('locale', code);
    notifyListeners();
  }

  Future<void> setIsPro(bool value) async {
    _isPro = value;
    await _prefs.setBool('is_pro', value);
    notifyListeners();
  }

  Future<void> setCurPageIndex(int index) async {
    _curPageIndex = index;
    notifyListeners();
  }

  Future<void> incrementMediaSaveCount() async {
    _mediaSaveCount += 1;
    await _prefs.setInt('media_save_count', _mediaSaveCount);
    notifyListeners();
  }

  int get longRecordingTrialRemaining {
    final remaining = 3 - _longRecordingTrialUsed;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> incrementLongRecordingTrialUsed() async {
    _longRecordingTrialUsed += 1;
    await _prefs.setInt('long_recording_trial_used', _longRecordingTrialUsed);
    notifyListeners();
  }

  Future<void> setResponseFrequencyMs(int value) async {
    _responseFrequencyMs = value;
    await _prefs.setInt('response_frequency_ms', value);
    notifyListeners();
  }

  Future<void> setAutoRecord(bool value) async {
    _autoRecord = value;
    await _prefs.setBool('auto_record', value);
    notifyListeners();
  }

  Future<void> setFrequencyWeighting(String value) async {
    _frequencyWeighting = value;
    await _prefs.setString('frequency_weighting', value);
    notifyListeners();
  }

  Future<void> setCalibration(double value) async {
    _calibration = value;
    await _prefs.setDouble('calibration', value);
    notifyListeners();
  }

  String get responseFrequencyLabel {
    if (_responseFrequencyMs <= 125) return 'Fast 125ms';
    return 'Slow ${_responseFrequencyMs}ms';
  }
}
