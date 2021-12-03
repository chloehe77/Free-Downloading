import 'dart:async';
import 'package:filemanager/dialog/ShareDialog.dart';
import 'package:filemanager/dialog/TipsInputDialog.dart';
import 'package:filemanager/page/LockDirectionPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'FileUtil.dart';
import 'SharedUtil.dart';
import 'ToastUtil.dart';

enum PlayType {
  network,
  asset,
  file,
  fileId,
}

class CommonUtil {

  static Function debounce(
    Function func, [
    Duration delay = const Duration(milliseconds: 1000),
  ]) {
    Timer timer;
    Function target = () {
      if (timer?.isActive ?? false) {
        timer?.cancel();
      }
      timer = Timer(delay, () {
        func?.call();
      });
    };
    return target;
  }


  static Function throttle(
    Future Function() func,
  ) {
    if (func == null) {
      return func;
    }
    bool enable = true;
    Function target = () {
      if (enable == true) {
        enable = false;
        func().then((_) {
          enable = true;
        });
      }
    };
    return target;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static Widget getW_Magin(double w) {
    return Container(
      width: w,
      height: 1,
    );
  }

  static Widget getH_Magin(double h) {
    return Container(
      width: 1,
      height: h,
    );
  }

  static bool isMobile(String mobile) {
    if (mobile == null || mobile.length != 11) {
      return false;
    }
    RegExp exp = RegExp(
        r'^((13[0-9])|(14[0-9])|(15[0-9])|(16[0-9])|(17[0-9])|(18[0-9])|(19[0-9]))\d{8}$');
    return exp.hasMatch(mobile);
  }

  static Future push(BuildContext context, Widget page) {
    return Navigator.push(context, CupertinoPageRoute(builder: (context) {
      return page;
    }));
  }

  // md5 encryption
  static String generate_MD5(String data) {
    var content = new Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes).toLowerCase();
  }

  static shareToWechat(BuildContext context, String path) {
    if ('image' != FileUtil.getMediaType(path)) {
      ToastUtil.showToast('not support');
      return;
    }

  }

  static showDialogIntoLockPage(BuildContext context, String safe_password) {
    showDialog(
      context: context,
      builder: (context) => TipsInputDialog(title: 'please enter password', isPw: true),
    ).then((value) {
      if (value != null) {
        if (value == SharedUtil.getString(SharedUtil.safe_password)) {
          CommonUtil.push(context, LockDirectionPage());
        } else {
          ToastUtil.showToast('incorrect password');
        }
      }
    });
  }
}
