import 'package:filemanager/Config.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef ShareClick(int choose);

class ShareDialog {
  static void showShare(BuildContext context, ShareClick onShareClick) {
    showDialog(
        context: context,
        builder: (context) => _ShareDialog(onShareClick: onShareClick));
  }
}

class _ShareDialog extends StatefulWidget {
  final ShareClick onShareClick;
  // _ShareDialog();
  _ShareDialog({
    Key key,
    this.onShareClick,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => ShareDialogState();
}

class ShareDialogState extends State<_ShareDialog> {
  bool loadFinish = false;
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1334), allowFontScaling: false);
    return Material(
      child: Column(
        children: [
          Expanded(
              child: loadFinish
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ViewUtils.loading(),
                        SizedBox(height: 10.h),
                        Center(
                          child: Text("Please wait...",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 30.sp)),
                        ),
                      ],
                    )
                  : SizedBox()),
          Container(
            color: Colors.white,
            height: 350.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              // loadFinish = true;//取消loading
                            });
                            ToastUtil.showToast('Please wait');
                            //widget.onShareClick(Config.WECHAT);
                          },
                          child: Image.asset(
                            'images/person_wechat.png',
                            width: 100.h,
                            height: 100.h,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text("Share to friends",
                            style: TextStyle(
                                color: ColorConfig.text_dark_gray,
                                fontSize: 30.sp))
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              // loadFinish = true;//取消loading
                            });
                            ToastUtil.showToast('Please wait');
                            //widget.onShareClick(Config.WECHAT_PYQ);
                          },
                          child: Image.asset(
                            'images/person_friend.png',
                            width: 100.h,
                            height: 100.h,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text("Share to friends via WeChat ",
                            style: TextStyle(
                                color: ColorConfig.text_dark_gray,
                                fontSize: 30.sp))
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel",
                      style: TextStyle(
                          color: ColorConfig.tab_color_normal,
                          fontSize: 36.sp)),
                )
              ],
            ),
          ),
        ],
      ),
      type: MaterialType.transparency,
    );
  }
}
