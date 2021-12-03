import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'AppPage.dart';
import 'tool/SharedUtil.dart';

void main() {
  runApp(MyApp());
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  SharedUtil.getInstance();

  SystemUiOverlayStyle uiStyle = SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.white,
  );

  SystemChrome.setSystemUIOverlayStyle(uiStyle);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File download',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppPage(),
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        print('=== deviceLocale: $deviceLocale');
      },
    );
  }
}
