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
import 'FileReaderPage.dart';
import 'ImageDetailPage.dart';
import 'MovePage.dart';
import 'OpenFilePage.dart';
import 'VideoDetailPage.dart';

class DirectionPage extends StatefulWidget {
  String path;
  bool isLock;

  DirectionPage({this.path, this.isLock = false});

  @override
  State<StatefulWidget> createState() {
    return DirectionPageState();
  }
}

class DirectionPageState extends State<DirectionPage> with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String rootPath;
  List<File> fileList = List();
  bool isOperationMode = false;
  List<bool> checkList = List();

  @override
  void initState() {
    super.initState();
    rootPath = widget.path;
    print('=== rootPath:$rootPath');
    initFileList();
  }

  initFileList() {
    isOperationMode = false;
    fileList.clear();
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
            context,
            ImageDetailPage(
              file: fileList[index],
              isLock: widget.isLock,
            )).then((value) {
          if (value != null && value == 1) {
            Navigator.pop(context, 1);
          }
        });
        break;
      case 'audio':
        CommonUtil.push(
            context,
            AudioDetailPage(
              file: fileList[index],
              isLock: widget.isLock,
            )).then((value) {
          if (value != null && value == 1) {
            Navigator.pop(context, 1);
          }
        });
        break;
      case 'video':
        CommonUtil.push(
            context,
            VideoDetailPage(
              file: fileList[index],
              isLock: widget.isLock,
            )).then((value) {
          if (value != null && value == 1) {
            Navigator.pop(context, 1);
          }
        });
        break;
      case 'doc':
        CommonUtil.push(
            context, FileReaderPage(filePath: fileList[index].path));
        break;
      case 'dir':
        CommonUtil.push(
                context,
                DirectionPage(
                    path: fileList[index].path, isLock: widget.isLock))
            .then((value) {
          if (value != null && value == 1) {
            Navigator.pop(context, 1);
          }
        });
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
          if (widget.isLock) {
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
          } else {
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
          }

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
        child: buildView());
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
            ? ViewUtils.getMenuTopbar(context, listener: this)
            : ViewUtils.buildTopBar(
                context, FileUtil.getFileNameFromUrl(rootPath),
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
                ViewUtils.buildBottomBar(context, listener: this)
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
          color: Colors.transparent,
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
