import 'dart:async';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  double _currentDecibel = 0.0;
  double _maxDecibel = 0.0;
  double _minDecibel = double.infinity;
  double _peakDecibel = 0.0;
  double _totalDecibel = 0.0;
  int _readingCount = 0;
  final List<double> _waveformData = [];

  double get currentDecibel => _currentDecibel;
  double get maxDecibel => _maxDecibel;
  double get minDecibel => _minDecibel == double.infinity ? 0.0 : _minDecibel;
  double get peakDecibel => _peakDecibel;
  double get avgDecibel =>
      _readingCount > 0 ? _totalDecibel / _readingCount : 0.0;
  List<double> get waveformData => List.unmodifiable(_waveformData);

  Function(double decibel)? onDecibelUpdate;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> start() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return false;

    _noiseMeter ??= NoiseMeter();
    _reset();

    _noiseSubscription = _noiseMeter!.noise.listen(
      (NoiseReading reading) {
        _currentDecibel = reading.meanDecibel.clamp(0.0, 120.0);

        if (_currentDecibel > _maxDecibel) _maxDecibel = _currentDecibel;
        if (_currentDecibel < _minDecibel) _minDecibel = _currentDecibel;
        if (_currentDecibel > _peakDecibel) _peakDecibel = _currentDecibel;

        _totalDecibel += _currentDecibel;
        _readingCount++;
        _waveformData.add(_currentDecibel);

        onDecibelUpdate?.call(_currentDecibel);
      },
      onError: (Object error) {
        print('Noise meter error: $error');
      },
    );
    return true;
  }

  void stop() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
  }

  void _reset() {
    _currentDecibel = 0.0;
    _maxDecibel = 0.0;
    _minDecibel = double.infinity;
    _peakDecibel = 0.0;
    _totalDecibel = 0.0;
    _readingCount = 0;
    // _waveformData.clear();
  }

  void resetStats() {
    _reset();
  }

  void dispose() {
    stop();
  }
}
