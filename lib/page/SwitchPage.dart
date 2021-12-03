import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class SwitchPage extends StatefulWidget {
  int type;

  SwitchPage({this.type});

  @override
  State<StatefulWidget> createState() {
    return SwitchPageState();
  }
}

class SwitchPageState extends State<SwitchPage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();

  int type;
  String title;
  String content;
  bool isOpen = true;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    switch (type) {
      case 0:
        title = 'Home page ad.';
        break;
      default:
    }

    if (SharedUtil.getBool(Config.KEY_SWITCH_BANNER) != null) {
      isOpen = SharedUtil.getBool(Config.KEY_SWITCH_BANNER);
    }
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
        ViewUtils.buildTopBar(context, '', showMenuBtn: false),
        Container(
          padding: EdgeInsets.only(top: 36.w, left: 32.w),
          alignment: Alignment.topLeft,
          child: ViewUtils.getTextView(title, 32, ColorConfig.main_txt_color),
        ),
        Container(
          padding: EdgeInsets.only(right: 32.w, left: 32.w, top: 48.w),
          alignment: Alignment.topLeft,
          child: ViewUtils.getTextView(content, 28, Color(0xff757575)),
        ),
        CommonUtil.getH_Magin(38.w),
        ViewUtils.getLine(CommonUtil.getScreenWidth(context), 2.w),
        Container(
          padding: EdgeInsets.only(left: 32.w, top: 38.w, right: 32.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              ViewUtils.getTextView('Whether to enable', 28, ColorConfig.main_txt_color),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isOpen = true;
                        SharedUtil.saveBool(Config.KEY_SWITCH_BANNER, true);
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_CODE_BANNER);
                      });
                    },
                    child: Container(
                      width: 56.w,
                      height: 46.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color:
                              isOpen ? Color(0xff5183F7) : Colors.transparent,
                          borderRadius: BorderRadius.all(Radius.circular(8.w))),
                      child: ViewUtils.getTextView('open ', 24,
                          isOpen ? Colors.white : ColorConfig.main_txt_color),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isOpen = false;
                        SharedUtil.saveBool(Config.KEY_SWITCH_BANNER, false);
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_CODE_BANNER);
                      });
                    },
                    child: Container(
                      width: 56.w,
                      height: 46.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color:
                              isOpen ? Colors.transparent : Color(0xff5183F7),
                          borderRadius: BorderRadius.all(Radius.circular(8.w))),
                      child: ViewUtils.getTextView('close', 24,
                          isOpen ? ColorConfig.main_txt_color : Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
