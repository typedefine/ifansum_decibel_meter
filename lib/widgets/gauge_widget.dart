import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class GaugeWidget extends StatelessWidget {
  final double currentDb;
  final double avgDb;
  final double maxDb;

  const GaugeWidget({
    super.key,
    required this.currentDb,
    required this.avgDb,
    required this.maxDb,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: CustomPaint(
        painter: _GaugePainter(
          currentDb: currentDb,
          avgDb: avgDb,
          maxDb: maxDb,
          context: context,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double currentDb;
  final double avgDb;
  final double maxDb;
  final BuildContext context;

  _GaugePainter({
    required this.currentDb,
    required this.avgDb,
    required this.maxDb,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final l10n = AppLocalizations.of(context);
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    // Gauge arc angles: from 210 degrees to -30 degrees (240 degree sweep)
    // const startAngle = 270.0;//360.0;//210.0;
    // const sweepAngle = 540.0;//360.0;//240.0;

    const startAngle = 360.0;//210.0;
    const sweepAngle = 360.0;//240.0;

    // Draw background arc
    _drawBackgroundArc(canvas, center, radius, startAngle, sweepAngle);

    // Draw colored arc segments
    _drawColoredArc(canvas, center, radius, startAngle, sweepAngle);

    // Draw tick marks
    _drawTicks(canvas, center, radius, startAngle, sweepAngle);

    // Draw noise level labels
    _drawLabels(canvas, center, radius, startAngle, sweepAngle, l10n);

    // Draw scale numbers (0 and 120)
    _drawScaleNumbers(canvas, center, radius, startAngle, sweepAngle);

    // Draw average and max labels
    // _drawStatsLabels(canvas, center, radius, l10n);

    // Draw needle
    _drawNeedle(canvas, center, radius, startAngle, sweepAngle);

    // Draw center dB value
    _drawCenterValue(canvas, center, l10n);
  }

  void _drawBackgroundArc(
      Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      _degToRad(startAngle),
      _degToRad(sweepAngle),
      false,
      paint,
    );
  }

  void _drawColoredArc(
      Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle) {
    // Color segments: green (0-40), yellow-green (40-60), orange (60-80), red (80-100), dark red (100-120)
    // final segments = [
    //   _ArcSegment(0, 40, const Color(0xFF2E7D32)),
    //   _ArcSegment(40, 60, const Color(0xFF558B2F)),
    //   _ArcSegment(60, 80, const Color(0xFFE65100)),
    //   _ArcSegment(80, 100, const Color(0xFFBF360C)),
    //   _ArcSegment(100, 120, const Color(0xFFB71C1C)),
    // ];

    final segments = [
      _ArcSegment(0, 10, const Color.fromRGBO(15, 235, 70, 1)),
      _ArcSegment(10, 20, const Color.fromRGBO(55, 205, 62, 1)),
      _ArcSegment(20, 30, const Color.fromRGBO(85, 185, 56, 1)),
      _ArcSegment(30, 40, const Color.fromRGBO(115, 165, 50, 1)),
      _ArcSegment(40, 50, const Color.fromRGBO(155, 155, 44, 1)),
      _ArcSegment(50, 60, const Color.fromRGBO(195, 145, 38, 1)),
      _ArcSegment(60, 70, const Color.fromRGBO(235, 125, 32, 1)),
      _ArcSegment(70, 80, const Color.fromRGBO(205, 105, 26, 1)),
      _ArcSegment(80, 90, const Color.fromRGBO(185, 85, 20, 1)),
      _ArcSegment(90, 100, const Color.fromRGBO(155, 65, 14, 1)),
      _ArcSegment(100, 110, const Color.fromRGBO(125, 40, 8, 1)),
      _ArcSegment(110, 120, const Color.fromRGBO(95, 15, 2, 1)),
    ];

    for (final seg in segments) {
      final segStartAngle = startAngle + (seg.startDb / 120.0) * sweepAngle;
      final segSweepAngle = ((seg.endDb - seg.startDb) / 120.0) * sweepAngle;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        _degToRad(segStartAngle),
        _degToRad(segSweepAngle),
        false,
        paint,
      );
    }
  }

  void _drawTicks(
      Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle) {
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 120; i += 2) {
      final angle = _degToRad(startAngle + (i / 120.0) * sweepAngle);
      final isMajor = i % 10 == 0;
      final innerRadius = radius - (isMajor ? 15 : 8);

      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );

      tickPaint.strokeWidth = isMajor ? 1.5 : 0.8;
      tickPaint.color = isMajor
          ? Colors.white.withOpacity(0.8)
          : Colors.white.withOpacity(0.4);

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle, AppLocalizations l10n) {
    final labels = [
      _Label(10, l10n.levelVerySilent, const Color(0xFF4CAF50)),
      _Label(30, l10n.levelSilent, const Color(0xFF4CAF50)),
      _Label(50, l10n.levelNormal, const Color(0xFFFF9800)),
      _Label(70, l10n.levelNoisy, const Color(0xFFFF9800)),
      _Label(90, l10n.levelVeryNoisy, const Color(0xFFE64A19)),
      _Label(110, l10n.levelExtreme, const Color(0xFFB71C1C)),
    ];

    for (final label in labels) {
      final angle = _degToRad(startAngle + (label.db / 120.0) * sweepAngle);
      final labelRadius = radius - 28;
      final pos = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text.replaceAll('\n', ''),
          style: TextStyle(
            color: label.color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Rotate text
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  void _drawScaleNumbers(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle) {
    // 0
    final angle0 = _degToRad(startAngle);
    final pos0 = Offset(
      center.dx + (radius + 18) * cos(angle0),
      center.dy + (radius + 18) * sin(angle0),
    );
    _drawText(canvas, '0', pos0, Colors.white, 14);

    // 120
    final angle120 = _degToRad(startAngle + sweepAngle);
    final pos120 = Offset(
      center.dx + (radius + 18) * cos(angle120),
      center.dy + (radius + 18) * sin(angle120),
    );
    _drawText(canvas, '120', pos120, Colors.white, 14);
  }

  // void _drawStatsLabels(
  //     Canvas canvas, Offset center, double radius, AppLocalizations l10n) {
  //   // Average on the left
  //   final avgPos = Offset(center.dx - radius * 0.75, center.dy - radius * 0.6);
  //   _drawText(canvas, avgDb.toStringAsFixed(1), avgPos, Colors.white, 22,
  //       fontWeight: FontWeight.bold);
  //   _drawText(canvas, l10n.average,
  //       Offset(avgPos.dx, avgPos.dy + 26), Colors.grey, 13);
  //
  //   // Max on the right
  //   final maxPos = Offset(center.dx + radius * 0.55, center.dy - radius * 0.6);
  //   _drawText(canvas, maxDb.toStringAsFixed(1), maxPos, Colors.white, 22,
  //       fontWeight: FontWeight.bold);
  //   _drawText(canvas, l10n.maximum,
  //       Offset(maxPos.dx, maxPos.dy + 26), Colors.grey, 13);
  // }

  void _drawNeedle(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle) {
    final dbClamped = currentDb.clamp(0.0, 120.0);
    final angle = _degToRad(startAngle + (dbClamped / 120.0) * sweepAngle);

    // Thin needle line
    final needlePaint = Paint()
      ..color = Color(0xFF00BCD4)//Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + (radius - 40) * cos(angle),
      center.dy + (radius - 40) * sin(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    // 绘制中心点
    final centerPaint = Paint()
      ..color = Colors.red.withOpacity(0.85)
      ..strokeWidth = 2;

    canvas.drawCircle(
      center,
      5,
      centerPaint,
    );
  }

  void _drawCenterValue(
      Canvas canvas, Offset center, AppLocalizations l10n) {
    // Main dB value
    _drawText(
      canvas,
      currentDb.toStringAsFixed(1),
      Offset(center.dx, center.dy - 55),
      Colors.white,
      52,
      fontWeight: FontWeight.bold,
    );

    // dB unit
    _drawText(
      canvas,
      l10n.dbUnit,
      Offset(center.dx, center.dy-16),
      Colors.white,
      14,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2),
    );
  }

  double _degToRad(double deg) => deg * pi / 360;

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.currentDb != currentDb ||
        oldDelegate.avgDb != avgDb ||
        oldDelegate.maxDb != maxDb;
  }
}

class _ArcSegment {
  final double startDb;
  final double endDb;
  final Color color;
  _ArcSegment(this.startDb, this.endDb, this.color);
}

class _Label {
  final double db;
  final String text;
  final Color color;
  _Label(this.db, this.text, this.color);
}
