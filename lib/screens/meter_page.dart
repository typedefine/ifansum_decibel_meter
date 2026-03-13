import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../l10n/app_localizations.dart';
import '../models/noise_record.dart';
import '../providers/records_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/audio_recording_service.dart';
import '../services/device_info_service.dart';
import '../services/location_service.dart';
import '../tool_utils.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/waveform_chart.dart';
import 'decibel_standard_screen.dart';
import 'pro_subscription_page.dart';

class MeterPage extends StatefulWidget {
  const MeterPage({super.key});

  @override
  State<MeterPage> createState() => _MeterPageState();
}

class _MeterPageState extends State<MeterPage> {
  final AudioService _audioService = AudioService();
  final LocationService _locationService = LocationService();
  final AudioRecordingService _audioRecordingService = AudioRecordingService();

  bool _isRecording = false;
  double _currentDb = 0.0;
  double _maxDb = 0.0;
  double _avgDb = 0.0;
  int _recordSeconds = 0;
  Timer? _timer;
  late List<double> _realtimeWaveform = [];//[0,0,0,0,0,0,0,0,0,0,0,0];
   late List<double> _singleWaveform = [];
  String _location = '';
  String? _currentRecordId;
  String? _currentAudioPath;

  @override
  void initState() {
    super.initState();

    _startMeasuring();
    // _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    _location = await _locationService.getCurrentLocation();
    // if (mounted) {
    //   setState(() {});
    // }
  }

