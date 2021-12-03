import 'dart:io';

import 'package:filemanager/dialog/TipsInputDialog.dart';
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
import 'package:photo_view/photo_view.dart';

import '../Config.dart';
import 'MovePage.dart';
import 'login/LoginPage.dart';

class ImageDetailPage extends StatefulWidget {
  File file;
  bool isLock;

  ImageDetailPage({this.file, this.isLock = false});

  @override
  State<StatefulWidget> createState() {
    return ImageDetailPageState();
  }
}

class ImageDetailPageState extends State<ImageDetailPage>
    with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String fileName;
  bool isOperationMode = false;
  File imgFile;

  @override
  void initState() {
    super.initState();
    imgFile = widget.file;
    fileName = FileUtil.getFileNameFromUrl(imgFile.path);
  }

  showLoginTip() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text('Tip'),
            content: Text(
                'Hello, if you need to login to continue, do you want to login？'),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    CommonUtil.push(context, LoginPage());
                  },
                  child: Text('Sure')),
            ],
          );
        });
  }

  intoLock() {
    String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
    if (token == null || token == '' || token == 'null') {
      showLoginTip();
      return;
    }
    showDialog(
      context: context,
      builder: (context) =>
          TipsInputDialog(title: 'Please enter the safe password', isPw: true),
    ).then((value) {
      if (value != null) {
        print('value:$value');
        print('value2:${SharedUtil.getString(SharedUtil.safe_password)}');
        if (value == SharedUtil.getString(SharedUtil.safe_password)) {
          moveToLock();
        } else {
          ToastUtil.showToast('Password error');
        }
      }
    });
  }

  moveToLock() {
    EasyLoading.show();
    FileUtil.getLockPath().then((rootPath) {
      String newPath = rootPath + FileUtil.getFileNameFromUrl(imgFile.path);
      print("newPath:$newPath");
      imgFile.rename(newPath).then((value) {
        Future.delayed(Duration(seconds: 1)).then((value) {
          EasyLoading.dismiss();
          ToastUtil.showToast('Successfully moved to safe');
          Navigator.pop(context, 1);
        });
      }).catchError((e) {
        print("rename:$e");
        EasyLoading.dismiss();
      });
    });
  }

  outLock() {
    FileUtil.getResourceLocalPathByType(FileUtil.getMediaType(imgFile.path))
        .then((value) {
      String newPath = value + FileUtil.getFileNameFromUrl(imgFile.path);
      imgFile.rename(newPath).then((value) {
        Future.delayed(Duration(seconds: 1)).then((value) {
          EasyLoading.dismiss();
          ToastUtil.showToast('Operation complete');
          Navigator.pop(context, 1);
        });
      });
    });
  }

  @override
  void clickMenu(int type) {
    if (type == 0) {

      setState(() {
        isOperationMode = !isOperationMode;
      });
    } else {
      switch (type) {
        case 10:
          EasyLoading.show();
          imgFile.delete().then((value) {
            EasyLoading.dismiss();
            ToastUtil.showToast('Delete complete');
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
            Navigator.pop(context, 1);
          });
          break;
        case 11:
          if (widget.isLock) {
            outLock();
          } else {
            intoLock();
          }
          break;
        case 12:
          List<File> moveFileList = List();
          moveFileList.add(imgFile);
          FileUtil.getResourceLocalPathByType('new').then((value) {
            CommonUtil.push(
                context,
                MovePage(
                  rootPath: value,
                  moveFileList: moveFileList,
                )).then((value) {
              if (value != null && value == 1) {
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                Navigator.pop(context, 1);
              }
            });
          });
          break;
        case 13:
          CommonUtil.shareToWechat(context, imgFile.path);
          break;
        case 14:
          showDialog(
            context: context,
            builder: (context) =>
                TipsInputDialog(title: 'Please enter a file name'),
          ).then((value) {
            if (value != null) {
              EasyLoading.show();
              List<String> strs = fileName.split('.');
              String newPath = imgFile.path.replaceAll(strs[0], value);
              imgFile.rename(newPath).then((value) {
                EasyLoading.dismiss();
                ToastUtil.showToast('Rename complete');
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                Navigator.pop(context, 1);
              });
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
          body: FlutterEasyLoading(child: buildMainView())),
    );
  }

  buildMainView() {
    return Column(
      children: [
        ViewUtils.buildTopBar(context, fileName,
            showMenuBtn: true, listener: this),
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(
                    //bottom: isOperationMode ? 150.w : 0,
                    top: isOperationMode ? 20.w : 0),
                child: Center(
                  child: PhotoView(
                    imageProvider: FileImage(widget.file),
                  ),
                ),
              ),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context,
                    listener: this, isLock: widget.isLock)
            ],
          ),
        )
      ],
    );
  }
}
