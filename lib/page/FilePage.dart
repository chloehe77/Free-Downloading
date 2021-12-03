import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filemanager/EnvironmentConfig.dart';
import 'package:filemanager/dialog/DownloadTipDialog.dart';
import 'package:filemanager/dialog/FileMenuDialog.dart';
import 'package:filemanager/dialog/TipsInputDialog.dart';
import 'package:filemanager/page/MovePage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/DateUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Config.dart';
import 'AddUrlPage.dart';
import 'AudioDetailPage.dart';
import 'DirectionPage.dart';
import 'FileReaderPage.dart';
import 'ImageDetailPage.dart';
import 'ImageListPage.dart';
import 'OpenFilePage.dart';
import 'TypeFilePage.dart';
import 'VideoDetailPage.dart';
import 'VideoListPage.dart';

class FilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FilePageState();
  }
}

class FilePageState extends State<FilePage> with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool openSortMenu = false;

  List<File> fileList = List();
  List<Map> tempList = new List();
  List<bool> checkList = List();
  bool isDownloading = false;
  double progress = 0;
  String downloadFile = '';
  bool isOperationMode = false;
  CancelToken cancelToken;
  String currentSavePath = '';
  String resourcesId = '';
  String currentUrl = '';

  @override
  void initState() {
    super.initState();
    initFileList();
    EventBus.getInstance().on(Config.EVENT_BUS_FILE_REFRESH, (arg) {
      print('=== file EVENT_BUS_FILE_REFRESH');
      initFileList();
    });
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
        if (element.statSync().type != FileSystemEntityType.DIRECTORY) {
          if (!element.path.endsWith('.ts') &&
              !element.path.contains('file_manager/m3u8')) {
            setState(() {
              File file = File(element.path);
              Map map = Map();
              map['file'] = file;
              map['time'] = file.lastModifiedSync();
              tempList.add(map);
              tempList.sort((a, b) => (b['time']).compareTo(a['time']));
              fileList.clear();
              tempList.forEach((element) {
                fileList.add(element['file']);
              });
            });
          }
        } else {
          //手动创建的文件夹
          if (element.path.endsWith('file_manager/news') ||
              element.path.endsWith('file_manager/m3u8')) {
            setState(() {
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
                  tempList.forEach((element) {
                    fileList.add(element['file']);
                  });
                }
              });
            });
          }
        }
      });
    });
    Future.delayed(Duration(seconds: 2)).then((value) {
      if (mounted) {
        setState(() {
          isOperationMode = false;
        });
      }
    });
  }

  showAddMenu() {
    showDialog(
      context: context,
      builder: (context) => FileMenuDialog(),
    ).then((value) {
      if (value != null) {
        doAddMenu(value);
      }
    });
  }

  showInputUrlDialog() {
    if (isDownloading) {
      ToastUtil.showToast('Downloading, please wait');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => TipsInputDialog(title: 'Enter download address'),
    ).then((value) {
      if (value != null) {
        if (value.toString().contains('http')) {
          download(value, '');
        } else {
          ToastUtil.showToast('Download address format error');
        }
      }
    });
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
        //ToastUtil.showToast('一次只能移动一个m3u8视频哦');
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
            ToastUtil.showToast('Successfully moved to Safe Box');
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
          } else {
            moveToLock(checkFiles);
          }
        } else {
          ToastUtil.showToast('Password error');
        }
      }
    });
  }

  openLock() {
    String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
    if (token == null || token == '' || token == 'null') {
      ViewUtils.showLoginTip(context);
      return;
    }
    String safe_password_key =
        SharedUtil.getString(SharedUtil.safe_password_key);
    CommonUtil.showDialogIntoLockPage(context, safe_password_key);
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
                  ToastUtil.showToast('Successfully moved to Safe Box');
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
                  ToastUtil.showToast('Successfully moved to Safe Box');
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

  showAddFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => TipsInputDialog(),
    ).then((value) {
      if (value != null) {
        EasyLoading.show();
        FileUtil.getResourceLocalPathByType('new').then((path) {
          Directory directory = Directory(path + value);
          directory.exists().then((exist) {
            if (exist) {
              EasyLoading.dismiss();
              ToastUtil.showToast('Folder creation success');
            } else {
              directory.create().then((r) {
                if (r != null) {
                  Future.delayed(Duration(seconds: 2)).then((value) {
                    EasyLoading.dismiss();
                    ToastUtil.showToast('Folder creation success');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  });
                } else {
                  EasyLoading.dismiss();
                  ToastUtil.showToast('Folder creation failed');
                }
              }).catchError((e) {
                print(e);
                EasyLoading.dismiss();
                ToastUtil.showToast('Folder creation failed');
              });
            }
          });
        });
      }
    });
  }

  addLocalFile(FileType fileType) {
    ToastUtil.showToast('Long press to select more');
    FilePicker.platform
        .pickFiles(type: fileType, allowMultiple: true)
        .then((value) {
      if (value != null && value?.files?.length > 0) {
        EasyLoading.show();
        for (int i = 0; i < value.files.length; i++) {
          File file = File(value.files[i].path);
          String type = FileUtil.getMediaType(file.path);
          FileUtil.getResourceLocalPathByType(type).then((path) {
            String newPath = path + FileUtil.getFileNameFromUrl(file.path);
            print('=== newPath:${newPath}');
            file.copy(newPath);
            if (i == value.files.length - 1) {
              Future.delayed(Duration(seconds: 2)).then((value) {
                EasyLoading.dismiss();
                ToastUtil.showToast('File added successfully');
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
              });
            }
          });
        }
      }
    });
  }

  doAddMenu(int p) {
    switch (p) {
      case 0:
        scan();
        break;
      case 1:
        CommonUtil.push(context, AddUrlPage()).then((value) {
          if (value != null) {
            download(value, '');
          }
        });
        break;
      case 2:
        showAddFolderDialog();
        break;
      case 3:
        addLocalFile(FileType.image);
        break;
      case 4:
        addLocalFile(FileType.video);
        break;
      case 5:
        addLocalFile(FileType.any);
        break;
      default:
    }
  }

  Future scan() async {
    // try {
    //   ScanResult scanResult = await BarcodeScanner.scan();
    //   print('扫码结果:' + scanResult.rawContent);
    //   viewdownload(scanResult?.rawContent?.trim());
    // } catch (e) {
    //   print('扫码错误: $e');
    // }
  }

  viewdownload(String content) {
    if (content != null && content != '') {
      showDialog(
        context: context,
        builder: (context) {
          return DownloadTipDialog(
            tip: 'Code scanning Download',
          );
        },
      ).then((value) {
        if (value == 1) {
          String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
          if (token == null || token == '' || token == 'null') {
            ViewUtils.showLoginTip(context);
          } else {
            if (content.contains('http')) {
              download(content, '');
            } else {
              ToastUtil.showToast('The download address format is incorrect');
            }
          }
        }
      });
    }
  }

  cancel() {
    if (cancelToken != null) {
      cancelToken.cancel();
      cancelToken = null;
      setState(() {
        isDownloading = false;
        EnvironmentConfig.isDownloading = false;
        File f = File(currentSavePath);
        f.exists().then((value) {
          if (value) {
            f.deleteSync(recursive: true);
          }
        });
      });
    }
  }

  download(String url, String resourcesid) {
    print('=== download:$url');
    Map map = Map();
    map['url'] = url;
    map['resourcesid'] = resourcesid;
    EventBus.getInstance().send(Config.EVENT_BUS_SET_INDEX, map);
    return;
  }

  switchOperationMode() {
    checkList.clear();
    fileList.forEach((element) {
      checkList.add(false);
    });
    setState(() {
      isOperationMode = !isOperationMode;
      openSortMenu = false;
    });
  }

  clickTopMenu(int index) {
    switch (index) {
      case 0:
        CommonUtil.push(context, ImageListPage());
        break;
      case 1:
        CommonUtil.push(context, TypeFilePage(type: 'audio'));
        break;
      case 2:
        CommonUtil.push(context, VideoListPage());
        break;
      case 3:
        CommonUtil.push(context, TypeFilePage(type: 'doc'));
        break;
      case 4:
        openLock();
        break;
      case 5:
        break;
      case 6:
        CommonUtil.push(context, TypeFilePage(type: 'apk'));
        break;
      case 7:
        CommonUtil.push(context, TypeFilePage(type: 'other'));
        break;
      default:
    }
    setState(() {
      openSortMenu = false;
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
        CommonUtil.push(context, ImageDetailPage(file: fileList[index]))
            .then((value) {
          if (value != null && value == 1) {
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
          }
        });
        break;
      case 'audio':
        CommonUtil.push(context, AudioDetailPage(file: fileList[index]))
            .then((value) {
          if (value != null && value == 1) {
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
          }
        });
        break;
      case 'video':
        CommonUtil.push(context, VideoDetailPage(file: fileList[index]))
            .then((value) {
          if (value != null && value == 1) {
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
          }
        });
        break;
      case 'doc':
        CommonUtil.push(
            context, FileReaderPage(filePath: fileList[index].path));
        break;
      case 'dir':
        CommonUtil.push(context, DirectionPage(path: fileList[index].path))
            .then((value) {
          if (value != null && value == 1) {
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
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
                  Future.delayed(Duration(seconds: 2)).then((value) {
                    EasyLoading.dismiss();
                    ToastUtil.showToast('Delete complete');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  });
                }
              });
            } else {
              fileList[i].delete().then((value) {
                deleteNum++;
                if (deleteNum == checkedNum) {
                  Future.delayed(Duration(seconds: 2)).then((value) {
                    EasyLoading.dismiss();
                    ToastUtil.showToast('Delete complete');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  });
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
                if (FileUtil.isDirection(fileList[i].path)) {
                  Directory directory = Directory(fileList[i].path);
                  if (fileList[i].path.contains('/file_manager/m3u8/')) {
                    SharedUtil.saveString(
                        FileUtil.getFileNameFromUrl2(fileList[i].path) +
                            '_rename',
                        value);
                    ToastUtil.showToast('Rename complete');
                    EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  } else {
                    directory.rename(newPath).then((value) {
                      Future.delayed(Duration(seconds: 2)).then((value) {
                        EasyLoading.dismiss();
                        ToastUtil.showToast('Rename complete');
                        EventBus.getInstance()
                            .send(Config.EVENT_BUS_FILE_REFRESH);
                      });
                    });
                  }
                } else {
                  fileList[i].rename(newPath).then((value) {
                    Future.delayed(Duration(seconds: 2)).then((value) {
                      EasyLoading.dismiss();
                      ToastUtil.showToast('重命名完成');
                      EventBus.getInstance()
                          .send(Config.EVENT_BUS_FILE_REFRESH);
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

  clickBottomBatItem(int index) {}

  @override
  void dispose() {
    EventBus.getInstance().off(Config.EVENT_BUS_FILE_REFRESH);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, //修改状态栏文字颜色的
      child: buildMain(),
    );
  }

  buildMain() {
    if (openSortMenu || isOperationMode) {
      return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: FlutterEasyLoading(child: buildChildMain()));
    }
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddMenu(),
          child: Icon(Icons.add),
        ),
        body: FlutterEasyLoading(child: buildChildMain()));
  }

  buildChildMain() {
    return RefreshIndicator(
        onRefresh: () async {
          initFileList();
          await Future.delayed(Duration(milliseconds: 2000), () {});
          return Future.value(true);
        },
        child: Column(
          children: [
            isOperationMode ? getMenuTopbar() : getTopbar(),
            ViewUtils.getLine(CommonUtil.getScreenWidth(context), 2.w),
            if (openSortMenu) buildSortMenu(),
            if (isDownloading) getDownloadingView(downloadFile, progress),
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
        ));
  }

  buildSortMenu() {
    List<Widget> list = List();
    List<Widget> list1 = List();
    List<Widget> list2 = List();
    list.add(getMenuItem(0, 'Image', 'images/icon_img.png'));
    list.add(getMenuItem(1, 'Music', 'images/icon_music.png'));
    list.add(getMenuItem(2, 'Video', 'images/icon_video.png'));
    list.add(getMenuItem(3, 'Document', 'images/icon_doc.png'));
    list.add(getMenuItem(4, 'Safe Box', 'images/icon_sock.png'));
    list.add(getMenuItem(5, 'E-book', 'images/icon_book.png'));
    list.add(getMenuItem(6, 'Application', 'images/icon_app.png'));
    list.add(getMenuItem(7, 'Other', 'images/icon_other.png'));

    if (list.length > 4) {
      list1.addAll(list.sublist(0, 4));
      list2.addAll(list.sublist(4));
    } else {
      list1.addAll(list);
    }
    return Container(
        width: CommonUtil.getScreenWidth(context),
        //height: CommonUtil.getScreenHeight(context),
        color: Color(0xA0000000),
        child: Column(
          children: [
            Container(
              width: CommonUtil.getScreenWidth(context),
              padding: EdgeInsets.only(top: 56.w, bottom: 48.w),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(ScreenUtil().setHeight(40.w)),
                      bottomRight:
                          Radius.circular(ScreenUtil().setHeight(40.w)))),
              child: Column(
                children: [
                  Row(
                    children: list1,
                  ),
                  Container(
                      width: CommonUtil.getScreenWidth(context),
                      height: 48.w,
                      color: Colors.white),
                  Row(
                    children: list2,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  openSortMenu = false;
                });
              },
              child: Container(
                width: CommonUtil.getScreenWidth(context),
                height: 1200.w,
                color: Color(0xA0000000),
              ),
            ),
          ],
        ));
  }

  getMenuItem(int index, String txt, String img) {
    return GestureDetector(
        onTap: () => clickTopMenu(index),
        child: Container(
          width: 187.5.w,
          color: Colors.white,
          alignment: Alignment.center,
          child: Column(
            children: [
              Image(
                image: AssetImage(img),
                width: 62.w,
                height: 50.w,
              ),
              CommonUtil.getH_Magin(20.w),
              Text(
                txt,
                style: TextStyle(
                    fontSize:
                        ScreenUtil().setSp(28, allowFontScalingSelf: false)),
              )
            ],
          ),
        ));
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
      case 'book':
        img = 'images/icon_book.png';
        break;
      default:
    }
    String time = '';
    try {
      if (FileUtil.isDirection(file.path)) {
        Directory directory = Directory(file.path);
        time = DateUtil.myFormatDateTime(directory.statSync().changed,
            format: 'yyyy-MM-dd HH:mm');
        img = 'images/icon_myfile_dirs.png';
        if (file.path.contains('/file_manager/m3u8/')) {
          img = 'images/icon_video.png';
        }
      } else {
        time = DateUtil.myFormatDateTime(file?.lastModifiedSync(),
            format: 'yyyy-MM-dd HH:mm');
      }
    } catch (e) {}

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

  getTopbar() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 176.w,
      padding: EdgeInsets.only(bottom: 24.w),
      color: Colors.white,
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              CommonUtil.getW_Magin(36.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    openSortMenu = !openSortMenu;
                    isOperationMode = false;
                  });
                },
                child: Text(
                  'Sort',
                  style: TextStyle(
                      color: ColorConfig.main_txt_color,
                      fontSize:
                          ScreenUtil().setSp(36, allowFontScalingSelf: false)),
                ),
              ),
              Image.asset(
                openSortMenu
                    ? 'images/icon_menu_up.png'
                    : 'images/icon_menu_down.png',
                width: 18.w,
                height: 12.w,
              ),
              CommonUtil.getW_Magin(150.w),
              Text(
                'File Management',
                style: TextStyle(
                    color: ColorConfig.main_txt_color,
                    fontSize:
                        ScreenUtil().setSp(36, allowFontScalingSelf: false)),
              ),
              CommonUtil.getW_Magin(120.w),
              GestureDetector(
                  onTap: () => switchOperationMode(),
                  child: Image.asset(
                    'images/icon_menu.png',
                    width: 54.w,
                    height: 54.w,
                  )),
            ],
          )
        ],
      ),
    );
  }

  getMenuTopbar() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 176.w,
      padding: EdgeInsets.only(bottom: 24.w),
      alignment: Alignment.bottomLeft,
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              CommonUtil.getW_Magin(36.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    openSortMenu = false;
                    isOperationMode = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: Color(0xff5183F7),
                      fontSize:
                          ScreenUtil().setSp(28, allowFontScalingSelf: false)),
                ),
              ),
              CommonUtil.getW_Magin(140.w),
              Text(
                'File Management',
                style: TextStyle(
                    color: ColorConfig.main_txt_color,
                    fontSize:
                        ScreenUtil().setSp(36, allowFontScalingSelf: false)),
              ),
              CommonUtil.getW_Magin(70.w),
              GestureDetector(
                onTap: () {
                  for (int i = 0; i < checkList.length; i++) {
                    checkList[i] = true;
                  }
                  setState(() {});
                },
                child: Text(
                  'Select all',
                  style: TextStyle(
                      color: Color(0xff5183F7),
                      fontSize:
                          ScreenUtil().setSp(28, allowFontScalingSelf: false)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  getDownloadingView(String fileName, double p) {
    String img = 'images/icon_other.png';
    switch (FileUtil.getMediaType(fileName)) {
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
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 136.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CommonUtil.getW_Magin(44.w),
          Image.asset(
            img,
            width: 38.w,
            height: 36.w,
          ),
          CommonUtil.getW_Magin(44.w),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              CommonUtil.getH_Magin(32.w),
              Container(
                  width: 592.w,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 400.w,
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: ColorConfig.main_txt_color,
                              fontSize: ScreenUtil()
                                  .setSp(28, allowFontScalingSelf: false)),
                        ),
                      ),
                      ViewUtils.getTextView(
                          '${(p * 100).floor()}%', 24, Color(0xffB0B3BE)),
                    ],
                  )),
              CommonUtil.getH_Magin(16.w),
              Container(
                  width: 592.w,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                    value: (p == null || p.isNaN) ? 0 : p,
                  )),
            ],
          )
        ],
      ),
    );
  }
}
