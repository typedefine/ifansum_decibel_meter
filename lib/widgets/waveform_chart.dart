import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaveformChart extends StatelessWidget {
  final List<double> data;
  final double maxY;
  final double height;
  final bool showLabels;
  final Color lineColor;

  const WaveformChart({
    super.key,
    required this.data,
    this.maxY = 120,
    this.height = 200,
    this.showLabels = true,
    this.lineColor = const Color(0xFF42A5F5),
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
                  LineChartBarData(
                    spots: List.generate(data.length, (i) {
                      return FlSpot(i.toDouble(), data[i]);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: lineColor,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.5),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
              duration: const Duration(milliseconds: 0),
      ),
    );
  }
}

/// Compact waveform used in record cards
class MiniWaveformChart extends StatelessWidget {
  final List<double> data;
  final double height;
  final Color lineColor;

  const MiniWaveformChart({
    super.key,
    required this.data,
    this.height = 40,
    this.lineColor = const Color(0xFFFF9800),
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
            LineChartBarData(
              spots: List.generate(displayData.length, (i) {
                return FlSpot(i.toDouble(), displayData[i]);
              }),
              isCurved: true,
              curveSmoothness: 0.15,
              color: lineColor,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 0),
      ),
    );
  }
}
