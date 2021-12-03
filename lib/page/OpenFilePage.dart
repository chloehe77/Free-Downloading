import 'dart:io';

import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class OpenFilePage extends StatefulWidget {
  File file;

  OpenFilePage({this.file});

  @override
  State<StatefulWidget> createState() {
    return OpenFilePageState();
  }
}

class OpenFilePageState extends State<OpenFilePage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String title;

  @override
  void initState() {
    super.initState();
    title = FileUtil.getFileNameFromUrl(widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: buildMainView()),
    );
  }

  buildMainView() {
    return Column(
      children: [
        ViewUtils.buildTopBar(context, title, showMenuBtn: false),
        Expanded(
            child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(top: 82.w),
              child: Image.asset(
                'images/bg_open_file.png',
                width: CommonUtil.getScreenWidth(context),
                height: 665.w,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 560.w),
              alignment: Alignment.topCenter,
              child: ViewUtils.getTextView(
                  'Select how to view the file', 32, Color(0xffB0B3BE)),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: CommonUtil.getScreenWidth(context),
                padding: EdgeInsets.only(top: 24.w),
                height: 140.w,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xff87ABFE), Color(0xff5385F7)])),
                child: Row(
                  children: [
                    CommonUtil.getW_Magin(158.w),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            Image.asset(
                              'images/icon_open_type.png',
                              width: 36.w,
                            ),
                            SizedBox(height: 12.w),
                            ViewUtils.getTextView(
                                'Open mode', 20, Colors.white),
                          ],
                        ),
                      ),
                    ),
                    CommonUtil.getW_Magin(294.w),
                    GestureDetector(
                      onTap: () {
                        ToastUtil.showToast('not support');
                      },
                      child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Image.asset(
                                'images/icon_open_share.png',
                                width: 36.w,
                              ),
                              SizedBox(height: 12.w),
                              ViewUtils.getTextView('Share', 20, Colors.white),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            )
          ],
        ))
      ],
    );
  }
}
