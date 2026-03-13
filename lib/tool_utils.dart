import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class ToolUtil{

  static Color rgbToColor(int r, int g, int b) {
    // // 确保数值在 0-255 范围内
    // r = r.clamp(0, 255);
    // g = g.clamp(0, 255);
    // b = b.clamp(0, 255);
    //
    // // 转换为十六进制字符串
    // String hex = 'FF${r.toRadixString(16).padLeft(2, '0')}'
    //     '${g.toRadixString(16).padLeft(2, '0')}'
    //     '${b.toRadixString(16).padLeft(2, '0')}';
    //
    // return Color(int.parse(hex, radix: 16));
    return Color(int.parse(rgbColorToHexStringValue(r, g, b)));
  }

  static String rgbColorToHexStringValue(int r, int g, int b) {
    // 确保数值在 0-255 范围内
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    // 转换为十六进制字符串
    String hex = 'FF${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';

    return '0x${hex.toUpperCase()}';
  }

  static String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '${difference.inHours}小时前';
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void print(Object msg){
    if(!kDebugMode){
      print(msg);
    }
  }

  static bool isNotEmpty(dynamic obj){

    if (obj == null) return false;

    if(obj is String) return obj.isNotEmpty;

    if(obj is List) return obj.isNotEmpty;

    if(obj is Map) return obj.isNotEmpty;

    if(obj is Set) return obj.isNotEmpty;

    return false;
  }

}