import 'package:filemanager/Config.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class TipsInputDialog extends Dialog {
  final String title;
  final bool isPw;
  TextEditingController inputControl = TextEditingController();

  TipsInputDialog({Key key, this.title, this.isPw = false}) : super(key: key);

  commit(BuildContext context) {
    if (inputControl.text.isEmpty) {
      ToastUtil.showToast('Please enter content');
      return;
    }
    Navigator.pop(context, inputControl.text);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1334), allowFontScaling: false);
    return Material(
      child: Center(
        child: Container(
          width: 494.w,
          height: 299.w,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20.w))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CommonUtil.getH_Magin(36.w),
              ViewUtils.getTextView(title == null ? 'New folder' : title, 32,
                  ColorConfig.main_txt_color),
              CommonUtil.getH_Magin(48.w),
              Container(
                width: 440.w,
                height: 65.w,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Color(0xffF7F7F7),
                ),
                child: Row(
                  children: [
                    CommonUtil.getW_Magin(20.w),
                    Container(
                      width: 350.w,
                      padding: EdgeInsets.only(bottom: 5.w),
                      child: TextField(
                          controller: inputControl,
                          obscureText: isPw,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: ScreenUtil()
                                  .setSp(32, allowFontScalingSelf: false)),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            contentPadding: EdgeInsets.only(bottom: 10.w),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            border: InputBorder.none,
                          )),
                    ),
                    CommonUtil.getW_Magin(30.w),
                    GestureDetector(
                      onTap: () => inputControl.clear(),
                      child: Image.asset(
                        'images/icon_et_clear.png',
                        width: 32.w,
                      ),
                    )
                  ],
                ),
              ),
              CommonUtil.getH_Magin(30.w),
              Container(
                width: 494.w,
                height: 2.w,
                color: ColorConfig.line_color,
              ),
              Row(
                children: [
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 246.w,
                        height: 72.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10.w)),
                        ),
                        child:
                            ViewUtils.getTextView('Cancel', 28, Color(0xff5183F7)),
                      )),
                  Container(
                    width: 2.w,
                    height: 72.w,
                    color: ColorConfig.line_color,
                  ),
                  GestureDetector(
                    onTap: () => commit(context),
                    child: Container(
                      width: 246.w,
                      height: 72.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10.w)),
                      ),
                      child: ViewUtils.getTextView('Confirm', 28, Color(0xff5183F7)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
      type: MaterialType.transparency,
    );
  }
}
