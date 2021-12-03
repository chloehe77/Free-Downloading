import 'package:filemanager/page/login/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../Config.dart';
import 'CommonUtil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ViewUtils {
  static Widget buildTopBar(BuildContext context, String title,
      {bool showMenuBtn = false,
      ClickMenuListener listener,
      bool isOperationMode = false}) {
    return Container(
        width: CommonUtil.getScreenWidth(context),
        height: 160.w,
        color: Colors.white,
        padding: EdgeInsets.only(top: 80.w, left: 32.w, right: 32.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'images/icon_back.png',
                    width: 54.w,
                    height: 54.w,
                  ),
                ),
                Container(
                  width: 500.w,
                  alignment: Alignment.center,
                  child: Text(
                    title == null ? ' ' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: ColorConfig.main_txt_color,
                        fontSize: ScreenUtil()
                            .setSp(36, allowFontScalingSelf: false)),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (listener != null) {
                      listener.clickMenu(0);
                    }
                  },
                  child: Image.asset(
                    'images/icon_menu.png',
                    width: showMenuBtn ? 54.w : 0,
                    height: 54.w,
                  ),
                ),
              ],
            ),
            CommonUtil.getH_Magin(24.w),
            getLine(CommonUtil.getScreenWidth(context), 2.w)
          ],
        ));
  }

  static getMenuTopbar(BuildContext context,
      {ClickMenuListener listener, String title}) {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 160.w,
      padding: EdgeInsets.only(bottom: 28.w),
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              CommonUtil.getW_Magin(36.w),
              GestureDetector(
                onTap: () {
                  if (listener != null) {
                    listener.clickMenu(1);
                  }
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: Color(0xff5183F7),
                      fontSize:
                          ScreenUtil().setSp(28, allowFontScalingSelf: false)),
                ),
              ),
              CommonUtil.getW_Magin(180.w),
              Text(
                title == null ? 'File Management' : title,
                style: TextStyle(
                    color: ColorConfig.main_txt_color,
                    fontSize:
                        ScreenUtil().setSp(36, allowFontScalingSelf: false)),
              ),
              CommonUtil.getW_Magin(140.w),
              GestureDetector(
                onTap: () {
                  if (listener != null) {
                    listener.clickMenu(2);
                  }
                },
                child: Text(
                  'Select all',
                  style: TextStyle(
                      color: Color(0xff5183F7),
                      fontSize:
                          ScreenUtil().setSp(28, allowFontScalingSelf: false)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  static Widget getLine(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: ColorConfig.line_color,
    );
  }

  static Widget getTextView(String txt, int fontSize, Color color) {
    return Text(
      txt,
      style: TextStyle(
          color: color,
          fontSize: ScreenUtil().setSp(fontSize, allowFontScalingSelf: false)),
    );
  }

  static Widget getNullView(BuildContext context, {double hMargin}) {
    return Container(
        width: CommonUtil.getScreenWidth(context),
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(bottom: 30.w),
        child: Column(
          children: [
            CommonUtil.getH_Magin(hMargin == null ? 100.w : hMargin),
            Image(
              image: AssetImage('images/bg_null.png'),
              width: 400.w,
              height: 320.w,
            ),
            Text(
              'There is currently no relevant history',
              style: TextStyle(
                  color: Color(0xffB0B3BE),
                  fontSize:
                      ScreenUtil().setSp(32, allowFontScalingSelf: false)),
            ),
            Text(
              'You haven not operated on any files recently',
              style: TextStyle(
                  color: Color(0xffD7D7DC),
                  fontSize:
                      ScreenUtil().setSp(28, allowFontScalingSelf: false)),
            )
          ],
        ));
  }

  static buildBottomBar(BuildContext context,
      {ClickMenuListener listener, bool isLock = false}) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        width: CommonUtil.getScreenWidth(context),
        height: 120.w,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Color(0xff87ABFE),
          Color(0xff5385F7),
        ])),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            getBottomBarItem(10, 'images/icon_bottombar_delete.png', 'Delete',
                listener: listener),
            getBottomBarItem(11, 'images/icon_bottombar_lock.png',
                isLock ? 'Out safe box' : 'into safe box',
                listener: listener),
            getBottomBarItem(12, 'images/icon_bottombar_move.png', 'Move',
                listener: listener),
            getBottomBarItem(13, 'images/icon_bottombar_share.png', 'Share',
                listener: listener),
            getBottomBarItem(14, 'images/icon_bottombar_rename.png', 'Rename',
                listener: listener),
          ],
        ),
      ),
    );
  }

  static getBottomBarItem(int index, String img, String txt,
      {ClickMenuListener listener}) {
    return GestureDetector(
      onTap: () => listener.clickMenu(index),
      child: Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CommonUtil.getH_Magin(24.w),
              Image.asset(
                img,
                width: 36.w,
                height: 36.w,
              ),
              CommonUtil.getH_Magin(12.w),
              ViewUtils.getTextView(txt, 20, Colors.white)
            ],
          )),
    );
  }

  static Widget loading() {
    return Container(
        alignment: Alignment.center,
        child: SizedBox(
          child: CircularProgressIndicator(),
          width: 50.h,
          height: 50.h,
        ));
  }

  static showLoginTip(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text('Tip'),
            content: Text(
                'Hello, if you need to login to continue, do you want to login？'),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    CommonUtil.push(context, LoginPage());
                  },
                  child: Text('Sure')),
            ],
          );
        });
  }
}

abstract class ClickMenuListener {
  void clickMenu(int type);
}
