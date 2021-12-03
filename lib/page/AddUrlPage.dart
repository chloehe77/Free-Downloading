import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class AddUrlPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AddUrlPageState();
  }
}

class AddUrlPageState extends State<AddUrlPage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController controller = TextEditingController();

  submit() {
    if (controller.text == '') {
      ToastUtil.showToast('Please enter the download address');
      return;
    }
    if (!controller.text.contains('http')) {
      ToastUtil.showToast(
          'The download address is incorrect. Please re-enter it');
      return;
    }
    Navigator.pop(context, controller.text);
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
        ViewUtils.buildTopBar(context, 'Add link', showMenuBtn: false),
        Container(
          width: CommonUtil.getScreenWidth(context),
          color: Color(0xFFFFF9C4),
          padding: EdgeInsets.all(15),
          child: ViewUtils.getTextView(
              'Please abide by the laws and regulations of your country',
              28,
              Colors.black),
        ),
        Container(
          width: CommonUtil.getScreenWidth(context),
          height: 400.h,
          color: Color(0xFFE0E0E0),
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.only(left: 15, right: 15, top: 10),
          child: TextField(
              controller: controller,
              maxLines: 99,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                contentPadding: EdgeInsets.only(bottom: 10.w),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                border: InputBorder.none,
                hintText:
                    'Please enter the download address, which supports links such as HTTP, HTTPS, FTP, m3u8, etc。',
                hintStyle: TextStyle(
                    letterSpacing: 1.w,
                    color: Color(0xFFBFBFBF),
                    fontSize:
                        ScreenUtil().setSp(32, allowFontScalingSelf: false)),
              )),
        ),
        GestureDetector(
            onTap: () => submit(),
            child: Container(
              width: CommonUtil.getScreenWidth(context),
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.all(15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: ViewUtils.getTextView('Download', 36, Colors.white),
            )),
      ],
    );
  }
}
