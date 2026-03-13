import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// import '../utils/app_config.dart';

class LocalHtmlViewer extends StatelessWidget {
  final  String title;
  final  String fileName;
  const LocalHtmlViewer({
    super.key,
    required this.title,
    required this.fileName
  });

  @override
  Widget build(BuildContext context) {
    // title = Get.parameters['title'];
    // fileName = Get.parameters['fileName'];
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 232, 232, 232),
      appBar: AppBar(
          title: Text(title),
        // backgroundColor: Color.fromARGB(255, 232, 232, 232),
      ),
      body: WebViewWidget(
        controller: assets(fileName)//assets(fileName!)
      ),
    );
  }

  //加载assets中的HTML
  WebViewController assets(String filePath) {
    String path = 'assets/html/$filePath';//index.html
    return  WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset(path); // 从assets加载 'assets/$fileName'
  }

  Future<WebViewController> documentDirectoryHtml() async{
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/index.html');
    return WebViewController()
        ..loadFile(file.path);
  }


  Future<WebViewController> rootBundleHtml(String filePath) async{
    String path = 'assets/$filePath';//index.html
    final c = await rootBundle.loadString(path);
    return WebViewController()
      ..loadHtmlString(c);
  }


}
/*
// 在原生 App 中调用
webView.loadUrl("feedback.html");

// 如果需要手动触发提交
webView.evaluateJavaScript("window.Compass360xFeedback.submit()");

// 清空表单
webView.evaluateJavaScript("window.Compass360xFeedback.clear()");
 */

/*
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialFile: "assets/index.html", // 直接加载assets文件
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
          ),
        ),
      ),
    );
  }

  InAppWebView(
  initialData: InAppWebViewInitialData(
  data: """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { font-family: Arial; padding: 20px; }
            h1 { color: blue; }
        </style>
    </head>
    <body>
        <h1>本地HTML内容</h1>
        <p>这是直接在代码中定义的HTML</p>
    </body>
    </html>
    """,
  ),
  )

}
*/
