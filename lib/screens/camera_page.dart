import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import 'pro_subscription_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  // Mode: photo or video
  bool _isVideoMode = false;
  bool _isRecordingVideo = false;

  // Audio meter overlay
  final AudioService _audioService = AudioService();
  final LocationService _locationService = LocationService();
  double _currentDb = 0.0;
  double _maxDb = 0.0;
  double _minDb = 0.0;
  double _avgDb = 0.0;
  int _durationSeconds = 0;
  Timer? _timer;
  String _location = '';
  DateTime _startTime = DateTime.now();

  static const int _nonProMediaLimit = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _startAudio();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    _location = await _locationService.getCurrentLocation();
    if (mounted) setState(() {});
  }


  // Future<void> _requestPermissionsAndInit() async {
  //   // 请求相机和麦克风权限（相机通常需要麦克风权限用于录像）
  //   final status = await Permission.camera.request();
  //   final micStatus = await Permission.microphone.request();
  //   if (status.isGranted && micStatus.isGranted) {
  //     await _initCamera();
  //   } else {
  //     // 处理权限被拒绝
  //   }
  // }
  //
  // Future<void> _initCamera() async {
  //   _cameras = await availableCameras();
  //   if (_cameras == null || _cameras!.isEmpty) return;
  //   _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
  //   await _cameraController!.initialize();
  //   if (mounted) setState(() {});
  // }



  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    await _setupCamera(_selectedCameraIndex);
  }


  Future<void> _setupCamera(int index) async {
    if (_cameras.isEmpty) return;

    _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera init error: $e');
    }
  }


  Future<void> _startAudio() async {
    _audioService.onDecibelUpdate = (db) {
      if (mounted) {
        setState(() {
          _currentDb = db;
          _maxDb = _audioService.maxDecibel;
          _minDb = _audioService.minDecibel;
          _avgDb = _audioService.avgDecibel;
        });
      }
    };

    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _durationSeconds =
              DateTime.now().difference(_startTime).inSeconds;
        });
      }
    });

    await _audioService.start();
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_selectedCameraIndex);
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final settings = context.read<SettingsProvider>();
    if (!settings.isPro && settings.mediaSaveCount >= _nonProMediaLimit) {
      _showMediaLimitDialog();
      return;
    }

    try {
      if (_location.isEmpty) {
        await _fetchLocation();
      }
      final rawImage = await _cameraController!.takePicture();
      final watermarkedPath = await _addWatermarkToPhoto(rawImage.path);

      if (watermarkedPath != null) {
        final ok = await _ensureGalleryPermission();
        if (!ok) return;

        final bytes = await File(watermarkedPath).readAsBytes();
        final result = await SaverGallery.saveImage(
          bytes,
          fileName: 'decibel_${DateTime.now().millisecondsSinceEpoch}.jpg',
          skipIfExists: false,
        );
        if (result.isSuccess) {
          await settings.incrementMediaSaveCount();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo saved'),
              backgroundColor: const Color(0xFF2C2C2E),
            ),
          );
        }
      }
    } catch (e) {
      print('Take photo error: $e');
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final settings = context.read<SettingsProvider>();
    if (!settings.isPro && settings.mediaSaveCount >= _nonProMediaLimit) {
      _showMediaLimitDialog();
      return;
    }

    if (_isRecordingVideo) {
      try {
        final video = await _cameraController!.stopVideoRecording();
        setState(() => _isRecordingVideo = false);
        if (mounted) {
          final ok = await _ensureGalleryPermission();
          if (!ok) return;

          final watermarkedPath = await _burnWatermarkOnVideo(video.path);
          final result = await SaverGallery.saveFile(
            filePath: watermarkedPath ?? video.path,
            fileName:
                'decibel_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
            skipIfExists: false,
          );
          if (result.isSuccess) {
            await settings.incrementMediaSaveCount();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved'),
              backgroundColor: const Color(0xFF2C2C2E),
            ),
          );
        }
      } catch (e) {
        print('Stop video error: $e');
      }
    } else {
      try {
        await _cameraController!.startVideoRecording();
        setState(() => _isRecordingVideo = true);
      } catch (e) {
        print('Start video error: $e');
      }
    }
  }

  void _relocate() {
    _audioService.resetStats();
    _startTime = DateTime.now();
    _durationSeconds = 0;
    _fetchLocation();
    setState(() {
      _currentDb = 0;
      _maxDb = 0;
      _minDb = 0;
      _avgDb = 0;
    });
  }

  String get _formattedDuration {
    final m = _durationSeconds ~/ 60;
    final s = _durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _formattedDateTime {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      // _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // _setupCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _audioService.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _addWatermarkToPhoto(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final image = img.copyResize(
        original,
        width: original.width,
        height: original.height,
      );

      final text =
          '${_currentDb.toStringAsFixed(1)} dB · $_location · $_formattedDateTime';

      img.drawString(
        image,
        text,
        font: img.arial24,
        x: 16,
        y: image.height - 40,
        color: img.ColorRgb8(255, 255, 255),
      );

      final outBytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));
      final file = File(path);
      await file.writeAsBytes(outBytes, flush: true);
      return file.path;
    } catch (e) {
      print('Watermark error: $e');
      return null;
    }
  }

  void _showMediaLimitDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          l10n.freeTrialTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.featureUnlimitedPhotos,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProSubscriptionPage(),
                ),
              );
            },
            child: Text(
              l10n.freeTrial,
              style: const TextStyle(color: Color(0xFF00BCD4)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureGalleryPermission() async {
    // iOS: photosAddOnly is sufficient for saving.
    // Android 13+: photos/videos permissions may be required; older versions use storage.
    try {
      final status = await Permission.photosAddOnly.request();
      if (status.isGranted || status.isLimited) return true;
    } catch (_) {}

    try {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
    } catch (_) {}

    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _burnWatermarkOnVideo(String inputPath) async {
    try {
      final inFile = File(inputPath);
      if (!await inFile.exists()) return null;

      if (_location.isEmpty) {
        await _fetchLocation();
      }

      final text =
          '${_currentDb.toStringAsFixed(1)} dB  $_location  $_formattedDateTime';
      final safeText = text
          .replaceAll('\\', '\\\\')
          .replaceAll(':', '\\:')
          .replaceAll("'", "\\'")
          .replaceAll('%', '\\%');

      final fontFile = await _pickFontFile();
      if (fontFile == null) return null;

      final outPath = inputPath.replaceFirst('.mp4', '_wm.mp4');
      final cmd =
          '-hide_banner -y -i "$inputPath" -vf "drawtext=fontfile=$fontFile:text=\'$safeText\':fontcolor=white:fontsize=24:x=16:y=h-60:box=1:boxcolor=black@0.35:boxborderw=10" -c:a copy -c:v libx264 -preset ultrafast -crf 23 "$outPath"';

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        return outPath;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _pickFontFile() async {
    try {
      if (Platform.isAndroid) {
        const p = '/system/fonts/Roboto-Regular.ttf';
        if (await File(p).exists()) return p;
      }
      if (Platform.isIOS) {
        const candidates = [
          '/System/Library/Fonts/Supplemental/Arial.ttf',
          '/System/Library/Fonts/Supplemental/Helvetica.ttf',
        ];
        for (final p in candidates) {
          if (await File(p).exists()) return p;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 关键：在 build 中检查控制器是否已初始化且未释放
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview area
            Expanded(
              child: Stack(
                children: [
                  // Camera preview
                  if (_isCameraInitialized && _cameraController != null)
                    Center(
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              color: Colors.grey, size: 64),
                          SizedBox(height: 16),
                          Text('Initializing camera...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  // Top bar overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                        IconButton(
                          onPressed: _toggleFlash,
                          icon: Icon(
                            _isFlashOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: _isFlashOn
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // dB overlay at bottom of preview
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Current dB
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _currentDb.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'dB',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Date/time and location
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formattedDateTime,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _location,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Stats row
                          Row(
                            children: [
                              _StatChip(
                                  '${l10n.maxLabel}:${_maxDb.toStringAsFixed(1)}'),
                              const SizedBox(width: 16),
                              _StatChip(
                                  '${l10n.minLabel}:${_minDb.toStringAsFixed(1)}'),
                              const SizedBox(width: 16),
                              _StatChip(
                                  '${l10n.avgLabel}:${_avgDb.toStringAsFixed(1)}'),
                              const SizedBox(width: 16),
                              _StatChip(
                                  '${l10n.durationLabel}:$_formattedDuration'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mode selector and controls
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Photo / Video toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isVideoMode = false),
                        child: Column(
                          children: [
                            Text(
                              l10n.photo,
                              style: TextStyle(
                                color: !_isVideoMode
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 16,
                                fontWeight: !_isVideoMode
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 2,
                              color: !_isVideoMode
                                  ? const Color(0xFF00BCD4)
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: () => setState(() => _isVideoMode = true),
                        child: Column(
                          children: [
                            Text(
                              l10n.video,
                              style: TextStyle(
                                color: _isVideoMode
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 16,
                                fontWeight: _isVideoMode
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 2,
                              color: _isVideoMode
                                  ? const Color(0xFF00BCD4)
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Relocate button
                      GestureDetector(
                        onTap: _relocate,
                        child: Column(
                          children: [
                            const Icon(Icons.navigation_outlined,
                                color: Colors.white, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              l10n.relocate,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Capture / Record button
                      GestureDetector(
                        onTap: _isVideoMode
                            ? _toggleVideoRecording
                            : _takePhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _isVideoMode
                                    ? const Color(0xFFEF7B7B)
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Flip button
                      GestureDetector(
                        onTap: _flipCamera,
                        child: Column(
                          children: [
                            const Icon(Icons.sync,
                                color: Colors.white, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              l10n.flip,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String text;
  const _StatChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
      ),
    );
  }
}
