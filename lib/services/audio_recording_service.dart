import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Handles raw audio recording to local files.
///
/// This is separate from [AudioService] which only measures decibels.
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String? _currentFilePath;
  String? get currentFilePath => _currentFilePath;

  /// Starts recording into a file whose name is based on [id].
  ///
  /// The file is stored under the app's documents directory.
  Future<void> startRecording(String id) async {
    if (_isRecording) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$id.m4a';

    // await discardAtPath(filePath);

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _currentFilePath = filePath;
    _isRecording = true;
  }

  /// Stops recording and returns the final file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return _currentFilePath;
    }

    final path = await _recorder.stop();
    _isRecording = false;

    if (path != null) {
      _currentFilePath = path;
      return path;
    }

    return _currentFilePath;
  }

  /// Discards the current recording file if it exists.
  Future<void> discardCurrent() async {
    final path = _currentFilePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    _currentFilePath = null;
  }


  Future<void> discardAtPath(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }


  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
    }
    await _recorder.dispose();
  }
}

