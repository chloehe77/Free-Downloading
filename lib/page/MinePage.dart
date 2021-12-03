import 'dart:io';

import 'package:filemanager/Config.dart';
import 'package:filemanager/page/AboutPage.dart';
import 'package:filemanager/page/HomePage.dart';
import 'package:filemanager/page/SwitchPage.dart';
import 'package:filemanager/page/login/LoginPage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MinePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MinePageState();
  }
}

class MinePageState extends State<MinePage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isLogin = false;
  int imgNum = 0;
  int videoNum = 0;
  int audioNum = 0;
  String dirSize = '0';

  @override
  void initState() {
    super.initState();
    SharedUtil.getInstance().then((value) {
      setState(() {
        isLogin = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN) != null;
      });
    });
    EventBus.getInstance().on(Config.EVENT_BUS_FILE_REFRESH, (arg) {
      getFileNum();
    });
    getFileNum();
  }

  @override
  void dispose() {
    EventBus.getInstance().off(Config.EVENT_BUS_FILE_REFRESH);
    super.dispose();
  }

  getFileNum() {
    imgNum = 0;
    videoNum = 0;
    audioNum = 0;
    FileUtil.getResourceLocalPath().then((value) {
      Directory directory = Directory(value);
      FileUtil.getTotalSizeOfFilesInDir(directory).then((value) {
        setState(() {
          dirSize = FileUtil.renderSize(value);
        });
      });
      directory.list(recursive: true).forEach((element) {
        setState(() {
          if (FileUtil.getMediaType(element.path) == 'image') {
            imgNum++;
          } else if (FileUtil.getMediaType(element.path) == 'video') {
            if (!element.path.endsWith('.ts') &&
                !element.path.endsWith('.db') &&
                !element.path.endsWith('.key') &&
                !element.path.endsWith('.m3u8')) {
              videoNum++;
            }
          } else if (FileUtil.getMediaType(element.path) == 'audio') {
            audioNum++;
          }
        });
      });
    });
  }

  clickItem(int index) {
    switch (index) {
      case 0:
        CommonUtil.push(context, AboutPage());
        break;
      case 1:
        CommonUtil.push(context, SwitchPage(type: 0));
        break;
      case 2:
        showLogoutDialog();
        break;
      default:
    }
  }

  showLogoutDialog() {
    if (SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN) == null) {
      ToastUtil.showToast('You have not login yet');
      return;
    }
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text('Tip'),
            content: Text('Are you sure you want to logout'),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              FlatButton(onPressed: () => doLogout(), child: Text('Sure')),
            ],
          );
        });
  }

  doLogout() {
    setState(() {
      SharedUtil.saveString(SharedUtil.SP_LOGIN_TOKEN, null);
      isLogin = false;
    });
    Navigator.pop(context);
  }

  goLogin() {
    CommonUtil.push(context, LoginPage());
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
    String name = SharedUtil.getString(
        '${Config.KEY_NICK_NAME}_${SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN)}');
    return Column(children: [
      CommonUtil.getH_Magin(120.w),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CommonUtil.getW_Magin(32.w),
              GestureDetector(
                onTap: () {
                  if (!isLogin) {
                    goLogin();
                  }
                },
                child: Image.asset(
                  'images/default_head.png',
                  width: 116.w,
                  height: 116.w,
                ),
              ),
              CommonUtil.getW_Magin(24.w),
              !isLogin
                  ? GestureDetector(
                      onTap: () => goLogin(),
                      child: Text(
                        'Please login',
                        style: TextStyle(
                            color: ColorConfig.main_txt_color,
                            fontSize: ScreenUtil()
                                .setSp(32, allowFontScalingSelf: false)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ViewUtils.getTextView(
                            name ?? ' ', 32, ColorConfig.main_txt_color),
                        ViewUtils.getTextView(
                            SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN),
                            24,
                            Color(0xffB0B3BE)),
                      ],
                    )
            ],
          ),
          Row(
            children: [
              Image.asset(
                'images/icon_right_btn.png',
                width: 54.w,
                height: 54.w,
              ),
              CommonUtil.getW_Magin(36.w)
            ],
          ),
        ],
      ),
      CommonUtil.getH_Magin(50.w),
      Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildDataView(imgNum, 'Image'),
          buildDataView(videoNum, 'Video'),
          buildDataView(audioNum, 'Music'),
          buildDataView(dirSize, 'Storage'),
        ],
      ),
      CommonUtil.getH_Magin(36.w),
      ViewUtils.getLine(CommonUtil.getScreenWidth(context), 20.w),
      buildItem(0, 'images/icon_mine_about.png', 'About APP'),
      getLine(),
      //buildItem(1, 'images/icon_mine_noad.png'),
      //getLine(),
      buildItem(2, 'images/icon_mine_bxg.png', 'Logout App'),
      getLine(),
    ]);
  }

  buildDataView(var num, String txt) {
    return Column(
      children: [
        Text(
          '$num',
          style: TextStyle(
              color: ColorConfig.main_txt_color,
              fontSize: ScreenUtil().setSp(28, allowFontScalingSelf: false)),
        ),
        Text(
          txt,
          style: TextStyle(
              color: Color(0xffB0B3BE),
              fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false)),
        )
      ],
    );
  }

  buildItem(int index, String img, String txt) {
    return GestureDetector(
        onTap: () => clickItem(index),
        child: Container(
          width: CommonUtil.getScreenWidth(context),
          height: 112.w,
          color: Colors.white,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              CommonUtil.getW_Magin(37.w),
              Image.asset(
                img,
                width: 24.w,
                height: 18.w,
              ),
              CommonUtil.getW_Magin(30.w),
              Text(
                txt,
                style: TextStyle(
                    color: ColorConfig.main_txt_color,
                    fontSize:
                        ScreenUtil().setSp(28, allowFontScalingSelf: false)),
              ),
              CommonUtil.getW_Magin(456.w),
              Image.asset(
                'images/icon_right_go.png',
                width: 15.w,
                height: 25.w,
              ),
            ],
          ),
        ));
  }

  getLine() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 2.w,
      margin: EdgeInsets.only(left: 34.w, right: 34.w),
      color: ColorConfig.line_color,
    );
  }
}
