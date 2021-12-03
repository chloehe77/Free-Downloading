import 'package:filemanager/Config.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InputDialog extends StatefulWidget {
  String title;
  bool isPw;
  InputDialog({this.title, this.isPw = false});

  @override
  State<StatefulWidget> createState() {
    return InputDialogState();
  }
}

class InputDialogState extends State<InputDialog> {
  TextEditingController inputControl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  commit() {
    if (inputControl.text.isEmpty) {
      ToastUtil.showToast('Please enter the download address');
      return;
    }
    Navigator.pop(context, inputControl.text);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1334), allowFontScaling: false);
    return Material(
        child: Container(
      width: CommonUtil.getScreenWidth(context),
      height: CommonUtil.getScreenHeight(context),
      color: Color(0xA0000000),
      child: Center(
        child: Container(
          width: 494.w,
          height: 296.w,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20.w))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CommonUtil.getH_Magin(36.w),
              ViewUtils.getTextView(
                  widget.title, 32, ColorConfig.main_txt_color),
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
                          obscureText: widget.isPw,
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
                            ViewUtils.getTextView('cancel', 28, Color(0xff5183F7)),
                      )),
                  Container(
                    width: 2.w,
                    height: 72.w,
                    color: ColorConfig.line_color,
                  ),
                  GestureDetector(
                    onTap: () => commit(),
                    child: Container(
                      width: 246.w,
                      height: 72.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10.w)),
                      ),
                      child: ViewUtils.getTextView('confirm', 28, Color(0xff5183F7)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    ));
  }
}
