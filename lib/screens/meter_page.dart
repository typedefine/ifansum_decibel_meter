import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/noise_record.dart';
import '../providers/records_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/device_info_service.dart';
import '../services/location_service.dart';
import '../tool_utils.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/waveform_chart.dart';
import 'decibel_standard_screen.dart';

class MeterPage extends StatefulWidget {
  const MeterPage({super.key});

  @override
  State<MeterPage> createState() => _MeterPageState();
}

class _MeterPageState extends State<MeterPage> {
  final AudioService _audioService = AudioService();
  final LocationService _locationService = LocationService();

  bool _isRecording = false;
  bool _isMeasuring = false;
  double _currentDb = 0.0;
  double _maxDb = 0.0;
  double _avgDb = 0.0;
  int _recordSeconds = 0;
  Timer? _timer;
  late List<double> _realtimeWaveform = [];//[0,0,0,0,0,0,0,0,0,0,0,0];
  String _location = '';

  @override
  void initState() {
    super.initState();

    _startMeasuring();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if(settings.autoRecord){
        _toggleRecording();
      }
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    _location = await _locationService.getCurrentLocation();
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

    await _audioService.start();
    _isMeasuring = true;
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    _audioService.resetStats();
    // _realtimeWaveform.clear();
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
  }

  void _stopRecording() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
    });
  }

  void _resetMeasurement() {
    _audioService.resetStats();
    // _realtimeWaveform.clear();
    _realtimeWaveform.add(0.0);
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

    if(!settings.isPro && _recordSeconds > 20){
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title:
          Container(
            height: 30,
            child: Center(
              child:
          Text(l10n.limitTimeTitle,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
          ),
            )),
          content:
          Container(
            height: 60,
            child: Center(
              child:
              Text(l10n.limitTimeContent,
                  style: const TextStyle(color: Colors.black, fontSize: 14)
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
                _saveData(context);
              },
              child: Container(
                height: 50,
                width: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(25)
                ),
                child: Center(
                  child: Text(
                    l10n.limitTimeFree,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15,),

            GestureDetector(
              onTap: (){
                Navigator.pop(context);
                if(_recordSeconds > 20 && _realtimeWaveform.length > 30){

                }
                _saveData(context);
              },
              child: Container(
                height: 50,
                width: 260,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(25)
                ),
                child: Center(child: Text(
                  l10n.limitTimeLast20s,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                )),
              ),
            ),

            const SizedBox(height: 15,),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 50,
                width: 260,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(25)
                ),
                child: Center(child:Text(
                  l10n.limitTimeClose,
                  style: const TextStyle(fontSize: 14, color: Colors.black),),
                ),),
            )

          ],
        ),
      );
    }else{
      _saveData(context);
    }
  }

  Future<void> _saveData(BuildContext context) async {
    int i=0;
    for (; i<_realtimeWaveform.length;i++) {
      var e = _realtimeWaveform[i];
      if(e != 0){
        break;
      }
    }
    _realtimeWaveform.removeRange(0, i);

    final settings = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final records = context.read<RecordsProvider>();
    String name = '${l10n.translate("noise_record_prefix")} ${records.records.length + 1}';
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

    if (result != null && result.isNotEmpty) {
      //   setState(() {
      //     _record.name = result;
      //   });
      //   context.read<RecordsProvider>().updateRecord(_record);

      final deviceInfo = await DeviceInfoService.getDeviceString();

      final record = NoiseRecord(
        id: const Uuid().v4(),
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
        waveformData: List.from(_realtimeWaveform),
      );

      await records.addRecord(record);

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
