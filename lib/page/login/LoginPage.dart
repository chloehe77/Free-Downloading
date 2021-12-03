import 'dart:async';

import 'package:filemanager/AppPage.dart';
import 'package:filemanager/Config.dart';
import 'package:filemanager/EnvironmentConfig.dart';
import 'package:filemanager/page/WebPage.dart';
import 'package:filemanager/page/login/RegisterPage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController phoneControl = TextEditingController();
  TextEditingController codeControl = TextEditingController();
  bool isChecked = false;

  login() {
    if (phoneControl.text.isEmpty) {
      ToastUtil.showToast('Please enter the account');
      return;
    }

    if (codeControl.text.isEmpty) {
      ToastUtil.showToast('Please enter the password');
      return;
    }
    if (!isChecked) {
      ToastUtil.showToast('Please read and agree《Privacy Policy》');
      return;
    }
    List<String> users = SharedUtil.getStringList('users');
    if (users == null) {
      users = List();
    }
    if (!users.contains(phoneControl.text)) {
      ToastUtil.showToast('The account does not exist');
      return;
    }
    String pw =
        SharedUtil.getString('${Config.KEY_USER_PW}_${phoneControl.text}');
    if (pw == codeControl.text) {
      ToastUtil.showToast('Login success');
      SharedUtil.saveString(SharedUtil.SP_LOGIN_TOKEN, phoneControl.text);
      SharedUtil.saveString(
          SharedUtil.safe_password, EnvironmentConfig.safe_password);
      Navigator.pushAndRemoveUntil(context,
          new MaterialPageRoute(builder: (BuildContext c) {
        return new AppPage();
      }), (r) => false);
    } else {
      ToastUtil.showToast('Password error');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  goRegisterPage() {
    CommonUtil.push(context, RegisterPage()).then((value) {
      if (value != null && value == 1) {
        Navigator.pushAndRemoveUntil(context,
            new MaterialPageRoute(builder: (BuildContext c) {
          return new AppPage();
        }), (r) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, //修改状态栏文字颜色的
        child: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.white,
              body: FlutterEasyLoading(
                  child: Container(
                color: Colors.white,
                child: buildMainView(),
              ))),
        ));
  }

  buildMainView() {
    return Column(
      children: [
        ViewUtils.buildTopBar(context, '', showMenuBtn: false),
        CommonUtil.getH_Magin(50.w),
        Image.asset(
          'images/ic_launcher_round.png',
          width: 152.w,
          height: 152.w,
        ),
        CommonUtil.getH_Magin(30.w),
        ViewUtils.getTextView('', 32, ColorConfig.main_txt_color),
        CommonUtil.getH_Magin(8.w),
        ViewUtils.getTextView('slogan', 28, Color(0xffB0B3BE)),
        Stack(
          children: [
            Container(
              width: CommonUtil.getScreenWidth(context),
              margin: EdgeInsets.only(
                top: 150.w,
                left: 60.w,
                right: 60.w,
              ),
              alignment: Alignment.center,
              child: TextField(
                  controller: phoneControl,
                  maxLines: 1,
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                      fontSize:
                          ScreenUtil().setSp(32, allowFontScalingSelf: false)),
                  decoration: InputDecoration(
                    hintText: 'Please enter the account',
                    counter: Text(''),
                    labelStyle: TextStyle(color: ColorConfig.line_color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorConfig.line_color),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorConfig.line_color),
                    ),
                    //border: OutlineInputBorder(borderSide: BorderSide.none),
                  )),
            ),
          ],
        ),
        buildCodeInput(),
        Container(
          width: CommonUtil.getScreenWidth(context),
          height: 2.w,
          color: ColorConfig.line_color,
          margin: EdgeInsets.only(left: 60.w, right: 60.w),
        ),
        CommonUtil.getH_Magin(68.w),
        GestureDetector(
          onTap: () => login(),
          child: Container(
            width: CommonUtil.getScreenWidth(context),
            height: 92.w,
            margin: EdgeInsets.only(left: 60.w, right: 60.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Color(0xff5183F7),
                borderRadius: BorderRadius.all(Radius.circular(10.w))),
            child: ViewUtils.getTextView('Login', 32, Colors.white),
          ),
        ),
        CommonUtil.getH_Magin(32.w),
        GestureDetector(
          onTap: () => goRegisterPage(),
          child: ViewUtils.getTextView(
              'No account? Register now', 24, Color(0xff5183F7)),
        ),
        CommonUtil.getH_Magin(200.w),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
                onTap: () {
                  setState(() {
                    isChecked = !isChecked;
                  });
                },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Image.asset(
                    isChecked
                        ? 'images/icon_checked.png'
                        : 'images/icon_nochecked.png',
                    width: 26.w,
                    height: 26.w,
                  ),
                )),
            ViewUtils.getTextView(
                'I have read and agree', 24, Color(0xffB6B6BC)),
            GestureDetector(
                onTap: () {
                  CommonUtil.push(context, WebPage());
                },
                child: ViewUtils.getTextView(
                    '《Privacy Policy》', 24, Color(0xff5183F7))),
          ],
        )
      ],
    );
  }

  buildCodeInput() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 80.w,
      margin: EdgeInsets.only(left: 60.w, right: 60.w),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 80.w,
            padding: EdgeInsets.only(bottom: 15.w),
            child: TextField(
                controller: codeControl,
                maxLines: 1,
                maxLength: 6,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                    fontSize:
                        ScreenUtil().setSp(32, allowFontScalingSelf: false)),
                decoration: InputDecoration(
                  hintText: 'Please enter the password',
                  counter: Text(''),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                )),
          ),
        ],
      ),
    );
  }
}
