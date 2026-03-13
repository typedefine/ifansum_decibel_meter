import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
/*
class WaveformChart extends StatelessWidget {
  final List<double> data;
  final double maxY;
  final double height;
  final bool showLabels;
  final Color lineColor;
  final double? progress; // 0..1
  final Color progressColor;

  const WaveformChart({
    super.key,
    required this.data,
    this.maxY = 120,
    this.height = 200,
    this.showLabels = true,
    this.lineColor = const Color(0xFF42A5F5),
    this.progress,
    this.progressColor = const Color(0xFF00BCD4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child:
      // data.isEmpty
      //     ? const Center(
      //         child: Text('', style: TextStyle(color: Colors.grey)),
      //       )
      //     :
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: data.length.toDouble() - 1,
          gridData: FlGridData(
            show: showLabels,
            drawVerticalLine: false,
            horizontalInterval: 24,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFF2C2C2E),
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: showLabels,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 35,
                interval: 24,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        color: Color.fromRGBO(79, 92, 125, 1),//Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            ..._buildColoredBars(
              data,
              barWidth: 1.5,
              curved: true,
              showBelow: true,
              fallbackColor: lineColor,
            ),
          ],
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (progress != null &&
                  data.isNotEmpty &&
                  progress! >= 0 &&
                  progress! <= 1)
                VerticalLine(
                  x: (data.length - 1) * progress!,
                  color: progressColor,
                  strokeWidth: 2,
                ),
            ],
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 0),
      ),
    );
  }
}
*/
/// Compact waveform used in record cards
class MiniWaveformChart extends StatelessWidget {
  final List<double> data;
  final double height;
  final Color lineColor;
  final double? progress; // 0..1
  final Color progressColor;

  const MiniWaveformChart({
    super.key,
    required this.data,
    this.height = 40,
    this.lineColor = const Color(0xFFFF9800),
    this.progress,
    this.progressColor = const Color(0xFF00BCD4),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height);
    }

    // Downsample data for mini display
    final maxPoints = 80;
    final List<double> displayData;
    if (data.length > maxPoints) {
      final step = data.length / maxPoints;
      displayData =
          List.generate(maxPoints, (i) => data[(i * step).floor().clamp(0, data.length - 1)]);
    } else {
      displayData = data;
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 120,
          minX: 0,
          maxX: displayData.length.toDouble() - 1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            ..._buildColoredBars(
              displayData,
              barWidth: 1.5,
              curved: true,
              showBelow: false,
              fallbackColor: lineColor,
            ),
          ],
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (progress != null &&
                  displayData.isNotEmpty &&
                  progress! >= 0 &&
                  progress! <= 1)
                VerticalLine(
                  x: (displayData.length - 1) * progress!,
                  color: progressColor,
                  strokeWidth: 2,
                ),
            ],
          ),
          lineTouchData: const LineTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 0),
      ),
    );
  }
}

List<LineChartBarData> _buildColoredBars(
    List<double> points, {
      required double barWidth,
      required bool curved,
      required bool showBelow,
      required Color fallbackColor,
    }) {
  if (points.isEmpty) return const [];

  final spots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i]));

  // Split into segments by color band so a single curve can have different colors.
  final List<List<FlSpot>> segments = [];
  final List<Color> segmentColors = [];

  List<FlSpot> current = [spots.first];
  Color currentColor = _dbColor(spots.first.y, fallbackColor: fallbackColor);

  for (int i = 1; i < spots.length; i++) {
    final s = spots[i];
    final c = _dbColor(s.y, fallbackColor: fallbackColor);
    if (c != currentColor) {
      segments.add(current);
      segmentColors.add(currentColor);
      current = [spots[i - 1], s]; // keep continuity
      currentColor = c;
    } else {
      current.add(s);
    }
  }
  segments.add(current);
  segmentColors.add(currentColor);

  return List.generate(segments.length, (idx) {
    final color = segmentColors[idx];
    return LineChartBarData(
      spots: segments[idx],
      isCurved: curved,
      curveSmoothness: 0.2,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: showBelow,
        color: color.withOpacity(0.5),
      ),
    );
  });
}

Color _dbColor(double db, {required Color fallbackColor}) {
  // Based on the provided segment colors.
  if (db < 10) return const Color.fromRGBO(15, 235, 70, 1);
  if (db < 20) return const Color.fromRGBO(55, 205, 62, 1);
  if (db < 30) return const Color.fromRGBO(85, 185, 56, 1);
  if (db < 40) return const Color.fromRGBO(115, 165, 50, 1);
  if (db < 50) return const Color.fromRGBO(155, 155, 44, 1);
  if (db < 60) return const Color.fromRGBO(195, 145, 38, 1);
  if (db < 70) return const Color.fromRGBO(235, 125, 32, 1);
  if (db < 80) return const Color.fromRGBO(205, 105, 26, 1);
  if (db < 90) return const Color.fromRGBO(185, 85, 20, 1);
  if (db < 100) return const Color.fromRGBO(155, 65, 14, 1);
  if (db < 110) return const Color.fromRGBO(125, 40, 8, 1);
  if (db <= 120) return const Color.fromRGBO(95, 15, 2, 1);
  return fallbackColor;
}
