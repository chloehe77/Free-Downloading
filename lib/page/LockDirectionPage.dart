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

import '../Config.dart';
import 'AudioDetailPage.dart';
import 'DirectionPage.dart';
import 'FileReaderPage.dart';
import 'ImageDetailPage.dart';
import 'MovePage.dart';
import 'OpenFilePage.dart';
import 'VideoDetailPage.dart';

class LockDirectionPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LockDirectionPageState();
  }
}

class LockDirectionPageState extends State<LockDirectionPage>
    with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String rootPath;
  List<File> fileList = List();
  bool isOperationMode = false;
  List<bool> checkList = List();

  @override
  void initState() {
    super.initState();
    FileUtil.getLockPath().then((value) {
      rootPath = value;
      initFileList();
    });
  }

  initFileList() {
    setState(() {
      isOperationMode = false;
    });
    fileList.clear();

    List<String> list =
        SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
    if (list != null && list.length > 0) {
      for (String path in list) {
        fileList.add(File(path));
        checkList.add(false);
      }
    }

    Directory directory = Directory(rootPath);
    directory.list().forEach((element) {
      setState(() {
        fileList.add(File(element.path));
      });
      checkList.add(false);
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
        CommonUtil.push(
                context, ImageDetailPage(file: fileList[index], isLock: true))
            .then((value) {
          if (value != null && value == 1) {
            initFileList();
          }
        });
        break;
      case 'audio':
        CommonUtil.push(
                context, AudioDetailPage(file: fileList[index], isLock: true))
            .then((value) {
          if (value != null && value == 1) {
            initFileList();
          }
        });
        break;
      case 'video':
        CommonUtil.push(
                context, VideoDetailPage(file: fileList[index], isLock: true))
            .then((value) {
          if (value != null && value == 1) {
            initFileList();
          }
        });
        break;
      case 'doc':
        CommonUtil.push(
            context, FileReaderPage(filePath: fileList[index].path));
        break;
      case 'dir':
        CommonUtil.push(context,
                DirectionPage(path: fileList[index].path, isLock: true))
            .then((value) {
          if (value != null && value == 1) {
            initFileList();
          }
        });
        break;
      default:
        CommonUtil.push(context, OpenFilePage(file: fileList[index]));
        break;
    }
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
          EasyLoading.show();
          int outNum = 0;
          for (int i = 0; i < checkList.length; i++) {
            if (checkList[i]) {
              if (FileUtil.isDirection(fileList[i].path)) {
                if (fileList[i].path.contains('/file_manager/m3u8/')) {
                  List<String> list =
                      SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
                  if (list != null && list.length > 0) {
                    list.remove(fileList[i].path);
                    SharedUtil.setStringList(
                        SharedUtil.m3u8_file_list_lock, list);
                    outNum++;
                    if (outNum == checkedNum) {
                      Future.delayed(Duration(seconds: 1)).then((value) {
                        EasyLoading.dismiss();
                        ToastUtil.showToast('Operation complete');
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_FILE_REFRESH);
                        initFileList();
                      });
                    }
                  }
                } else {
                  Directory directory = Directory(fileList[i].path);
                  FileUtil.getResourceLocalPathByType('new').then((value) {
                    String newPath =
                        value + FileUtil.getFileNameFromUrl(fileList[i].path);
                    directory.rename(newPath).then((value) {
                      outNum++;
                      if (outNum == checkedNum) {
                        Future.delayed(Duration(seconds: 1)).then((value) {
                          EasyLoading.dismiss();
                          ToastUtil.showToast('Operation complete');
                          EventBus.getInstance()
                              .send(Config.EVENT_BUS_FILE_REFRESH);
                          initFileList();
                        });
                      }
                    });
                  });
                }
              } else {
                FileUtil.getResourceLocalPathByType(
                        FileUtil.getMediaType(fileList[i].path))
                    .then((value) {
                  String newPath =
                      value + FileUtil.getFileNameFromUrl(fileList[i].path);
                  fileList[i].rename(newPath).then((value) {
                    outNum++;
                    if (outNum == checkedNum) {
                      Future.delayed(Duration(seconds: 1)).then((value) {
                        EasyLoading.dismiss();
                        ToastUtil.showToast('Operation complete');
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_FILE_REFRESH);
                        initFileList();
                      });
                    }
                  });
                });
              }
            }
          }
          break;
        case 12:
          FileUtil.getLockPath().then((value) {
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
                    if (fileList[i].path.contains('/file_manager/m3u8/')) {
                      SharedUtil.saveString(
                          FileUtil.getFileNameFromUrl2(fileList[i].path) +
                              '_rename',
                          value);
                      EasyLoading.dismiss();
                      ToastUtil.showToast('Rename complete');
                      EventBus.getInstance()
                          .send(Config.EVENT_BUS_FILE_REFRESH);
                      initFileList();
                    } else {
                      directory.rename(newPath).then((value) {
                        Future.delayed(Duration(seconds: 2)).then((value) {
                          EasyLoading.dismiss();
                          ToastUtil.showToast('Rename complete');
                          EventBus.getInstance()
                              .send(Config.EVENT_BUS_FILE_REFRESH);
                          initFileList();
                        });
                      });
                    }
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

  showAddFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => TipsInputDialog(title: 'New folder'),
    ).then((value) {
      if (value != null) {
        Directory directory = Directory(rootPath + '/' + value);
        print('=== AddFolder:${directory.path}');
        directory.exists().then((exist) {
          if (exist) {
            ToastUtil.showToast('Folder already exists');
          } else {
            directory.create().then((r) {
              if (r != null) {
                ToastUtil.showToast('Folder created successfully');
                initFileList();
              } else {
                ToastUtil.showToast('Folder created failed');
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: buildView(),
    );
  }

  buildView() {
    if (isOperationMode) {
      return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: FlutterEasyLoading(child: buildMainView()));
    }
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddFolderDialog(),
          child: Icon(Icons.add),
        ),
        body: FlutterEasyLoading(child: buildMainView()));
  }

  buildMainView() {
    return Column(
      children: [
        isOperationMode
            ? ViewUtils.getMenuTopbar(context,
                title: 'Safe Box', listener: this)
            : ViewUtils.buildTopBar(context, 'Safe Box',
                showMenuBtn: true,
                listener: this,
                isOperationMode: isOperationMode),
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: isOperationMode ? 120.w : 0),
                child: getFileList(),
              ),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context, listener: this, isLock: true)
            ],
          ),
        )
      ],
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
      if (file.path.contains('/file_manager/m3u8/')) {
        img = 'images/icon_video.png';
      }
    } else {
      if (file.existsSync()) {
        time = DateUtil.myFormatDateTime(file.lastModifiedSync(),
            format: 'yyyy-MM-dd HH:mm');
      }
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
              if (isOperationMode)
                Image.asset(
                  checkList[i]
                      ? 'images/icon_checked.png'
                      : 'images/icon_nochecked.png',
                  width: 30.w,
                  height: 30.w,
                )
            ],
          ),
        ));
  }
}
