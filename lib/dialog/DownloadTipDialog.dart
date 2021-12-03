import 'package:filemanager/Config.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DownloadTipDialog extends Dialog {
  String tip;

  DownloadTipDialog({Key key, this.tip}) : super(key: key);

  commit(BuildContext context) {
    Navigator.pop(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: 600.w,
            height: 583.w,
            child: Stack(
              children: [
                Container(
                  width: 600.w,
                  height: 506.w,
                  margin: EdgeInsets.only(top: 77.w),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20.w))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CommonUtil.getH_Magin(256.w),
                      ViewUtils.getTextView(
                          tip, 32, ColorConfig.main_txt_color),
                      CommonUtil.getH_Magin(22.w),
                      ViewUtils.getTextView(
                          'Download current file?', 32, ColorConfig.main_txt_color),
                      CommonUtil.getH_Magin(63.w),
                      Container(
                        width: 600.w,
                        height: 2.w,
                        color: ColorConfig.line_color,
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                                width: 298.w,
                                height: 72.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(20.w))),
                                child: ViewUtils.getTextView(
                                  'Cancel',
                                  28,
                                  Color(0xff5183F7),
                                )),
                          ),
                          Container(
                            width: 2.w,
                            height: 68.w,
                            color: ColorConfig.line_color,
                          ),
                          GestureDetector(
                            onTap: () => commit(context),
                            child: Container(
                                width: 298.w,
                                height: 72.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(20.w))),
                                child: ViewUtils.getTextView(
                                  'Download now',
                                  28,
                                  Color(0xff5183F7),
                                )),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'images/icon_clipboard.png',
                    width: 206.w,
                    height: 296.w,
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
