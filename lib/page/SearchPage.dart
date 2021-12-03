import 'dart:io';

import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/DateUtil.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';
import 'AudioDetailPage.dart';
import 'DirectionPage.dart';
import 'FileReaderPage.dart';
import 'ImageDetailPage.dart';
import 'OpenFilePage.dart';
import 'VideoDetailPage.dart';

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SearchPageState();
  }
}

class SearchPageState extends State<SearchPage> {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController searchController = TextEditingController();
  List<File> fileList = List();

  @override
  void initState() {
    super.initState();
  }

  search() {
    if (searchController.text.isEmpty) {
      ToastUtil.showToast('Please enter the search content');
      return;
    }
    fileList.clear();
    String key = searchController.text;
    FileUtil.getResourceLocalPath().then((value) {
      Directory directory = Directory(value);
      directory.list(recursive: true).forEach((element) {
        setState(() {
          List<String> list = element.path.split('/');
          String name = list[list.length - 1];
          if (name.contains(key)) {
            fileList.add(File(element.path));
          }
        });
      });
    });
  }

  clickFileItem(int index) {
    String type = FileUtil.getMediaType(fileList[index].path);
    switch (type) {
      case 'image':
        CommonUtil.push(context, ImageDetailPage(file: fileList[index]));
        break;
      case 'audio':
        CommonUtil.push(context, AudioDetailPage(file: fileList[index]));
        break;
      case 'video':
        CommonUtil.push(context, VideoDetailPage(file: fileList[index]));
        break;
      case 'doc':
        CommonUtil.push(
            context, FileReaderPage(filePath: fileList[index].path));
        break;
      case 'dir':
        CommonUtil.push(context, DirectionPage(path: fileList[index].path));
        break;
      default:
        CommonUtil.push(context, OpenFilePage(file: fileList[index]));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, //修改状态栏文字颜色的
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: buildMainView()),
    );
  }

  buildMainView() {
    return Column(
      children: [CommonUtil.getH_Magin(80.w), getSearchView(), getFileList()],
    );
  }

  getFileList() {
    if (fileList.length == 0) {
      return getNullView();
    }
    return Expanded(
        child: ListView.builder(
      itemCount: fileList.length,
      padding: EdgeInsets.only(top: 0),
      itemBuilder: (context, index) {
        return getFileItem(index, fileList[index]);
      },
    ));
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
      time = DateUtil.myFormatDateTime(file.lastModifiedSync(),
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

  getNullView() {
    return Container(
        width: CommonUtil.getScreenWidth(context),
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(bottom: 30.w),
        child: Column(
          children: [
            CommonUtil.getH_Magin(100.w),
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

  getSearchView() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 64.w,
      margin: EdgeInsets.only(left: 32.w, right: 32.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              'images/icon_back.png',
              width: 54.w,
              height: 54.w,
            ),
          ),
          CommonUtil.getW_Magin(30.w),
          Container(
            width: 480.w,
            height: 64.w,
            padding: EdgeInsets.only(left: 32.w),
            decoration: new BoxDecoration(
                color: Color(0xFFF5F6F9),
                borderRadius: new BorderRadius.circular(32.0)),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Image(
                  image: AssetImage('images/icon_search.png'),
                  width: 30.w,
                  height: 30.w,
                ),
                Container(
                  width: 370.w,
                  height: 64.w,
                  margin: EdgeInsets.only(left: 20.w),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.bottom,
                    cursorWidth: 1.w,
                    cursorColor: Color(0xffCCCCCC),
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                        letterSpacing: 1.w,
                        color: Colors.black,
                        fontSize: ScreenUtil()
                            .setSp(26, allowFontScalingSelf: false)),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.all(0),
                      hintText: 'Please enter the search content',
                      hintStyle: TextStyle(
                          letterSpacing: 1.w,
                          color: Color(0xFFBFBFBF),
                          fontSize: ScreenUtil()
                              .setSp(26, allowFontScalingSelf: false)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CommonUtil.getW_Magin(32.w),
          GestureDetector(
            onTap: () => search(),
            child:
                ViewUtils.getTextView('Search', 28, ColorConfig.main_txt_color),
          ),
        ],
      ),
    );
  }
}
