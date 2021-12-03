import 'dart:io';

import 'package:filemanager/AppPage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/DateUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';

class MovePage extends StatefulWidget {
  String rootPath;
  List<File> moveFileList;

  MovePage({this.rootPath, this.moveFileList});

  @override
  State<StatefulWidget> createState() {
    return MovePageState();
  }
}

class MovePageState extends State<MovePage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<File> fileList = List();
  String title;

  clickFileItem(int index) {
    CommonUtil.push(
        context,
        MovePage(
          rootPath: fileList[index].path,
          moveFileList: widget.moveFileList,
        )).then((value) {
      if (value != null && value == 1) {
        Navigator.pop(context, 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initFileList();
    print('=== rootPath:${widget.rootPath}');
    String path = widget.rootPath;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    title = FileUtil.getFileNameFromUrl(path);
    if (title == 'news' || title == 'news/') {
      title = 'My folder';
    }
    if (title == 'lock') {
      title = 'Safe Box';
    }
  }

  initFileList() {
    Directory directory = Directory(widget.rootPath);
    directory.list(recursive: false).forEach((element) {
      if (element.statSync().type == FileSystemEntityType.DIRECTORY) {
        fileList.add(File(element.path));
      }
    });
    Future.delayed(Duration(seconds: 1)).then((value) {
      setState(() {});
    });
  }

  move() {
    EasyLoading.show();
    int num = 0;
    widget.moveFileList.forEach((element) {
      String newPath =
          widget.rootPath + '/' + FileUtil.getFileNameFromUrl(element.path);
      print("newPath:$newPath");
      if (newPath.contains(element.path)) {
        EasyLoading.dismiss();
        ToastUtil.showToast('not support');
        throw new Error();
      }
      element.rename(newPath).then((value) {
        num++;
        if (num == widget.moveFileList.length) {
          EasyLoading.dismiss();
          ToastUtil.showToast('Move complete');
          Navigator.pop(context, 1);
        }
      }).catchError((e) {
        EasyLoading.dismiss();

      });
    });
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
          body: FlutterEasyLoading(child: buildMainView())),
    );
  }

  buildMainView() {
    return Stack(
      children: [
        ViewUtils.buildTopBar(context, title == null ? 'My folder' : title,
            showMenuBtn: false),
        Container(
          width: CommonUtil.getScreenWidth(context),
          margin: EdgeInsets.only(top: 160.w),
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 120.w),
                  child: Column(
                    children: buildListView(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => move(),
              child: Container(
                width: CommonUtil.getScreenWidth(context),
                height: 100.w,
                color: Colors.blue,
                alignment: Alignment.center,
                child: ViewUtils.getTextView('Sure', 28, Colors.white),
              ),
            ))
      ],
    );
  }

  buildListView() {
    List<Widget> list = List();
    list.add(buildTipView());
    if (fileList.length == 0) {
      list.add(ViewUtils.getNullView(context));
    } else {
      for (int i = 0; i < fileList.length; i++) {
        list.add(getFileItem(i, fileList[i]));
      }
    }
    return list;
  }

  getFileItem(int i, File file) {
    String name = FileUtil.getFileNameFromUrl(file.path);
    String img = 'images/icon_other.png';
    switch (FileUtil.getMediaType(file.path)) {
      case 'image':
        img = 'images/icon_img.png';
        break;
      case 'apk':
        img = 'images/icon_app.png';
        break;
      case 'doc':
        img = 'images/icon_doc.png';
        break;
      case 'audio':
        img = 'images/icon_music.png';
        break;
      case 'video':
        img = 'images/icon_video.png';
        break;
      default:
    }
    String time = '';
    if (FileUtil.isDirection(file.path)) {
      Directory directory = Directory(file.path);
      time = DateUtil.myFormatDateTime(directory.statSync().changed,
          format: 'yyyy-MM-dd HH:mm');
      img = 'images/icon_myfile_dirs.png';
    } else {
      time = DateUtil.myFormatDateTime(file?.lastModifiedSync(),
          format: 'yyyy-MM-dd HH:mm');
    }
    return GestureDetector(
        onTap: () => clickFileItem(i),
        child: Container(
          width: CommonUtil.getScreenWidth(context),
          padding:
              EdgeInsets.only(top: 26.w, bottom: 26.w, left: 44.w, right: 32.w),
          child: Row(
            children: [
              Image(
                image: AssetImage(img),
                width: 38.w,
                height: 34.w,
              ),
              CommonUtil.getW_Magin(44.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 550.w,
                    alignment: Alignment.centerLeft,
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            color: ColorConfig.main_txt_color,
                            fontSize: ScreenUtil()
                                .setSp(28, allowFontScalingSelf: false))),
                  ),
                  Text(time,
                      style: TextStyle(
                          color: Color(0xffB0B3BE),
                          fontSize: ScreenUtil()
                              .setSp(24, allowFontScalingSelf: false))),
                ],
              ),
            ],
          ),
        ));
  }

  buildTipView() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 80.w,
      color: Color(0x80F1EEEE),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 15.w),
      child: ViewUtils.getTextView('Please select a folder（Selected：${title}）',
          28, ColorConfig.sub_txt_color),
    );
  }
}
