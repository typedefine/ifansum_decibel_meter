import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/noise_record.dart';
import '../providers/records_provider.dart';
import '../widgets/waveform_chart.dart';

class RecordDetailPage extends StatefulWidget {
  final NoiseRecord record;

  const RecordDetailPage({super.key, required this.record});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late NoiseRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Color _getWaveformColor() {
    if (_record.avgDecibel < 60) return const Color(0xFF66BB6A);
    if (_record.avgDecibel < 70) return const Color(0xFFFFCA28);
    if (_record.avgDecibel < 80) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          _record.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform player card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Play button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3A3A3C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 8),
                        // Waveform
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: MiniWaveformChart(
                              data: _record.waveformData,
                              height: 36,
                              lineColor: _getWaveformColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: 48),
                        const Text('00:00',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        Text(_record.formattedDuration,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Info section
              Text(
                l10n.basicInfo,
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _InfoCard(
                children: [
                  _InfoRow(
                    label: l10n.nameLabel,
                    value: _record.name,
                    hasChevron: true,
                    onTap: () => _editName(context),
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.timeLabel,
                    value: _record.formattedDate,
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.recordDuration,
                    value: _record.formattedDuration,
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.device,
                    value: _record.deviceInfo,
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.location,
                    value: _record.location.isEmpty
                        ? '-'
                        : _record.location,
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.notes,
                    value: _record.notes.isEmpty ? '' : _record.notes,
                    hasChevron: true,
                    onTap: () => _editNotes(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Measurement Info section
              Text(
                l10n.measurementInfo,
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _InfoCard(
                children: [
                  _InfoRow(
                    label: l10n.frequencyWeighting,
                    value: _record.frequencyWeighting,
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.responseTime,
                    value:
                        '${_record.responseTimeMs >= 500 ? l10n.slow : "Fast"} ${_record.responseTimeMs}ms',
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.calibration,
                    value:
                        '${_record.calibration >= 0 ? "+" : ""}${_record.calibration.toStringAsFixed(2)} dB',
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.maxDecibel,
                    value: _record.maxDecibel.toStringAsFixed(1),
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.minDecibel,
                    value: _record.minDecibel.toStringAsFixed(1),
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.avgDecibel,
                    value: _record.avgDecibel.toStringAsFixed(1),
                  ),
                  const _Divider(),
                  _InfoRow(
                    label: l10n.peakValue,
                    value: _record.peakValue.toStringAsFixed(1),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: _record.name);
    final l10n = AppLocalizations.of(context);
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
      setState(() {
        _record.name = result;
      });
      context.read<RecordsProvider>().updateRecord(_record);
    }
  }

  Future<void> _editNotes(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _record.notes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(l10n.editNotes,//'Edit Notes'
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
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
            child: Text(l10n.editNotesCancel,//'Cancel'
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.editNotesSave,//'Save'
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _record.notes = result;
      });
      context.read<RecordsProvider>().updateRecord(_record);
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool hasChevron;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.hasChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),

            if (value.length > 15)
              Expanded(
               child: Text(
                   value,
                   style: const TextStyle(
                       color: Colors.grey,
                       fontSize: 12),
                 ),
           )
            else
            ...[
              Text(
              value,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14)
              ),
              const SizedBox(width: 8),
            ],
            if (hasChevron) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: const Color(0xFF3A3A3C),
    );
  }
}
