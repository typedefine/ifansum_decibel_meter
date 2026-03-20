import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/noise_record.dart';
import '../providers/records_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/record_card.dart';
import 'record_detail_page.dart';
import 'pro_subscription_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final AudioPlayer _player = AudioPlayerService.instance.player;
  String? _playingRecordId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    // TODO: implement dispose
    stop();
    super.dispose();
  }

  void stop(){
    if(_player.playing){
      _player.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final records = context.read<RecordsProvider>();
      if (!records.isLoaded) {
        records.loadRecords();
      }
    });

    _player.positionStream.listen((pos) {
      // if (!mounted) return;
      // setState(() {
      //   _position = pos;
      // });
      positionChanged(pos);
    });
    _player.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });
    _player.playerStateStream.listen((state) {
      // if (!mounted) return;
      // setState(() {
      //   _position = Duration.zero;
      // });
      stateChanged(state);
    });
  }

  void stateChanged(PlayerState state){
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      if (_player.playing && state.processingState == ProcessingState.completed) {
        _player.pause();
      }
    });
  }

  void positionChanged(Duration p){
    if (!mounted) return;
    setState(() {
      // _playingRecordId = id;
      // if(_playingRecordId == id){
        _position = p;
      // }
    });
  }

  Future<void> _togglePlayRecord(NoiseRecord record) async {
    final path = record.audioFilePath;
    if (path == null) return;

    // if (_playingRecordId == record.id && _player.playing) {
    //   await _player.pause();
    //   return;
    // }
    //
    // // if (_playingRecordId != record.id) {
    //   _playingRecordId = record.id;
    //   _position = Duration.zero;
    //   _duration = Duration.zero;
    //   await _player.setFilePath(path);
    // // }
    // await _player.play();

    if (_playingRecordId == record.id) {
      if(_player.playing){
        await _player.pause();
      }else{
        await _player.setFilePath(path);
        await _player.play();
      }
    } else{
      _playingRecordId = record.id;
      _position = Duration.zero;
      _duration = Duration.zero;
      await _player.setFilePath(path);
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final records = context.watch<RecordsProvider>();
    final settings = context.watch<SettingsProvider>();
    final isPro = settings.isPro;
    final allRecords = records.records;

    // bool isInCurPage = Provider.of<SettingsProvider>(context, listen:true).curPageIndex == 2;
    if(settings.curPageIndex != 2){//!isInCurPage
      stop();
    }

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.records,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: allRecords.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined,
                            color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecords,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    physics: !isPro && allRecords.length > 3 ?
                    NeverScrollableScrollPhysics():AlwaysScrollableScrollPhysics(),
                    itemCount: allRecords.length,
                    itemBuilder: (context, index) {
                      final record = allRecords[index];
                      final canModify =
                          isPro || index < 3; // non-pro: only first 3 items
                      final isPlaying =
                          _playingRecordId == record.id && _player.playing;
                      final progress = (_playingRecordId == record.id &&
                              _duration.inMilliseconds > 0)
                          ? (_position.inMilliseconds /
                              _duration.inMilliseconds)
                          : null;
                      return Dismissible(
                        key: Key(record.id),
                        direction: canModify
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (canModify) {
                            records.deleteRecord(record.id);
                          }
                        },
                        child: RecordCard(
                          record: record,
                          isPlaying: isPlaying,
                          progress: progress == null
                              ? null
                              : progress.clamp(0.0, 1.0),
                          onPlayTap: () => _togglePlayRecord(record),
                          onTap: () {
                            if(!isPro && index >= 3) return;
                            Duration position = Duration.zero;
                            // if (_playingRecordId == record.id && _player.playing) {
                            //   position = _position;
                            // }
                            // _playingRecordId = record.id;
                            if (_playingRecordId == record.id){
                              position = _position;
                            }else{
                              _playingRecordId = record.id;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_){
                                  return RecordDetailPage(
                                    record: record,
                                    position: position,
                                    positionCallback: positionChanged,
                                    stateCallback: stateChanged,
                                  );
                                }

                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
              visible: !isPro && allRecords.length > 3,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF00E5CC).withOpacity(0.5),
                        ]
                    )
                ),
                child: _buildUnlockBanner(context, l10n),
              )
          ))
        ],
      ),
    );
  }

  Widget _buildUnlockBanner(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _openProPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5CC),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
              child: Text(
                l10n.unlockFree,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.nonProLimit,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _openProPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProSubscriptionPage()),
    );
  }
}
