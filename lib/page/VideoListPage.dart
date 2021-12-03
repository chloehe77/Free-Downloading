import 'dart:io';

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
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../Config.dart';
import 'MovePage.dart';
import 'VideoDetailPage.dart';

class VideoListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return VideoListPageState();
  }
}

class VideoListPageState extends State<VideoListPage> with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<File> fileList = List();
  List<Map> tempList = new List();
  List<VideoPlayerController> controllerList = List();
  List<Future> futureList = List();
  bool isOperationMode = false;
  List<bool> checkList = List();

  @override
  void initState() {
    super.initState();
    initFileList();
  }

  intoLock(List<File> checkFiles) {
    String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
    if (token == null || token == '' || token == 'null') {
      ViewUtils.showLoginTip(context);
      return;
    }
    for (int i = 0; i < checkFiles.length; i++) {
      if (checkFiles[i].path.contains('/file_manager/m3u8/') &&
          checkFiles.length > 1) {
        ToastUtil.showToast('not support');
        return;
      }
    }
    showDialog(
      context: context,
      builder: (context) =>
          TipsInputDialog(title: 'Please enter the safe password', isPw: true),
    ).then((value) {
      if (value != null) {
        if (value == SharedUtil.getString(SharedUtil.safe_password)) {
          if (checkFiles.length == 1 &&
              checkFiles[0].path.contains('/file_manager/m3u8/')) {

            List<String> list =
                SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
            if (list == null) {
              list = List();
            }
            list.add(checkFiles[0].path);
            SharedUtil.setStringList(SharedUtil.m3u8_file_list_lock, list);
            doRefresh();
          } else {
            moveToLock(checkFiles);
          }
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
              doRefresh();
            }
          }).catchError((e) {
            print("rename:$e");
            EasyLoading.dismiss();
          });
        }
      });
    }
  }

  doRefresh() {
    Future.delayed(Duration(seconds: 2)).then((value) {
      EasyLoading.dismiss();
      ToastUtil.showToast('Operation complete');
      EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
      //initFileList();
      Navigator.pop(context);
    });
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
                    doRefresh();
                  }
                });
              } else {
                fileList[i].delete().then((value) {
                  deleteNum++;
                  if (deleteNum == checkedNum) {
                    doRefresh();
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
          for (int i = 0; i < checkList.length; i++) {
            if (checkList[i]) {
              if (fileList[i].path.contains('/file_manager/m3u8/')) {
                ToastUtil.showToast('not support');
                return;
              }
            }
          }
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
                  if (fileList[i].path.contains('/file_manager/m3u8/')) {
                    SharedUtil.saveString(
                        FileUtil.getFileNameFromUrl2(fileList[i].path) +
                            '_rename',
                        value);
                    doRefresh();
                  } else {
                    String fileNm =
                        FileUtil.getFileNameFromUrl(fileList[i].path);
                    List<String> strs = fileNm.split('.');
                    String newPath =
                        fileList[i].path.replaceAll(strs[0], value);
                    print('=== newPath:$newPath');
                    fileList[i].rename(newPath).then((value) {
                      doRefresh();
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
  void dispose() {
    try {
      controllerList.forEach((element) {
        element.dispose();
      });
    } catch (e) {
      print('e1:$e');
    }
    super.dispose();
  }

  initFileList() {
    isOperationMode = false;
    tempList.clear();
    checkList.clear();
    try {
      controllerList.forEach((element) {
        element.dispose();
      });
    } catch (e) {
      print('e2:$e');
    }
    controllerList.clear();
    futureList.clear();
    FileUtil.getResourceLocalPath().then((value) {
      Directory directory = Directory(value);
      directory.list(recursive: true).forEach((element) {
        if (element.statSync().type != FileSystemEntityType.DIRECTORY &&
            'video' == FileUtil.getMediaType(element.path) &&
            !element.path.endsWith('.ts') &&
            !element.path.endsWith('.db') &&
            !element.path.endsWith('.key') &&
            !element.path.endsWith('.m3u8')) {
          setState(() {
            File file = File(element.path);
            print('=== file:${file.path}');
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
        } else if (element.path.endsWith('file_manager/m3u8')) {
          Directory newDir = Directory(element.path);
          newDir.list().forEach((e) {
            List<String> list =
                SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
            if (list == null) {
              list = List();
            }
            if (FileUtil.isDirection(e.path) && !list.contains(e.path)) {
              Directory dirItem = Directory(e.path);

              File file = File(e.path);
              Map map = Map();
              map['file'] = file;
              map['time'] = dirItem.statSync().changed;
              tempList.add(map);
              tempList.sort((a, b) => (b['time']).compareTo(a['time']));
              fileList.clear();
              checkList.clear();
              tempList.forEach((element) {
                fileList.add(element['file']);
                checkList.add(false);
              });
            }
          });
        }
      });
    });
    Future.delayed(Duration(milliseconds: 500)).then((value) {
      setState(() {
        fileList.forEach((element) {
          VideoPlayerController controller =
              VideoPlayerController.file(element);
          controllerList.add(controller);
          futureList.add(controller.initialize());
        });
      });
    });
  }

  goVideoDetail(File file, int index) {
    if (isOperationMode) {
      setState(() {
        checkList[index] = !checkList[index];
      });
      return;
    }
    CommonUtil.push(context, VideoDetailPage(file: file)).then((value) {
      if (value != null && value == 1) {
        EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, //修改状态栏文字颜色的
      child: FlutterEasyLoading(
          child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: buildMainView(),
      )),
    );
  }

  buildMainView() {
    return Column(
      children: [
        isOperationMode
            ? ViewUtils.getMenuTopbar(context,
                listener: this, title: 'My Video')
            : ViewUtils.buildTopBar(context, 'My Video',
                showMenuBtn: true,
                listener: this,
                isOperationMode: isOperationMode),
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
    if (fileList.length == 0 || controllerList.length == 0) {
      return ViewUtils.getNullView(context);
    }
    List<Widget> views = List();
    for (int i = 0; i < fileList.length; i++) {
      views.add(getVideoItem(i, fileList[i]));
    }
    return GridView.count(
      crossAxisSpacing: 18.w,

      mainAxisSpacing: 18.w,

      padding: EdgeInsets.all(20.0.w),

      crossAxisCount: 2,

      childAspectRatio: 1.2,
      children: views,
    );
  }

  getVideoItem(int index, File file) {
    bool isDirection = FileUtil.isDirection(file.path);
    DateTime dateTime;
    double size = 0;
    if (isDirection) {
      Directory directory = Directory(file.path);
      dateTime = directory.statSync().changed;
      List<FileSystemEntity> fileList = directory.listSync(recursive: true);
      for (FileSystemEntity entity in fileList) {
        if (!FileUtil.isDirection(entity.path)) {
          size = size + File(entity.path).lengthSync();
        }
      }
    } else {
      dateTime = file.lastModifiedSync();
      size = file.lengthSync().toDouble();
    }
    return GestureDetector(
        onTap: () => goVideoDetail(file, index),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 190.w,
                  child: FutureBuilder(

                    future: futureList[index],
                    builder: (context, snapshot) {
                      print(snapshot.connectionState);
                      if (snapshot.hasError) print(snapshot.error);
                      if (snapshot.connectionState == ConnectionState.done) {
                        return AspectRatio(
                          aspectRatio: 1.73,
                          child: VideoPlayer(controllerList[index]),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
                CommonUtil.getW_Magin(12.w),
                Text(
                  FileUtil.getFileNameFromUrl(file.path),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: ColorConfig.main_txt_color,
                      fontSize:
                          ScreenUtil().setSp(28, allowFontScalingSelf: false)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ViewUtils.getTextView(
                        DateUtil.myFormatDateTime(dateTime,
                            format: 'yyyy-MM-dd HH:mm'),
                        24,
                        Color(0xffB0B3BE)),
                    ViewUtils.getTextView(
                        FileUtil.renderSize(size), 24, Color(0xffB0B3BE))
                  ],
                )
              ],
            ),
            if (isOperationMode)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.all(10.w),
                  child: Image.asset(
                    checkList[index]
                        ? 'images/icon_checked.png'
                        : 'images/icon_nochecked.png',
                    width: 30.w,
                    height: 30.w,
                  ),
                ),
              )
          ],
        ));
  }
}
