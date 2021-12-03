import 'package:filemanager/tool/CommonUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class FileMenuDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1334), allowFontScaling: false);
    return Material(
      child: Stack(
        children: [
          Positioned(
              bottom: 0,
              child: Container(
                height: 550.w,
                width: 750.w,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ScreenUtil().setHeight(40.w)),
                        topRight:
                            Radius.circular(ScreenUtil().setHeight(40.w)))),
                child: Column(
                  children: [
                    CommonUtil.getH_Magin(76.w),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getMenuItem(
                            context, 0, 'Scan code', 'images/icon_add_scan.png'),
                        getMenuItem(
                            context, 1, 'Input url', 'images/icon_add_url.png'),
                        getMenuItem(
                            context, 2, 'New Folder', 'images/icon_add_folder.png')
                      ],
                    ),
                    CommonUtil.getH_Magin(56.w),
                    buildTip(),
                    CommonUtil.getH_Magin(56.w),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getMenuItem(context, 3, 'Local Photo', 'images/icon_img.png'),
                        getMenuItem(
                            context, 4, 'Local Video', 'images/icon_video.png'),
                        getMenuItem(context, 5, 'Local file', 'images/icon_doc.png')
                      ],
                    ),
                  ],
                ),
              ))
        ],
      ),
      type: MaterialType.transparency,
    );
  }

  getMenuItem(BuildContext context, int index, String txt, String img) {
    return GestureDetector(
        onTap: () => Navigator.pop(context, index),
        child: Container(
          width: 187.5.w,
          alignment: Alignment.center,
          color: Colors.white,
          child: Column(
            children: [
              Image(
                image: AssetImage(img),
                width: 62.w,
                height: 50.w,
              ),
              CommonUtil.getH_Magin(20.w),
              Text(
                txt,
                style: TextStyle(
                    fontSize:
                        ScreenUtil().setSp(28, allowFontScalingSelf: false)),
              )
            ],
          ),
        ));
  }

  Widget _line() {
    return Container(
      height: 1.h,
      width: 160.w,
      decoration: new BoxDecoration(
        color: ColorConfig.common_line,
      ),
    );
  }

  buildTip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(),
        CommonUtil.getH_Magin(20.w),
        Text(
          'Add files',
          style: TextStyle(
              color: Color(0xffDCDCDE),
              fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false)),
        ),
        CommonUtil.getH_Magin(20.w),
        _line()
      ],
    );
  }
}

abstract class OnHeadClick {
  void onHeadClick(int choose);
}