  Future<void> _startMeasuring() async {
    DateTime lastTime = DateTime.now();
    DateTime now = lastTime;
    _audioService.onDecibelUpdate = (db) {
      if (mounted && _isRecording) {
        setState(() {
          _currentDb = db;
          _maxDb = _audioService.maxDecibel;
          _avgDb = _audioService.avgDecibel;
        });
        if(now.difference(lastTime).inMilliseconds > 1200){
          lastTime = now;
          setState(() {
            _realtimeWaveform.add(db);
            _singleWaveform.add(db);
          });
        }
      }
      now = DateTime.now();
    };

    // _audioService.onDecibelUpdate = (db) {
    //   if (mounted && _isRecording) {
    //       setState(() {
    //         _currentDb = db;
    //         _maxDb = _audioService.maxDecibel;
    //         _avgDb = _audioService.avgDecibel;
    //         _realtimeWaveform.add(db);
    //       });
    //   }
    // };

    bool r = await _audioService.start();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if(settings.autoRecord && r){
      // _toggleRecording();
      await _startRecording();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final id = const Uuid().v4();
    _currentRecordId = id;
    await _audioRecordingService.startRecording(id);
    _audioService.resetStats();
    // _realtimeWaveform.clear();
    _singleWaveform.clear();
    if(_realtimeWaveform.isEmpty){
      _realtimeWaveform = [0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0,0,0,0];
    }

    _recordSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordSeconds++;
        });
      }
    });

    setState(() {
      _isRecording = true;
    });

    _fetchLocation();
  }

  Future<void> _stopRecording({bool autoStop = false}) async {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
    });
    _currentAudioPath = await _audioRecordingService.stopRecording();
    if(!autoStop){
      await _audioRecordingService.discardCurrent();
    }
  }

  void _resetMeasurement() {
    _audioService.resetStats();
    // _realtimeWaveform.clear();
    _singleWaveform.clear();
    _realtimeWaveform.add(0.0);
    _singleWaveform.add(0.0);
    _recordSeconds = 0;
    setState(() {
      _currentDb = 0.0;
      _maxDb = 0.0;
      _avgDb = 0.0;
    });
  }

  Future<void> _saveRecord(BuildContext context) async {
    if (_realtimeWaveform.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    // Ensure file is finalized before saving.
    if (_isRecording) {
      await _stopRecording(autoStop: true);
    }

    if (!settings.isPro && _recordSeconds > 20) {
      // final choice =
      await showDialog<_LongSaveChoice>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          title: Text(
            l10n.limitTimeTitle,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            '${l10n.limitTimeContent}\n\n${l10n.limitUseTimes}${settings.longRecordingTrialRemaining}',//Remaining usable times:
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.pop(context);
                _cancelAndDeleteRecord();
              },//=> Navigator.pop(context, _LongSaveChoice.cancel)
              child: Text(
                l10n.limitTimeClose,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: (){
                _saveLast20Seconds(context);
              },//=> Navigator.pop(context, _LongSaveChoice.last20)
              child: Text(
                l10n.limitTimeLast20s,
                style: const TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
            TextButton(
              onPressed: (){
                _freeTrial(context);
              },//=> Navigator.pop(context, _LongSaveChoice.freeTrial)
              child: Text(
                l10n.limitTimeFree,
                style: const TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
          ],
        ),
      );

       /*

      if (choice == null || choice == _LongSaveChoice.cancel) {
        // await _audioRecordingService.discardCurrent();
        // await _audioRecordingService.discardAtPath(_currentAudioPath);
        // _currentAudioPath = null;
        // _currentRecordId = null;
        // _resetMeasurement();
        _cancelAndDeleteRecord();
        return;
      }

      // if (choice == _LongSaveChoice.freeTrial) {
      //   if (settings.longRecordingTrialRemaining <= 0) {
      //     if (context.mounted) {
      //       Navigator.of(context).push(
      //         MaterialPageRoute(
      //           builder: (_) => const ProSubscriptionPage(),
      //         ),
      //       );
      //     }
      //     return;
      //   }
      //   await settings.incrementLongRecordingTrialUsed();
      //   await _saveData(context);
      //   return;
      // }

      await _saveLast20Seconds(context);
      return;
      */
    }else{
      await _saveData(context);
    }
  }

  Future<void> _freeTrial(BuildContext context) async{
    final settings = context.read<SettingsProvider>();
    if (settings.longRecordingTrialRemaining <= 0) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProSubscriptionPage(),
          ),
        );
      }
      return;
    }
    // else{
    //   Navigator.pop(context);
    // }
    await settings.incrementLongRecordingTrialUsed();
    await _saveData(context, isNotProAndOver20s: true);
    return;
  }

  Future<void> _saveData(BuildContext context,{bool isNotProAndOver20s = false}) async {
    int i=0;
    for (; i<_singleWaveform.length;i++) {
      var e = _singleWaveform[i];
      if(e != 0){
        break;
      }
    }
    _singleWaveform.removeRange(0, i);

    final settings = context.read<SettingsProvider>();
    final records = context.read<RecordsProvider>();
    /*
    String name = '${l10n.noiseRecordPrefix} ${records.records.length + 1}';
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title:
        Text(l10n.editRecordName,//'Edit Name'
            style: TextStyle(color: Colors.white)),
        content: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00BCD4)),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.editRecordNameCancel,//'Cancel'
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.editRecordNameSave,//'Save'
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
    */

    String? result = await _noiseNameInput(context);

    if (result != null && result.isNotEmpty) {
      //   setState(() {
      //     _record.name = result;
      //   });
      //   context.read<RecordsProvider>().updateRecord(_record);

      final deviceInfo = await DeviceInfoService.getDeviceString();
      final recordId = _currentRecordId ?? const Uuid().v4();

      final record = NoiseRecord(
        id: recordId,
        name: result,
        createdAt: DateTime.now(),
        durationSeconds: _recordSeconds,
        deviceInfo: deviceInfo,
        location: _location,
        frequencyWeighting: settings.frequencyWeighting,
        responseTimeMs: settings.responseFrequencyMs,
        calibration: settings.calibration,
        maxDecibel: _audioService.maxDecibel,
        minDecibel: _audioService.minDecibel,
        avgDecibel: _audioService.avgDecibel,
        peakValue: _audioService.peakDecibel,
        waveformData: List.from(_singleWaveform),
        audioFilePath: _currentAudioPath,
      );

      await records.addRecord(record);

      _afterSaveData(context, isOver20s: isNotProAndOver20s);

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         '${l10n.records} saved',
      //         style: const TextStyle(color: Colors.white),
      //       ),
      //       backgroundColor: const Color(0xFF2C2C2E),
      //       duration: const Duration(seconds: 2),
      //     ),
      //   );
      // }
      //
      // _resetMeasurement();
    } else {
      // User cancelled saving: remove audio file to avoid affecting next recording.
      // await _audioRecordingService.discardCurrent();
      // await _audioRecordingService.discardAtPath(_currentAudioPath);
      // _currentAudioPath = null;
      // _currentRecordId = null;
      // _resetMeasurement();
      if(!isNotProAndOver20s){
        await _cancelAndDeleteRecord();
      }
    }
  }

  void _afterSaveData(BuildContext context, {bool isOver20s = false}){

    if(isOver20s){
      Navigator.pop(context);
    }

    final l10n = AppLocalizations.of(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.records} saved',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2C2C2E),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _resetMeasurement();
  }

  Future<String?> _noiseNameInput(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final records = context.read<RecordsProvider>();
    String name = '${l10n.noiseRecordPrefix} ${records.records.length + 1}';
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title:
        Text(l10n.editRecordName,//'Edit Name'
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.editRecordNameCancel,//'Cancel'
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.editRecordNameSave,//'Save'
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _cancelAndDeleteRecord() async{
    // User cancelled saving: remove audio file to avoid affecting next recording.
    // await _audioRecordingService.discardCurrent();
    await _audioRecordingService.discardAtPath(_currentAudioPath);
    _currentAudioPath = null;
    _currentRecordId = null;
    _resetMeasurement();
  }

  Future<void> _saveLast20Seconds(BuildContext context) async {
    final totalSeconds = _recordSeconds <= 0 ? 1 : _recordSeconds;
    final pointsPerSecond = _realtimeWaveform.isEmpty
        ? 1.0
        : (_realtimeWaveform.length / totalSeconds);
    final lastPoints =
        (pointsPerSecond * 20).round().clamp(1, _realtimeWaveform.length);

    final trimmedWaveform = _realtimeWaveform.isEmpty
        ? <double>[]
        : _realtimeWaveform.sublist(_realtimeWaveform.length - lastPoints);

    final originalPath = _currentAudioPath;
    final trimmedAudioPath = await _trimAudioToLast20Seconds(originalPath);

    final settings = context.read<SettingsProvider>();
    final records = context.read<RecordsProvider>();

    /*
    String name =
        '${l10n.noiseRecordPrefix} ${records.records.length + 1}';
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(l10n.editRecordName,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.editRecordNameCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.editRecordNameSave,
                style: const TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
    */

    String? result = await _noiseNameInput(context);
    if (result == null || result.isEmpty) {
      // await _audioRecordingService.discardCurrent();
      // await _audioRecordingService.discardAtPath(_currentAudioPath);
      // _currentAudioPath = null;
      // _currentRecordId = null;
      // _resetMeasurement();
      // await _cancelAndDeleteRecord();
      return;
    }

    final deviceInfo = await DeviceInfoService.getDeviceString();
    final recordId = _currentRecordId ?? const Uuid().v4();

    final maxDb =
        trimmedWaveform.isEmpty ? 0.0 : trimmedWaveform.reduce((a, b) => a > b ? a : b);
    final minDb =
        trimmedWaveform.isEmpty ? 0.0 : trimmedWaveform.reduce((a, b) => a < b ? a : b);
    final avgDb = trimmedWaveform.isEmpty
        ? 0.0
        : trimmedWaveform.reduce((a, b) => a + b) / trimmedWaveform.length;

    final record = NoiseRecord(
      id: recordId,
      name: result,
      createdAt: DateTime.now(),
      durationSeconds: 20,
      deviceInfo: deviceInfo,
      location: _location,
      frequencyWeighting: settings.frequencyWeighting,
      responseTimeMs: settings.responseFrequencyMs,
      calibration: settings.calibration,
      maxDecibel: maxDb,
      minDecibel: minDb,
      avgDecibel: avgDb,
      peakValue: maxDb,
      waveformData: List.from(trimmedWaveform),
      audioFilePath: trimmedAudioPath,
    );

    await records.addRecord(record);

    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         '${l10n.records} saved',
    //         style: const TextStyle(color: Colors.white),
    //       ),
    //       backgroundColor: const Color(0xFF2C2C2E),
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    // }
    //
    // _resetMeasurement();

    _afterSaveData(context, isOver20s: true);
  }

  Future<String?> _trimAudioToLast20Seconds(String? inputPath) async {
    if (inputPath == null) return null;
    try {
      final inFile = File(inputPath);
      if (!await inFile.exists()) return inputPath;

      final outPath = inputPath.replaceFirst('.m4a', '_trim.m4a');

      final cmd =
          '-hide_banner -y -sseof -20 -i "$inputPath" -t 20 -c:a aac -b:a 128k "$outPath"';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        try {
          await inFile.delete();
        } catch (_) {}
        final outFile = File(outPath);
        if (await outFile.exists()) {
          // Keep file name aligned with record id by restoring original path.
          await outFile.rename(inputPath);
          return inputPath;
        }
      }
    } catch (_) {}
    return inputPath;
  }

  String get _formattedTime {
    final minutes = _recordSeconds ~/ 60;
    final seconds = _recordSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // dB-A chip
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      // color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(width: 1, color: const Color(0xFF2C2C2E))
                    ),
                    child: Text(
                      'dB-${settings.frequencyWeighting}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Book icon (reference info)
                  IconButton(
                    onPressed: (){
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DecibelStandardScreen())
                      );
                    },
                    //_showNoiseReference(context),
                    icon: const Icon(Icons.menu_book_outlined,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // Realtime waveform chart
            Container(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 30),
              child: WaveformChart(
                  data: _realtimeWaveform.length > 200
                      ? _realtimeWaveform
                      .sublist(_realtimeWaveform.length - 200)
                      : _realtimeWaveform,
                  height: 280,
                  maxY: 120,
                  showLabels: true,
                  lineColor: const Color(0xFF00BCD4)//Color.fromRGBO(88, 189, 230, 1), //ToolUtil.rgbToColor(34, 36, 38)//const Color(0xFF42A5F5),
              ),
            ),

            // Gauge
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ToolUtil.rgbToColor(23, 23, 25),//Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Positioned(
                            top: 5,
                            left: 24,
                            child: _textWidget(l10n.average, _avgDb.toStringAsFixed(1))
                        ),
                        GaugeWidget(
                          currentDb: _currentDb,
                          avgDb: _avgDb,
                          maxDb: _maxDb,
                        ),
                        Positioned(
                            top: 5,
                            right: 24,
                            child: _textWidget(l10n.maximum, _maxDb.toStringAsFixed(1))
                        ),
                      ],
                    ),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button
                        _ControlButton(
                          icon: Icons.refresh,
                          onTap: _resetMeasurement,
                          enable: _isRecording,
                          size: 52,
                        ),
                        const SizedBox(width: 32),

                        // Record/Stop button
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isRecording ? 28 : 46,
                                height: _isRecording ? 28 : 46,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.85),//const Color(0xFFEF7B7B),
                                  borderRadius: BorderRadius.circular(
                                      _isRecording ? 6 : 23),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Save button
                        _ControlButton(
                          icon: Icons.download,
                          onTap: () => _saveRecord(context),
                          enable: _isRecording,
                          size: 52,
                        ),
                      ],
                    ),

                    SizedBox(
                        height: 30,
                        child: Visibility(
                            visible: _isRecording,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                  _formattedTime,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  )
                              ),
                            )
                        )
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      );
  }

  Widget _textWidget(String title, String value){
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(fontSize: 16, color: Colors.white60),)
      ],
    );
  }

/*
  void _showNoiseReference(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      enableDrag: false,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            l10n.decibelStandard,//'Noise Reference',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _referenceRow('0-20 dB', 'Barely audible (rustling leaves)'),
          _referenceRow('20-40 dB', 'Quiet (whisper, library)'),
          _referenceRow('40-60 dB', 'Moderate (normal conversation)'),
          _referenceRow('60-80 dB', 'Loud (vacuum cleaner, traffic)'),
          _referenceRow('80-100 dB', 'Very loud (lawn mower, concert)'),
          _referenceRow('100-120 dB', 'Extremely loud (siren, jet)')
            ]
          )
        );
      }
    );
  }

  Widget _referenceRow(String level, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            // width: 100,
            child: Text(
              level,
              style: TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
*/
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool? enable;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.enable = true,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enable == true ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black38,//Color(0xFF2C2C2E),
          shape: BoxShape.circle,
          border: Border.all(width: 0.5, color: Colors.white38)
        ),
        child: Icon(
            icon,
            color: Colors.white.withOpacity(enable == true ?1:0.5),
            size: size * 0.45
        ),
      ),
    );
  }
}

enum _LongSaveChoice { freeTrial, last20, cancel }
