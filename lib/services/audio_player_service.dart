import 'package:just_audio/just_audio.dart';

/// Simple wrapper around [AudioPlayer] to reuse a single player instance
/// across multiple screens if desired.
class AudioPlayerService {
  AudioPlayerService._internal();

  static final AudioPlayerService instance = AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> dispose() async {
    await _player.dispose();
  }
}

