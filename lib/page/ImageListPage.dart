import 'dart:io';

import 'package:filemanager/dialog/InputDialog.dart';
import 'package:filemanager/dialog/TipsInputDialog.dart';
import 'package:filemanager/page/ImageDetailPage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';
import 'MovePage.dart';

class ImageListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ImageListPageState();
  }
}

class ImageListPageState extends State<ImageListPage> with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<File> fileList = List();
  List<Map> tempList = new List();
  bool isOperationMode = false;
  List<bool> checkList = List();

  @override
  void initState() {
    super.initState();
    initFileList();
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
          String newPath = rootPath + FileUtil.getFileNameFromUrl(element.path);
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
      });
    }
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
            'image' == FileUtil.getMediaType(element.path)) {
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

  goImageDetail(File file, int index) {
    if (isOperationMode) {
      setState(() {
        checkList[index] = !checkList[index];
      });
      return;
    }
    CommonUtil.push(context, ImageDetailPage(file: file)).then((value) {
      if (value != null && value == 1) {
        initFileList();
      }
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
        body: FlutterEasyLoading(child: buildMainView()),
      ),
    );
  }

  buildMainView() {
    return Column(
      children: [
        isOperationMode
            ? ViewUtils.getMenuTopbar(context,
                listener: this, title: 'My Image')
            : ViewUtils.buildTopBar(context, 'My Image',
                showMenuBtn: true,
                listener: this,
                isOperationMode: isOperationMode),
        ViewUtils.getLine(CommonUtil.getScreenWidth(context), 2.w),
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: isOperationMode ? 120.w : 0),
                child: getFileGrid(),
              ),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context, listener: this)
            ],
          ),
        )
      ],
    );
  }

  getFileGrid() {
    if (fileList.length == 0) {
      return ViewUtils.getNullView(context);
    }
    List<Widget> views = List();
    for (int i = 0; i < fileList.length; i++) {
      views.add(getImageItem(fileList[i], i));
    }

    return GridView.count(

      crossAxisSpacing: 5.w,

      mainAxisSpacing: 5.w,

      padding: EdgeInsets.all(10.0.w),

      crossAxisCount: 4,

      childAspectRatio: 1.0,
      children: views,
    );
  }

  getImageItem(File file, int index) {
    return GestureDetector(
      onTap: () => goImageDetail(file, index),
      child: Container(
        width: 184.w,
        height: 184.w,
        //color: Colors.blue,
        child: Stack(
          children: [
            Image.file(
              file,
              width: 164.w,
              height: 164.w,
              fit: BoxFit.fitWidth,
            ),
            if (isOperationMode)
              Align(
                  alignment: Alignment.topRight,
                  child: Image.asset(
                    checkList[index]
                        ? 'images/icon_checked.png'
                        : 'images/icon_nochecked.png',
                    width: 30.w,
                    height: 30.w,
                  ))
          ],
        ),
      ),
    );
  }
}
