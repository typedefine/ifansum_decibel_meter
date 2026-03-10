
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../tool_utils.dart';

class DecibelStandardScreen extends StatelessWidget {
  const DecibelStandardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.decibelStandard,//'Noise Reference',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.black,
          // decoration: BoxDecoration(
          //     color: ToolUtil.rgbToColor(69, 72, 77),
          //     border: BoxBorder.all(
          //         color: ToolUtil.rgbToColor(43, 44, 48),
          //         width: 15
          //     ),
          //     borderRadius: BorderRadius.circular(30)
          // ),
          child:
          // Column(
          //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.fromLTRB(80, 10, 80, 10),
          //       decoration: BoxDecoration(
          //           color: ToolUtil.rgbToColor(24, 25, 27),
          //           borderRadius: BorderRadius.circular(10)
          //       ),
          //       child: Text(
          //         l10n.decibelStandard,//'Noise Reference',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
              Column(
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 16),
                  _referenceBgRow([
                    _referenceRow('0-20 dB', l10n.noise_20, ToolUtil.rgbToColor(184, 236, 218)),
                    _referenceRow('20-40 dB', l10n.noise_40, ToolUtil.rgbToColor(184, 236, 218)),
                    _referenceRow('40-60 dB', l10n.noise_60, ToolUtil.rgbToColor(184, 236, 218)),
                  ]),
                  const SizedBox(height: 20),
                  _referenceBgRow([
                    _referenceRow('60-70 dB', l10n.noise_70, ToolUtil.rgbToColor(242, 244, 180)),
                    _referenceRow('70-90 dB', l10n.noise_90, ToolUtil.rgbToColor(242, 244, 180))
                  ]),
                  const SizedBox(height: 20),
                  _referenceBgRow([
                    _referenceRow('90-100 dB', l10n.noise_100, ToolUtil.rgbToColor(169, 139, 140)),
                    _referenceRow('100-110 dB', l10n.noise_110, ToolUtil.rgbToColor(169, 139, 140)),
                    _referenceRow('>110 dB', l10n.noise_120, ToolUtil.rgbToColor(169, 139, 140)),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            // ],
          // )
      ),
    );
}

Widget _referenceBgRow(List<Widget> itemList){
  return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: ToolUtil.rgbToColor(44, 50, 57),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: itemList
      )
  );
}

Widget _referenceRow(String level, String description, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            level,
            style: TextStyle(
              color: color,//Color(0xFFFF9800),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: TextStyle(color: color, fontSize: 14),
          ),
        ),
      ],
    )
  );
  }

}