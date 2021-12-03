import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:filemanager/Config.dart';
import 'package:filemanager/EnvironmentConfig.dart';
import 'package:filemanager/dialog/DownloadTipDialog.dart';
import 'package:filemanager/net/DownLoadManage.dart';
import 'package:filemanager/page/DirectionPage.dart';
import 'package:filemanager/page/ImageDetailPage.dart';
import 'package:filemanager/page/ImageListPage.dart';
import 'package:filemanager/page/OpenFilePage.dart';
import 'package:filemanager/page/SearchPage.dart';
import 'package:filemanager/page/TypeFilePage.dart';
import 'package:filemanager/page/VideoListPage.dart';
import 'package:filemanager/tool/CommonUtil.dart';
import 'package:filemanager/tool/DateUtil.dart';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:filemanager/tool/ToastUtil.dart';
import 'package:filemanager/tool/ViewUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'AudioDetailPage.dart';
import 'FileReaderPage.dart';
import 'VideoDetailPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  bool openMenu = false;
  bool showBanner = false;
  bool isDownloading = false;
  double progress = 0;
  String downloadFile = '';
  List<File> fileList = List();
  List<Map> tempList = new List();
  CancelToken cancelToken;
  String currentSavePath = '';
  String resourcesId = '';
  String currentUrl = '';

  List<String> downloadingUrls;
  Map<String, double> progressMap = Map();
  Map<String, bool> isPauseMap = Map();

  @override
  void initState() {
    super.initState();

    EventBus.getInstance().on(Config.EVENT_BUS_FILE_REFRESH, (arg) {
      print('home EVENT_BUS_FILE_REFRESH');
      initFileList();
    });

    EventBus.getInstance().on(Config.EVENT_BUS_SET_INDEX, (arg) {
      print('Home EVENT_BUS_SET_INDEX');
      if (arg != null && arg['url'] != null) {
        pauseAll();

        resourcesId = arg['resourcesid'];
        currentUrl = arg['url'];
        downloadFile = FileUtil.getFileNameFromUrl(currentUrl);
        progress = 0;
        download(currentUrl, resourcesId);
      }
    });

    initFileList();

    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      if (value != null &&
          value?.text != null &&
          value?.text.replaceAll('\uFEFF', '') != '') {
        download(value?.text.replaceAll('\uFEFF', ''), '');
        Clipboard.setData(ClipboardData(text: ''));
      }
    });

    SharedUtil.getInstance().then((value) {
      setState(() {
        downloadingUrls =
            SharedUtil.getStringList(SharedUtil.downloading_url_list);
        print('=== downloadingUrls:${downloadingUrls}');
        if (downloadingUrls == null) {
          downloadingUrls = List();
        }

        if (downloadingUrls.length > 0) {
          downloadingUrls.forEach((element) {
            double progress = SharedUtil.getDouble('${element}_progress');
            if (progress != null) {
              progressMap[element] = progress;
            } else {
              progressMap[element] = 0;
            }
            isPauseMap[element] = true;
          });
        }
      });
    });
  }

  Future requestPermission() async {
    PermissionStatus storageStatus;

    await [
      Permission.camera,
      Permission.storage,
    ].request().then((value) {
      storageStatus = value[Permission.storage];
    });
    debugPrint("Waiting:$storageStatus");
  }

  addDownloadingUrls(String url) {
    downloadingUrls.add(url);
    SharedUtil.setStringList(SharedUtil.downloading_url_list, downloadingUrls);
  }

  initFileList() {
    tempList.clear();
    setState(() {
      fileList.clear();
    });
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
      setState(() {});
    });
  }

  @override
  void dispose() {
    EventBus.getInstance().off(Config.EVENT_BUS_CODE_BANNER);
    EventBus.getInstance().off(Config.EVENT_BUS_FILE_REFRESH);
    EventBus.getInstance().off(Config.EVENT_BUS_SET_INDEX);
    SharedUtil.setStringList(SharedUtil.downloading_url_list, null);

    super.dispose();
  }

  doOpenMenu() {
    setState(() {
      openMenu = !openMenu;
    });
  }

  clickMenu(int index) {
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
        intoLock();
        break;
      case 5:
        CommonUtil.push(context, TypeFilePage(type: 'book'));
        break;
      case 6:
        CommonUtil.push(context, TypeFilePage(type: 'apk'));
        break;
      case 7:
        CommonUtil.push(context, TypeFilePage(type: 'other'));
        break;
      default:
    }
  }

  // Scan code
  Future scan() async {
    bool scan = true;
    if (downloadingUrls.length > 0) {
      downloadingUrls.forEach((element) {
        if (!isPauseMap[element]) {
          ToastUtil.showToast('Please pause the current download task first');
          scan = false;
          return;
        }
      });
    }
    if (scan) {
      // try {
      //   ScanResult scanResult = await BarcodeScanner.scan();
      //   print('scan result: ' + scanResult.rawContent);
      //   viewdownload(scanResult?.rawContent);
      // } catch (e) {
      //   print('wrong result: $e');
      // }
    }
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
    }
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

  cancelUrl(int index, {bool delete = true}) {
    String url = downloadingUrls[index];
    DownLoadManage.getInstance().stop(url);
    cancelToken = null;
    if (delete) {
      File f = File(currentSavePath);
      f.exists().then((value) {
        if (value) {
          f.deleteSync(recursive: true);
        }
      });

      setState(() {
        progressMap.remove(downloadingUrls[index]);
        downloadingUrls.removeAt(index);

        SharedUtil.setStringList(
            SharedUtil.downloading_url_list, downloadingUrls);
      });
    }
  }

  download(String url, String resourcesid) {
    print('=== download:$url');
    currentUrl = url;
    if (!downloadingUrls.contains(currentUrl)) {
      addDownloadingUrls(url);
    }
    progressMap[currentUrl] = 0;
    isPauseMap[currentUrl] = false;
    setState(() {
      isDownloading = true;
      EnvironmentConfig.isDownloading = true;
    });
    progress = 0;
    downloadFile = FileUtil.getFileNameFromUrl(url);
    resourcesId = resourcesid;
    SharedUtil.saveString(SharedUtil.downloading_url, url);
    String flieType = FileUtil.getMediaType(downloadFile);
    FileUtil.getResourceLocalPathByType(flieType).then((savePath) {
      savePath = savePath + downloadFile;
      currentSavePath = savePath;
      print('=== savePath:$savePath');
      cancelToken = CancelToken();

      //HttpManager.getInstance().download(
      DownLoadManage.getInstance().download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) {
          setState(() {
            progress = count / total;
            progressMap[currentUrl] = progress;
            SharedUtil.saveDouble('${url}_progress', progress);
          });
          print(
              'onReceivedProgress:total:${total} count:${count} progress:${progressMap[currentUrl]}');
          if (count == total) {
            if (isDownloading) {
              ToastUtil.showToast('Download complete');
              downloadingUrls.remove(currentUrl);
              SharedUtil.setStringList(
                  SharedUtil.downloading_url_list, downloadingUrls);
              progress = 1;
              setState(() {
                isDownloading = false;
                EnvironmentConfig.isDownloading = false;
              });
              EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
              SharedUtil.saveString(SharedUtil.downloading_url, '');
            }
          }
        },
      ).then((value) {
        if (value != null) {
          if (value.statusCode == 200) {
            if (isDownloading) {
              progress = 1;
              ToastUtil.showToast('Download complete');
              setState(() {
                isDownloading = false;
                EnvironmentConfig.isDownloading = false;
              });
              SharedUtil.saveString(SharedUtil.downloading_url, '');
              EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
            }
          } else {
            print('=== 下载失败:${value.statusMessage}');
            ToastUtil.showToast('Download false:${value.statusMessage}');
            setState(() {
              isDownloading = false;
              EnvironmentConfig.isDownloading = false;
            });
          }
        }
      }).catchError((e) {
        if (e != null) {
          print('=== catchError:$e');
          ToastUtil.showToast('Download false');
          SharedUtil.saveString(SharedUtil.downloading_url, '');
          setState(() {
            isDownloading = false;
            EnvironmentConfig.isDownloading = false;
          });
        }
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

  intoLock() {
    String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
    if (token == null || token == '' || token == 'null') {
      ViewUtils.showLoginTip(context);
      return;
    }
    String safe_password = SharedUtil.getString(SharedUtil.safe_password);
    CommonUtil.showDialogIntoLockPage(context, safe_password);
  }

  downloadPause(int index) {
    String url = downloadingUrls[index];
    bool isPause = isPauseMap[url];
    if (isPause) {
      pauseAll();
      download(url, resourcesId);
    } else {
      cancelUrl(index, delete: false);
    }
    setState(() {
      isPauseMap[url] = !isPause;
    });
  }

  pauseAll() {
    if (downloadingUrls != null && downloadingUrls.length > 0) {
      for (int i = 0; i < downloadingUrls.length; i++) {
        cancelUrl(i, delete: false);
        isPauseMap[downloadingUrls[i]] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, //修改状态栏文字颜色的
        child: Scaffold(
            backgroundColor: Colors.white,
            body: RefreshIndicator(
                onRefresh: () async {
                  initFileList();
                  await Future.delayed(Duration(milliseconds: 2000), () {});
                  return Future.value(true);
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90.w,
                      ),
                      getSearchView(),
                      if (showBanner) getBanner(),
                      getMenus(),
                      Container(
                        width: CommonUtil.getScreenWidth(context),
                        height: 80.w,
                        alignment: Alignment.topCenter,
                        padding: EdgeInsets.only(top: 36.w),
                        child: GestureDetector(
                          onTap: () => doOpenMenu(),
                          child: Container(
                            width: 34.w,
                            height: 50.w,
                            color: Colors.transparent,
                            child: Image.asset(
                              openMenu
                                  ? 'images/icon_up.png'
                                  : 'images/icon_down.png',
                              width: 34.w,
                              height: 20.w,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: CommonUtil.getScreenWidth(context),
                        height: 2.w,
                        color: ColorConfig.line_color,
                      ),
                      Container(
                        padding: EdgeInsets.all(32.w),
                        child: Text(
                          'Recent file records',
                          style: TextStyle(
                              color: ColorConfig.main_txt_color,
                              fontSize: ScreenUtil()
                                  .setSp(32, allowFontScalingSelf: false)),
                        ),
                      ),
                      if (downloadingUrls != null && downloadingUrls.length > 0)
                        for (int i = 0; i < downloadingUrls.length; i++)
                          getDownloadingView(
                              FileUtil.getFileNameFromUrl(downloadingUrls[i]),
                              progressMap[downloadingUrls[i]],
                              i),
                      fileList.length == 0
                          ? ViewUtils.getNullView(context, hMargin: 20.w)
                          : getFileList(),
                      Container(
                        height: 800.w,
                      ),
                    ],
                  ),
                ))));
  }

  getDownloadingView(String fileName, double p, int index) {
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
                  width: 502.w,
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
                  width: 502.w,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                    value: (p == null || p.isNaN) ? 0 : p,
                  )),
            ],
          ),

          SizedBox(width: 20.w),
          GestureDetector(
              onTap: () {
                downloadPause(index);
              },
              child: Icon(
                  (isPauseMap[downloadingUrls[index]])
                      ? Icons.play_arrow
                      : Icons.pause,
                  size: 38.w)), //pause play_arrow
          SizedBox(width: 20.w),
          GestureDetector(
              onTap: () {
                cancelUrl(index, delete: true);
              },
              child: Icon(Icons.close, size: 38.w)),
        ],
      ),
    );
  }

  getBanner() {
    return Image.asset(
      'images/banner.png',
      width: CommonUtil.getScreenWidth(context),
      height: CommonUtil.getScreenWidth(context) / 2.35,
    );
  }

  getFileList() {
    List<Widget> views = List();
    for (int i = 0; i < fileList.length; i++) {
      File file = fileList[i];
      String name = FileUtil.getFileNameFromUrl(file.path);
      String img = 'images/icon_other.png';
      switch (FileUtil.getMediaType(name)) {
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
      views.add(getFileItem(i, img, name, time));
    }
    return Column(children: views);
  }

  getFileItem(int i, String img, String fileName, String time) {
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
                    child: Text(fileName,
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

  getMenus() {
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
      margin: EdgeInsets.only(top: 56.w),
      child: Column(
        children: [
          Row(
            children: list1,
          ),
          CommonUtil.getH_Magin(openMenu ? 48.w : 20.w),
          if (openMenu)
            Row(
              children: list2,
            ),
        ],
      ),
    );
  }

  getMenuItem(int index, String txt, String img) {
    return GestureDetector(
        onTap: () => clickMenu(index),
        child: Container(
          width: 187.5.w,
          alignment: Alignment.center,
          color: Colors.transparent,
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

  getSearchView() {
    return Container(
      width: CommonUtil.getScreenWidth(context),
      height: 64.w,
      color: Colors.white,
      margin: EdgeInsets.only(left: 32.w, right: 32.w),
      child: Row(
        children: [
          GestureDetector(
              onTap: () => CommonUtil.push(context, SearchPage()),
              child: Container(
                width: 600.w,
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
                      width: 500.w,
                      height: 64.w,
                      margin: EdgeInsets.only(left: 20.w),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.bottom,
                        cursorWidth: 1.w,
                        enabled: false,
                        cursorColor: Color(0xffCCCCCC),
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                            letterSpacing: 1.w,
                            color: Colors.black,
                            fontSize: ScreenUtil()
                                .setSp(26, allowFontScalingSelf: false)),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.all(0),
                          hintText: 'Please enter the search content',
                          hintStyle: TextStyle(
                              letterSpacing: 1.w, //字符间距
                              color: Color(0xFFBFBFBF),
                              fontSize: ScreenUtil()
                                  .setSp(26, allowFontScalingSelf: false)),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          CommonUtil.getW_Magin(32.w),
          GestureDetector(
            onTap: () => scan(),
            child: Image(
              image: AssetImage('images/icon_scan.png'),
              width: 54.w,
              height: 54.w,
            ),
          ),
        ],
      ),
    );
  }
}
