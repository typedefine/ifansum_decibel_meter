import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ifansum_decibel_meter/l10n/app_localizations.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:chewie/chewie.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class VideoPreviewPage extends PreviewPage{
   VideoPreviewPage({
    super.key,
     super.filePath,
     super.fileName,
    super.arguments
  });

  @override
  State<StatefulWidget> createState() => VideoPreviewPageState();
}

class VideoPreviewPageState extends _PreviewPageState{

  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  // final ffmpeg = FlutterFFmpeg();

  @override
  void initState() {
    super.initState();
    // try {
    //   _videoController = VideoPlayerController.file(File(widget.filePath))
    //     ..initialize().then((_) {
    //       // 自动播放且循环
    //       _videoController.play();
    //       _videoController.setLooping(true);
    //       setState(() {}); // 刷新界面显示视频
    //     });
    // }
    // catch(e){
    //   print(e);
    // }
    // probeVideo();
    _initializePlayer();

  }

  // Future<void> probeVideo() async {
  //   final rc = await ffmpeg.execute('-i ${widget.filePath}');
  //   print('ffprobe返回码: $rc');
  //   // 可以解析日志输出
  // }


  Future<void> _initializePlayer() async {
    final file = File(widget.filePath!);
    print('路径: ${file.path}');
    print('存在: ${file.existsSync()}');
    print('可读: ${await file.open()}');
    print('大小: ${await file.length()} 字节');
    _videoController = VideoPlayerController.file(File(widget.filePath!));
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      // 自定义控件颜色等
      materialProgressColors: ChewieProgressColors(
        playedColor: Color(0xFF00BCD4),
        handleColor: Color(0xFF00BCD4),
        backgroundColor: Colors.black38,
        bufferedColor: Colors.black26,
      ),
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            '视频加载失败：$errorMessage',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
    _videoController.addListener(() {
      if (_videoController.value.hasError) {
        print('播放器错误: ${_videoController.value.errorDescription}');
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    // _chewieController?.dispose();
    super.dispose();
  }


  @override
  Widget body(l10n){
    return Center(
      child: _chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : CircularProgressIndicator(),
    );

    //  return Center(
    //   child: _videoController.value.isInitialized
    //       ? AspectRatio(
    //     aspectRatio: _videoController.value.aspectRatio,
    //     child: VideoPlayer(_videoController), // 纯视频，无任何控制按钮
    //   )
    //       : CircularProgressIndicator(),
    // );
  }


  @override
  Future<bool> ensureGalleryPermission() async{
    // TODO: implement ensureGalleryPermission

    if (Platform.isAndroid) {
      if (await Permission.videos.request().isGranted) return true;
    } else if (Platform.isIOS) {
      if (await Permission.photos.request().isGranted) return true;
    }

    return super.ensureGalleryPermission();
  }

  @override
  Future<SaveResult?> saveToGallery() async {
    final result = await SaverGallery.saveFile(
      filePath: widget.filePath!,
      fileName: widget.fileName!,
      skipIfExists: false,
      androidRelativePath: "Movies",
    );
    return result;
  }

}


class ImagePreviewPage extends PreviewPage{
   ImagePreviewPage({
    super.key,
     super.filePath,
     super.fileName,
     super.arguments
  });

  @override
  State<StatefulWidget> createState() => ImagePreviewPageState();
}

class ImagePreviewPageState extends _PreviewPageState{
  
  @override
  Widget body(l10n) {
    // TODO: implement body
    return Center(
      child:
          widget.arguments is Uint8List ? Image.memory(widget.arguments):
          widget.filePath != null && widget.filePath!.isNotEmpty ?
           Image.file(File(widget.filePath!)): Container()
      ,
    );
  }


  @override
  Future<SaveResult> saveToGallery() async {
    Uint8List imageBytes;
    if(widget.arguments is Uint8List) {
      imageBytes = widget.arguments;
    }else{
      if(widget.filePath == null || widget.filePath!.isEmpty){
        return SaveResult(false, 'File is not exist');
      }
      imageBytes = File(widget.filePath!).readAsBytesSync();
    }

    final result = await SaverGallery.saveImage(
      imageBytes,
      quality: 60,
      fileName: widget.fileName!,
      androidRelativePath: "Pictures/iFansum/images",
      skipIfExists: false,
    );
    return result;
  }
}


class PreviewPage extends StatefulWidget {
  final String? filePath;
  final String? fileName;
  dynamic arguments;

   PreviewPage({
    super.key, 
     this.filePath,
     this.fileName,
    this.arguments
  });

  @override
  State createState() => _PreviewPageState();

  Future<bool> ensureGalleryPermission() async {
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
}

class _PreviewPageState extends State<PreviewPage> {

  Future<bool> ensureGalleryPermission() async {
    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }


  Future<void> _save(l10n) async {
    if (!await ensureGalleryPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.previewSaveStorage)),//'需要存储权限'
      );
      return;
    }
    try {
      final result = await saveToGallery();
      if (result!.isSuccess == true) {
        final settings = context.read<SettingsProvider>();
        await settings.incrementMediaSaveCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSaveAlbum)),//'已保存到相册'
        );
        Future.delayed(Duration(seconds: 2), () => Navigator.pop(context, true));
      } else {
        throw Exception(result.errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.previewSaveFailure}: $e')),//保存失败
      );
    }
  }

  Future<SaveResult?> saveToGallery() async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body(l10n),
      bottomNavigationBar: Container(
        height: 200,
        color: Colors.black87,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: ()=> _save(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.previewSave),//'保存'
              ),
            ),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget body(l10n){
    return Container();
  }

  Future<void> delete() async{
    if(widget.filePath == null || widget.filePath!.isEmpty) return;
    final file = File(widget.filePath!);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    delete();
    super.dispose();
  }
}