import 'package:flutter/material.dart';
import 'package:ifansum_decibel_meter/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'meter_page.dart';
import 'camera_page.dart';
import 'records_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // int _currentIndex = 0;

  final List<Widget> _pages = const [
    MeterPage(),
    SizedBox(),//CameraPage(),
    RecordsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: settings.curPageIndex,//_currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: settings.curPageIndex,//_currentIndex,
          onTap: (index){
            if(index != 1){
              // setState(() => _currentIndex = index);
              // setState(() {});
              settings.setCurPageIndex(index);
            }else{
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => CameraPage(),
                ),
              );
            }
          }, //=> setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const _MeterIcon(),
              activeIcon: const _MeterIcon(active: true),
              label: l10n.tabMeter,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.camera_alt_outlined),
              activeIcon: const Icon(Icons.camera_alt),
              label: l10n.tabCamera,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              activeIcon: const Icon(Icons.description),
              label: l10n.tabRecords,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.tune_outlined),
              activeIcon: const Icon(Icons.tune),
              label: l10n.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _MeterIcon extends StatelessWidget {
  final bool active;
  const _MeterIcon({this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00BCD4) : Colors.grey;
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MeterIconPainter(color: color),
      ),
    );
  }
}

class _MeterIconPainter extends CustomPainter {
  final Color color;
  _MeterIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Draw sound wave bars
    final barWidth = w / 7;
    final heights = [0.4, 0.7, 1.0, 0.5, 0.8, 0.3, 0.6];
    for (int i = 0; i < 5; i++) {
      final x = w * 0.15 + i * barWidth * 1.2;
      final barH = h * heights[i];
      final y1 = (h - barH) / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + barH), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
