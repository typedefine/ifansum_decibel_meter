import 'package:flutter/material.dart';
import '../models/noise_record.dart';
import 'waveform_chart.dart';

class RecordCard extends StatelessWidget {
  final NoiseRecord record;
  final VoidCallback? onTap;
  final bool isLocked;

  const RecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.isLocked = false,
  });

  // Color _getWaveformColor() {
  //   if (record.avgDecibel < 40) return const Color(0xFF66BB6A);
  //   if (record.avgDecibel < 60) return const Color(0xFFFFCA28);
  //   if (record.avgDecibel < 80) return const Color(0xFFFF9800);
  //   return const Color(0xFFEF5350);
  // }

  Color _getWaveformColor() {
    if (record.avgDecibel < 60) return const Color(0xFF66BB6A);
    if (record.avgDecibel < 70) return const Color(0xFFFFCA28);
    if (record.avgDecibel < 80) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      record.formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Waveform with play button
                Row(
                  children: [
                    // Play button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3A3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini waveform
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MiniWaveformChart(
                          data: record.waveformData,
                          height: 36,
                          lineColor: _getWaveformColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Duration row
                Row(
                  children: [
                    const SizedBox(width: 44),
                    const Text(
                      '00:00',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      record.formattedDuration,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            // Lock overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
