import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class AboutPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AboutPageState();
  }
}

class AboutPageState extends State<AboutPage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();

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
        ViewUtils.buildTopBar(context, '', showMenuBtn: false),
        Expanded(
          child: Center(
            child: Text(
              'Version：V1.0.0',
              style: TextStyle(
                  color: ColorConfig.main_txt_color,
                  fontSize:
                      ScreenUtil().setSp(36, allowFontScalingSelf: false)),
            ),
          ),
        )
      ],
    );
  }
}
