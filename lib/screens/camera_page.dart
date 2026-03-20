import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ifansum_decibel_meter/screens/preview_page.dart';
import 'package:in_app_recorder/flutter_screen_capture.dart';
import 'package:in_app_recorder/screen_recording_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/audio_recording_service.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import 'pro_subscription_page.dart';
import 'package:flutter/rendering.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  // Mode: photo or video
  bool _isVideoMode = false;
  bool _isRecordingVideo = false;
  bool _isLocation = false;
  bool _isTakePicture = false;
  bool _isMerging = false;
  // late WidgetRecorderController _recorderController;
  late ScreenRecorderController _recorderController;
  final AudioRecordingService _audioRecordingService = AudioRecordingService();

  final GlobalKey _repaintKey = GlobalKey();

  // Audio meter overlay
  final AudioService _audioService = AudioService();
  final LocationService _locationService = LocationService();
  double _currentDb = 0.0;
  double _maxDb = 0.0;
  double _minDb = 0.0;
  double _avgDb = 0.0;
  int _durationSeconds = 0;
  // Timer? _timer;
  // late String _location = _locationService.currentLocation;
  DateTime _startTime = DateTime.now();

  late AnimationController _controller;
  DateTime _now = DateTime.now();

  static const int _nonProMediaLimit = 5;


  @override
  void initState() {
    super.initState();
    // 进入全屏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [], // 空数组表示隐藏所有系统UI
    );

    _initCamera();
    _startAudio();
    // _fetchLocation();

    // _recorderController = WidgetRecorderController(
    //   targetFps: 30,
    //   isWithTicker: true,
    // );

    // _recorderController = WidgetRecorderController(
    //   recordAudio: false, // Permission handled automatically
    //   onComplete: (path) => print('Saved: $path'),
    //   onError: (error) => print('Error: $error'),
      // permissionDeniedDialog: (context, openSettings) {
      //   return AlertDialog(
      //     title: const Text('Microphone Access Required'),
      //     content: const Text('Please enable microphone in Settings.'),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.pop(context, false),
      //         child: const Text('Cancel'),
      //       ),
      //       ElevatedButton(
      //         onPressed: () {
      //           openSettings(); // Opens app settings
      //           Navigator.pop(context, true);
      //         },
      //         child: const Text('Open Settings'),
      //       ),
      //     ],
      //   );
      // },
    //   onComplete: (path) {
    //     // setState(() => _isRecordingVideo = false);
    //     // ScaffoldMessenger.of(context).showSnackBar(
    //     //   SnackBar(
    //     //     content: Text('Video saved: $path'),
    //     //     action: SnackBarAction(
    //     //       label: 'Open',
    //     //       onPressed: () => OpenFilex.open(path),
    //     //     ),
    //     //   ),
    //     // );
    //   },
    //   onError: (error) {
    //     setState(() => _isRecordingVideo = false);
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
    //     );
    //   },
    // );
    // _recorderController.fps = 15;
    _initRecorderController();
  }

  Future<void> _initRecorderController()async{
    final tempDirectory = await getTemporaryDirectory();
    final fileName = 'decibel_video_${DateTime
        .now()
        .millisecondsSinceEpoch}.mp4';
    _recorderController = ScreenRecorderController(videoExportPath: '${tempDirectory.path}/$fileName', fps:30, shareMessage: "Hey this is the recorded video",
        shareVideo: false, updateFrameCount: (count){
          // setState(() {
          //   frameCount = count;
          // });
    });
  }


  @override
  void dispose() {
    // _recorderController.dispose();
    _cameraController?.dispose();
    // _audioService.dispose();
    // _timer?.cancel();
    _controller.dispose();
    // 退出全屏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values, // 显示所有系统UI
    );
    super.dispose();
  }


  AppBar _buildAppBar(){
    return AppBar(
      backgroundColor: Colors.black87,
      foregroundColor: Colors.white,
      leading: IconButton(
          onPressed: ()=> Navigator.pop(context),
          icon: Icon(Icons.close, color: Colors.white,)
      ),
      actions: [
        IconButton(
          icon:  Icon(
            _isFlashOn
                ? Icons.flash_on
                : Icons.flash_off,
            color: _isFlashOn
                ? const Color(0xFFFFD54F)
                : Colors.white,
            size: 28,
          ),
          onPressed: _toggleFlash,
        ),
      ],
    );
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
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Camera preview area
              _mainPart(l10n),
              // Mode selector and controls
              _controlPart(l10n),
            ],
          ),
        )
    );
  }


  Widget _controlPart(l10n){
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Photo / Video toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _photoMode(l10n),
              const SizedBox(width: 40),
              _videoMode(l10n),
            ],
          ),

          const SizedBox(height: 20),

          // Bottom controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Relocate button
              _reLocateAction(l10n),

              // Capture / Record button
              _isVideoMode ? _videoAction(l10n) : _photoAction(l10n),

              // Flip button
              _flipCameraAction(l10n),
            ],
          ),

          // const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _photoAction(l10n){
    return GestureDetector(
      onTap: _isTakePicture ? null : ()=>_takePhoto(l10n),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _whiteColor(),
            width: 3,
          ),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoAction(l10n){
    return GestureDetector(
      onTap: _isMerging ? null : ()=> _toggleVideoRecording(l10n),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: _isMerging? Colors.white38 : Colors.white, width: 3),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isRecordingVideo ? 28 : 46,
            height: _isRecordingVideo ? 28 : 46,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(_isMerging?0.3:0.85),//const Color(0xFFEF7B7B),
              borderRadius: BorderRadius.circular(
                  _isRecordingVideo ? 6 : 23),
            ),
          ),
        ),
      ),
    );
  }


  Widget _flipCameraAction(l10n){
    return GestureDetector(
      onTap: _isRecordingVideo || _isMerging ? null : _flipCamera,
      child: Column(
        children: [
           Icon(Icons.sync,
              color: _whiteColor(), size: 28),
          const SizedBox(height: 4),
          Text(
            l10n.flip,
            style: TextStyle(
                color: _whiteColor(), fontSize: 12),
          ),
        ],
      ),
    );
  }


  Widget _reLocateAction(l10n){
    return GestureDetector(
      onTap: _isLocation || _isRecordingVideo ? null : _relocate,
      child: Column(
        children: [
           Icon(Icons.navigation_outlined,
              color: _whiteColor(), size: 28),
          const SizedBox(height: 4),
          Text(
            _isLocation ?
            l10n.relocating
                :
            l10n.relocate,
            style: TextStyle(
                color: _whiteColor(), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _whiteColor(){
    return  _isRecordingVideo ? Colors.white54: Colors.white;
  }


  Widget _videoMode(l10n){
    return  GestureDetector(
      onTap: () =>  _isRecordingVideo || _isMerging ? null:  setState(() => _isVideoMode = true),
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
    );
  }

  Widget _photoMode(l10n){
    return GestureDetector(
      onTap: () => _isRecordingVideo || _isMerging ? null:  setState(() => _isVideoMode = false),
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
    );
  }

  Widget _mainPart(l10n){

    if (_isCameraInitialized && _cameraController != null){
      if(_isVideoMode){
        // return WidgetRecorder (
        //     controller: _recorderController,
        //     child: _targetWidget(l10n),
        //   );
        // return _mainContent(child: WidgetRecorderWrapper(
        //   controller: _recorderController,
        //   child: _targetWidget(l10n),
        // ));
        return Stack(
          children: [
            _mainContent(child: FlutterScreenCapture(
              controller: _recorderController,
              child: _targetWidget(l10n),
            )),
            if(_isMerging)
              Positioned(
                  left: 0,//MediaQuery.of(context).size.width/2.0-30
                  top: MediaQuery.of(context).size.height/2.0-100,
                  child: _buildIOSLoadingScreen(l10n)
              )
          ],
        );
      }else{
        return Stack(
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: _targetWidget(l10n),
            ),
            if(_isTakePicture)
              Positioned(
                  left: 0,//MediaQuery.of(context).size.width/2.0-30
                  top: MediaQuery.of(context).size.height/2.0-100,
                  child: _buildIOSLoadingScreen(l10n)
              )
          ],
        );
      }
    }

    return const Center(
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
    );
  }

  Widget _buildIOSLoadingScreen(l10n) {
    var tintColor = const Color(0xFF00BCD4);
    return
      Container(
        width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child:
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tintColor.withOpacity(0.3),
                  width: 5,
                ),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: tintColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('${l10n.cameraMerge}...',//水印合成中
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetWidget(l10n){
    return Stack(
      children: [
        // Camera preview
        _mainContent(child: CameraPreview(_cameraController!)),
        // dB overlay at bottom of preview
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _watermarkPart(l10n),
        ),
      ],
    );
  }

  Widget _mainContent({required Widget child}){
    Size size = contentSize();
    return Container(
        color: Colors.transparent,
        width: size.width,
        height: size.height,
        child: child
    );
  }

  Size contentSize(){
    return Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height-260
    );
  }

  Widget _watermarkPart(l10n) {
    return Container(
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
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationService.currentLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                  '${l10n.maxLabel}:${_maxDb.toStringAsFixed(1)}'),
              _StatChip(
                  '${l10n.minLabel}:${_minDb.toStringAsFixed(1)}'),
              _StatChip(
                  '${l10n.avgLabel}:${_avgDb.toStringAsFixed(1)}'),
              _StatChip(
                  '${l10n.durationLabel}:$_formattedDuration'),
            ],
          ),
        ],
      ),
    );
  }



  Future<void> _fetchLocation() async {
    if(_isLocation) return;
    _isLocation = true;
    await _locationService.getCurrentLocation();
    _isLocation = false;
    if (mounted) setState(() {});
  }

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
    // _audioService.onDecibelUpdate = (db) {
    //   if (mounted) {
    //     setState(() {
    //       _currentDb = db;
    //       _maxDb = _audioService.maxDecibel;
    //       _minDb = _audioService.minDecibel;
    //       _avgDb = _audioService.avgDecibel;
    //     });
    //   }
    // };

    _startTime = DateTime.now();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1)
    )..addListener(_onTick)
    ..repeat();

    /*
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _durationSeconds =
              DateTime.now().difference(_startTime).inSeconds;
          // _durationSeconds = _audioService.recordSeconds;
          // _durationSeconds++;
          _currentDb = _audioService.currentDecibel;
          _maxDb = _audioService.maxDecibel;
          _minDb = _audioService.minDecibel;
          _avgDb = _audioService.avgDecibel;
        });
      }
    });

     */

    // await _audioService.start();
  }

  void _onTick(){
    if(_isMerging || _isTakePicture) return;
    final newNow = DateTime.now();
    if(newNow.second != _now.second){
      setState(() {
        _now = newNow;
        _durationSeconds =
            DateTime.now().difference(_startTime).inSeconds;
        _currentDb = _audioService.currentDecibel;
        _maxDb = _audioService.maxDecibel;
        _minDb = _audioService.minDecibel;
        _avgDb = _audioService.avgDecibel;
      });
    }
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_selectedCameraIndex);
  }

  void _toggleFlash() async {
    if (_cameraController == null || _isRecordingVideo || _isMerging) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (_) {}
  }


  Future<void> _takePhoto(l10n) async {
    if (_cameraController == null
        || !_cameraController!.value.isInitialized
        || _isTakePicture) {
      return;
    }

    final settings = context.read<SettingsProvider>();
    if (!settings.isPro && settings.mediaSaveCount >= _nonProMediaLimit) {
      _showMediaLimitDialog(l10n);
      return;
    }

    try {
      setState(() {
        _isTakePicture = true;
      });
      // final rawImage = await _cameraController!.takePicture();
      // final watermarkedPath = await _addWatermarkToPhoto(rawImage.path);

      // 1. 找到 RepaintBoundary 的 RenderObject
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 2. 捕获为图像（直接获取像素，无需等待屏幕刷新）

      final image  = await boundary.toImage(pixelRatio: 3.0); // pixelRatio 控制分辨率
      // final image  = await compute(boundary.toImage as ComputeCallback<double, dynamic>, 3.0);

      // 3. 转换为 PNG 字节
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      // // ByteData? byteData = await compute(image.toByteData,ui.ImageByteFormat.png);
      if (byteData == null){
        setState(() {
          _isTakePicture = false;
        });
      }
      // // 4. 保存到临时文件
      final name = 'decibel_${DateTime.now().millisecondsSinceEpoch}.png';
      // final dir = await getTemporaryDirectory();
      // final file = File('${dir.path}/$name');
      final bytes = byteData?.buffer.asUint8List();
      // await file.writeAsBytes(bytes!);
      // await compute(file.writeAsBytes, bytes!);

      Navigator.of(context).push(MaterialPageRoute(builder: (_){
        return ImagePreviewPage(arguments: bytes, fileName: name,);
        // return ImagePreviewPage(filePath: file.path, fileName: name);
      }));

      // print('照片已保存到：${file.path}');

      setState(() {
        _isTakePicture = false;
      });

      return;

      // if (file.path != null) {
      //   final ok = await _ensureGalleryPermission();
      //   if (!ok) return;
      //
      //   // final bytes = await File(watermarkedPath).readAsBytes();
      //   final result = await SaverGallery.saveImage(
      //     bytes,
      //     quality: 60,
      //     fileName: name,
      //     androidRelativePath: "Pictures/iFansum/images",
      //     skipIfExists: false,
      //   );
      //   if (result.isSuccess) {
      //     await settings.incrementMediaSaveCount();
      //   }
      //
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text('Photo saved'),
      //         backgroundColor: const Color(0xFF2C2C2E),
      //       ),
      //     );
      //   }
      // }
    } catch (e) {
      print('Take photo error: $e');
    }
  }

  Future<void> _toggleVideoRecording(l10n) async {

    if(_isMerging) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final settings = context.read<SettingsProvider>();
    if (!settings.isPro && settings.mediaSaveCount >= _nonProMediaLimit) {
      _showMediaLimitDialog(l10n);
      return;
    }

    final fileName = 'decibel_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    if (_isRecordingVideo) {
      try {
       setState(() {
         _isMerging = true;
       });
       await Future.delayed(const Duration(milliseconds: 3000));
       final audioPath = await _audioRecordingService.stopRecording();
       // await Future.delayed(const Duration(milliseconds: 3600));
        // final videoPath = await _recorderController.stop();
        await _recorderController.stopRecording(
          // setState: ()=>  setState(() {
          //   _isRecordingVideo = false;
          //   _durationSeconds = 0;
          // })
        );
        String videoPath = _recorderController.videoExportPath;
       // await Future.delayed(const Duration(milliseconds: 3000));
       // await Future.delayed(const Duration(milliseconds: 300));
        if(videoPath == null || videoPath.isEmpty) {
          setState(() {
            _isMerging = false;
            _isRecordingVideo = false;
            _durationSeconds = 0;
          });
          print('视频文件不存在');
        }

        final File videoFile = File(videoPath);

        // 1. 先检查文件是否存在
        if (videoFile == null || !await videoFile.exists()) {
          setState(() {
            _isMerging = false;
            _isRecordingVideo = false;
            _durationSeconds = 0;
          });
          print('视频文件不存在');
          return;
        }
        //
        // if(audioPath == null || audioPath.isEmpty) {
        //   print('音频文件不存在');
        // }
        //
        //
        // final File audioFile = await File(audioPath!);
        //
        // if (await audioFile.exists() == false) {
        //   print('音频文件不存在');
        //   return;
        // }


        if(audioPath != null && audioPath.isNotEmpty && await File(audioPath).exists()){
          try {
            try {
              final videoStream = await videoFile.open();
              await videoStream.close();
              final audioStream = await File(audioPath).open();
              await audioStream.close();
            } catch (e) {
              print('文件仍不可读，可能需要更长时间');
              await Future.delayed(const Duration(milliseconds: 300));
            }
            await Future.delayed(const Duration(milliseconds: 1800));
            // 合并音视频
            final outputDir = await getTemporaryDirectory();
            final outputPath = '${outputDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';
            // 命令说明：
            // -i 视频文件 -i 音频文件
            // -c:v copy 视频流直接复制（不重新编码，速度快）
            // -c:a aac 音频编码为 AAC（如果音频已经是 AAC 可改用 copy，但需确保格式一致）
            // -map 0:v:0 -map 1:a:0 选择视频的第一个视频流和音频的第一个音频流
            // -shortest 以较短的流为基准截断，防止长度不匹配
            String cmd = '-i $videoPath -i $audioPath '
                '-c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest $outputPath';
            // String cmd = '-i $videoPath -i $audioPath '
            //     '-c:v copy -c:a aac -map 0:v:0 -map 1:a:0 $outputPath';
            final session = await FFmpegKit.execute(cmd);
            // await Future.delayed(Duration(milliseconds: 500));
            // sleep(Duration(seconds: 2));
            // final session = await compute(FFmpegKit.execute,cmd);
            final rc = await session.getReturnCode();
            if (ReturnCode.isSuccess(rc)) {
              try {
                await File(videoPath).delete();
                await File(audioPath).delete();
              } catch (_) {}
              final outFile = File(outputPath);
              if (await outFile.exists()) {
                // Keep file name aligned with record id by restoring original path.
                // await outFile.rename(videoPath);
                videoPath = outputPath;
              }
            }else{
              print('声音合成失败！');
            }
          } catch (_) {

          }
        }
        // setState(() => _isRecordingVideo = false);
        // if(videoPath == null) return;
        // await Future.delayed(Duration(milliseconds: 500));
        await Navigator.of(context).push(MaterialPageRoute(builder: (_){
          return VideoPreviewPage(filePath: videoPath, fileName: fileName);
        }));

        // await Future.delayed(Duration(milliseconds: 500));
        setState(() {
          _isMerging = false;
          _isRecordingVideo = false;
          // _durationSeconds = _audioService.recordSeconds;
          _durationSeconds = 0;
        });
        return;

        // if (mounted) {
        //   final ok = await _ensureGalleryPermission();
        //   if (!ok) return;
        //   final result = await SaverGallery.saveFile(
        //     filePath: videoPath,
        //     fileName:
        //     'decibel_video_${DateTime
        //         .now()
        //         .millisecondsSinceEpoch}.mp4',
        //     skipIfExists: false,
        //     androidRelativePath: "Movies",
        //   );
        //   if (result.isSuccess) {
        //     await settings.incrementMediaSaveCount();
        //   }
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('Video saved'),
        //       backgroundColor: Colors.green//const Color(0xFF2C2C2E),
        //     ),
        //   );
        //   print('视频已保存到：${videoPath}');
        // }
      }
      catch (e) {
        _isMerging = false;
        _durationSeconds = 0;
        setState(() => _isRecordingVideo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
        print('Stop video error: $e');
      }
    }

      /*
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

       */
    else {
      try {
        // await _cameraController!.startVideoRecording();
        // await _recorderController.start();
        // _startTime = DateTime.now();
        // setState((){
        //   _durationSeconds = 0;
        //   _isRecordingVideo = true;
        // });
        // await _recorderController.startRecording(
        //   fileName,
        //   pixelRatio: MediaQuery.devicePixelRatioOf(context),
        // );
        // await Future.delayed(Duration(milliseconds: 100));

        if (await requestMicrophonePermission()) {
          _isRecordingVideo = true;
          setState((){
            _startTime = DateTime.now();
            _durationSeconds = 0;
          });
          await _recorderController.startRecording(
              // setState: ()=> setState((){
              //   _startTime = DateTime.now();
              //   _durationSeconds = 0;
              //   _isRecordingVideo = true;
              // })
          );
          // 开始音频录制
          final id = const Uuid().v4();
          await _audioRecordingService.startRecording(id);
        }

      } catch (e) {
        print('Start video error: $e');
        _durationSeconds = 0;
        setState(() => _isRecordingVideo = false);
      }
    }
  }

  Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
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

  String get _formattedDuration{
    int t = _audioService.recordSeconds;
    // if(_isRecordingVideo){
    //   t = _durationSeconds;
    // }
    final m = t ~/ 60;
    final s = t % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _formattedDateTime {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

/*
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
          '${_currentDb.toStringAsFixed(1)} dB · ${_locationService.currentLocation} · $_formattedDateTime';

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
*/


  void _showMediaLimitDialog(l10n) {
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
            child: Text(
              l10n.cameraOk,//'OK'
              style: const TextStyle(color: Colors.grey),
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

  /*

  Future<String?> _burnWatermarkOnVideo(String inputPath) async {
    try {
      final inFile = File(inputPath);
      if (!await inFile.exists()) return null;

      // if (_location.isEmpty) {
      //   await _fetchLocation();
      // }

      final text =
          '${_currentDb.toStringAsFixed(1)} dB  ${_locationService.currentLocation}  $_formattedDateTime';
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

*/

}

class _StatChip extends StatelessWidget {
  final String text;
  const _StatChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }
}
