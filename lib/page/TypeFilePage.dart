import 'dart:io';

import 'package:filemanager/dialog/FileMenuDialog.dart';
import 'package:filemanager/dialog/InputDialog.dart';
import 'package:filemanager/dialog/TipsInputDialog.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/DateUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';
import 'AudioDetailPage.dart';
import 'FileReaderPage.dart';
import 'ImageDetailPage.dart';
import 'MovePage.dart';
import 'OpenFilePage.dart';
import 'VideoDetailPage.dart';

class TypeFilePage extends StatefulWidget {
  String type;

  TypeFilePage({this.type});

  @override
  State<StatefulWidget> createState() {
    return TypeFilePageState();
  }
}

class TypeFilePageState extends State<TypeFilePage> with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String title = '';
  String type = '';

  List<File> fileList = List();
  List<Map> tempList = new List();
  bool isOperationMode = false;
  List<bool> checkList = List();

  @override
  void initState() {
    super.initState();
    type = widget.type;
    switch (widget.type) {
      case 'audio':
        title = 'My Music';
        break;
      case 'apk':
        title = 'My Application';
        break;
      case 'doc':
        title = 'My Document';
        break;
      case 'other':
        title = 'Other';
        break;
      case 'book':
        title = 'E-book';
        break;
      default:
    }
    initFileList();
  }

  initFileList() {
    setState(() {
      isOperationMode = false;
      fileList.clear();
    });
    tempList.clear();
    FileUtil.getResourceLocalPath().then((value) {
      Directory directory = Directory(value);
      directory.list(recursive: true).forEach((element) {
        if (element.statSync().type != FileSystemEntityType.DIRECTORY &&
            type == FileUtil.getMediaType(element.path)) {
          setState(() {
            File file = File(element.path);
            fileList.add(file);
            Map map = Map();
            map['file'] = file;
            map['time'] = file.lastModifiedSync();
            tempList.add(map);
            tempList.sort((a, b) => (b['time']).compareTo(a['time']));
            fileList.clear();
            checkList.clear();
            tempList.forEach((element) {
              fileList.add(element['file']);
              checkList.add(false);
            });
          });
        }
      });
    });
  }

  clickFileItem(int index) {
    if (isOperationMode) {
      setState(() {
        checkList[index] = !checkList[index];
      });
      return;
    }
    String type = FileUtil.getMediaType(fileList[index].path);
    switch (type) {
      case 'image':
        CommonUtil.push(context, ImageDetailPage(file: fileList[index]));
        break;
      case 'audio':
        CommonUtil.push(
                context,
                AudioDetailPage(
                    file: fileList[index], index: index, fileList: fileList))
            .then((value) {
          if (value != null && value == 1) {
            initFileList();
          }
        });
        break;
      case 'video':
        CommonUtil.push(context, VideoDetailPage(file: fileList[index]));
        break;
      case 'doc':
        CommonUtil.push(
            context, FileReaderPage(filePath: fileList[index].path));
        break;
      default:
        CommonUtil.push(context, OpenFilePage(file: fileList[index]));
        break;
    }
  }

  intoLock(List<File> checkFiles) {
    String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
    if (token == null || token == '' || token == 'null') {
      ViewUtils.showLoginTip(context);
      return;
    }
    String safe_password_key =
        SharedUtil.getString(SharedUtil.safe_password_key);
    showDialog(
      context: context,
      builder: (context) =>
          TipsInputDialog(title: 'Please enter the safe password', isPw: true),
    ).then((value) {
      if (value != null) {
        if (value == SharedUtil.getString(SharedUtil.safe_password)) {
          moveToLock(checkFiles);
        } else {
          ToastUtil.showToast('Password error');
        }
      }
    });
  }

  moveToLock(List<File> checkFiles) {
    if (checkFiles != null && checkFiles.length > 0) {
      EasyLoading.show();
      int num = 0;
      FileUtil.getLockPath().then((rootPath) {
        for (int i = 0; i < checkFiles.length; i++) {
          File element = checkFiles[i];
          if (FileUtil.isDirection(element.path)) {
            Directory directory = Directory(element.path);
            String newPath =
                rootPath + FileUtil.getFileNameFromUrl(element.path);
            directory.rename(newPath).then((value) {
              num++;
              if (num == checkFiles.length) {
                Future.delayed(Duration(seconds: 3)).then((value) {
                  EasyLoading.dismiss();
                  ToastUtil.showToast('Successfully moved to safe');
                  EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                });
              }
            }).catchError((e) {
              print("rename:$e");
              EasyLoading.dismiss();
            });
          } else {
            String newPath =
                rootPath + FileUtil.getFileNameFromUrl(element.path);
            print("newPath:$newPath");
            element.rename(newPath).then((value) {
              num++;
              if (num == checkFiles.length) {
                Future.delayed(Duration(seconds: 3)).then((value) {
                  EasyLoading.dismiss();
                  ToastUtil.showToast('Successfully moved to safe');
                  EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  initFileList();
                });
              }
            }).catchError((e) {
              print("rename:$e");
              EasyLoading.dismiss();
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void clickMenu(int type) {
    if (type == 0) {
      for (int i = 0; i < checkList.length; i++) {
        checkList[i] = false;
      }
      setState(() {
        isOperationMode = true;
      });
    } else if (type == 1) {
      setState(() {
        isOperationMode = false;
      });
    } else if (type == 2) {
      for (int i = 0; i < checkList.length; i++) {
        checkList[i] = true;
      }
      setState(() {});
    } else {
      int checkedNum = 0;
      List<File> checkFiles = List();
      for (int i = 0; i < checkList.length; i++) {
        if (checkList[i]) {
          checkedNum++;
          checkFiles.add(fileList[i]);
        }
      }
      if (checkedNum == 0) {
        ToastUtil.showToast('Please select the file to operate');
        return;
      }
      switch (type) {
        case 10:
          EasyLoading.show();
          int deleteNum = 0;
          for (int i = 0; i < checkList.length; i++) {
            if (checkList[i]) {
              if (FileUtil.isDirection(fileList[i].path)) {
                Directory directory = Directory(fileList[i].path);
                directory.delete(recursive: true).then((value) {
                  deleteNum++;
                  if (deleteNum == checkedNum) {
                    EasyLoading.dismiss();
                    ToastUtil.showToast('Delete complete');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                    initFileList();
                  }
                });
              } else {
                fileList[i].delete().then((value) {
                  deleteNum++;
                  if (deleteNum == checkedNum) {
                    EasyLoading.dismiss();
                    ToastUtil.showToast('Delete complete');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                    initFileList();
                  }
                });
              }
            }
          }
          break;
        case 11:
          intoLock(checkFiles);
          break;
        case 12:
          FileUtil.getResourceLocalPathByType('new').then((value) {
            CommonUtil.push(
                context,
                MovePage(
                  rootPath: value,
                  moveFileList: checkFiles,
                )).then((value) {
              if (value != null && value == 1) {
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                initFileList();
              }
            });
          });
          break;
        case 13:
          if (checkedNum > 1) {
            ToastUtil.showToast('Please select a file to share');
            return;
          }
          CommonUtil.shareToWechat(context, checkFiles[0].path);
          break;
        case 14:
          if (checkedNum > 1) {
            ToastUtil.showToast('Please select a file to rename');
            return;
          }
          showDialog(
            context: context,
            builder: (context) =>
                TipsInputDialog(title: 'Please enter a file name'),
          ).then((value) {
            if (value != null) {
              EasyLoading.show();
              for (int i = 0; i < checkList.length; i++) {
                if (checkList[i]) {
                  String fileNm = FileUtil.getFileNameFromUrl(fileList[i].path);
                  List<String> strs = fileNm.split('.');
                  String newPath = fileList[i].path.replaceAll(strs[0], value);
                  print('=== newPath:$newPath');
                  if (FileUtil.isDirection(fileList[i].path)) {
                    Directory directory = Directory(fileList[i].path);
                    directory.rename(newPath).then((value) {
                      Future.delayed(Duration(seconds: 2)).then((value) {
                        EasyLoading.dismiss();
                        ToastUtil.showToast('Rename complete');
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_FILE_REFRESH);
                        initFileList();
                      });
                    });
                  } else {
                    fileList[i].rename(newPath).then((value) {
                      Future.delayed(Duration(seconds: 2)).then((value) {
                        EasyLoading.dismiss();
                        ToastUtil.showToast('Rename complete');
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_FILE_REFRESH);
                        initFileList();
                      });
                    });
                  }
                }
              }
            }
          });
          break;
        default:
      }
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
          body: Column(
            children: [
              isOperationMode
                  ? ViewUtils.getMenuTopbar(context,
                      listener: this, title: title)
                  : ViewUtils.buildTopBar(context, title,
                      showMenuBtn: true,
                      listener: this,
                      isOperationMode: isOperationMode),
              ViewUtils.getLine(CommonUtil.getScreenWidth(context), 2.w),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.only(bottom: isOperationMode ? 120.w : 0),
                      child: getFileList(),
                    ),
                    if (isOperationMode)
                      ViewUtils.buildBottomBar(context, listener: this)
                  ],
                ),
              )
            ],
          )),
    );
  }

  getFileList() {
    if (fileList.length == 0) {
      return ViewUtils.getNullView(context);
    }
    return ListView.builder(
      itemCount: fileList.length,
      padding: EdgeInsets.only(top: 0),
      itemBuilder: (context, index) {
        return getFileItem(index, fileList[index]);
      },
    );
  }

  getFileItem(int index, File file) {
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
      case 'book':
        img = 'images/icon_book.png';
        break;
      default:
    }
    return GestureDetector(
      onTap: () => clickFileItem(index),
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
                  Text(
                      DateUtil.myFormatDateTime(file.lastModifiedSync(),
                          format: 'yyyy-MM-dd HH:mm'),
                      style: TextStyle(
                          color: Color(0xffB0B3BE),
                          fontSize: ScreenUtil()
                              .setSp(24, allowFontScalingSelf: false))),
                ],
              ),
              if (isOperationMode)
                Image.asset(
                  checkList[index]
                      ? 'images/icon_checked.png'
                      : 'images/icon_nochecked.png',
                  width: 30.w,
                  height: 30.w,
                )
            ],
          )),
    );
  }
}
