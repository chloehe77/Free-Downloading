import 'dart:io';
import 'package:filemanager/tool/EventBus.dart';
import 'package:filemanager/tool/FileUtil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Config.dart';
import 'EnvironmentConfig.dart';
import 'dialog/DownloadTipDialog.dart';
import 'page/FilePage.dart';
import 'page/HomePage.dart';
import 'page/MinePage.dart';
import 'page/login/LoginPage.dart';
import 'tool/CommonUtil.dart';
import 'tool/SharedUtil.dart';

class AppPage extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<AppPage> with WidgetsBindingObserver {
  DateTime lastPopTime;
  //Currently selected page index
  var _currentIndex = 0;

  HomePage homePage;
  FilePage filePage;
  MinePage minePage;

  List<Widget> _pages = [
    HomePage(),
    FilePage(),
    MinePage(),
  ];

  //Returns a different page based on the index
  currentPage() {
    switch (_currentIndex) {
      case 0:
        //back to home page
        if (homePage == null) {
          homePage = new HomePage();
        }
        return homePage;
      case 1:
        if (filePage == null) {
          filePage = new FilePage();
        }
        return filePage;
      case 2:
        if (minePage == null) {
          minePage = new MinePage();
        }
        return minePage;
    }
  }

  //Bottom part
  BottomNavigationBarItem bottomItem(int index, var press, var normal) {
    //bottom title
    var title = Config.tab_home;
    switch (index) {
      case 1:
        title = Config.tab_file;
        break;
      case 2:
        title = Config.tab_mine;
        break;
    }
    return new BottomNavigationBarItem(
        title: new Text(
          //title
          title,
          style: TextStyle(
              //size
              fontSize: ScreenUtil().setSp(22, allowFontScalingSelf: false),
              //color
              color: _currentIndex == index
                  ? ColorConfig.blue
                  : ColorConfig.sub_sub_txt_color),
        ),
        //do picture switching display
        icon: Image.asset(
          _currentIndex == index ? press : normal,
          width: 48.h,
          height: 48.h,
        ));
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: Size(750, 1624), allowFontScaling: false);
    return WillPopScope(
      child: Scaffold(
        bottomNavigationBar: new BottomNavigationBar(
            showUnselectedLabels: true,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              //Import text and icons
              bottomItem(
                  0, 'images/icon_home.png', 'images/icon_home_black.png'),
              bottomItem(
                  1, 'images/icon_file.png', 'images/icon_file_black.png'),
              bottomItem(
                  2, 'images/icon_mine.png', 'images/icon_mine_black.png'),
            ]),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      onWillPop: () {
        // back click
        if (lastPopTime == null ||
            DateTime.now().difference(lastPopTime) > Duration(seconds: 2)) {
          lastPopTime = DateTime.now();
          Fluttertoast.showToast(msg: 'Press again to exit');
        } else {
          lastPopTime = DateTime.now();
          // logout app
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initShare();
    WidgetsBinding.instance.addObserver(this);
    requestPermission();
    SharedUtil.getInstance().then((value) {
      if (SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN) == null) {
        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (context) {
          return LoginPage();
        }));
      }
    });
    FileUtil.getResourceLocalPath().then((path) {
      Directory root = Directory(path);
      if (!root.existsSync()) {
        root.createSync();
      }
      root.exists().then((value) {
        if (value) {
          createDir(path, 'imgs/');
          createDir(path, 'videos/');
          createDir(path, 'audios/');
          createDir(path, 'docs/');
          createDir(path, 'apks/');
          createDir(path, 'others/');
          createDir(path, 'news/');
          createDir(path, '.lock/');
          createDir(path, 'txdownload/');
        } else {
          root.create().then((value) {
            createDir(path, 'imgs/');
            createDir(path, 'videos/');
            createDir(path, 'audios/');
            createDir(path, 'docs/');
            createDir(path, 'apks/');
            createDir(path, 'others/');
            createDir(path, 'news/');
            createDir(path, '.lock/');
            createDir(path, 'txdownload/');
          });
        }
      });
    });
    FileUtil.getLockPath().then((path) {
      Directory root = Directory(path);
      root.exists().then((value) {
        if (!value) {
          root.createSync();
        }
      });
    });

    EventBus.getInstance().on(Config.EVENT_BUS_SET_INDEX, (arg) {
      print('app EVENT_BUS_SET_INDEX');
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  initShare() {
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>> initShare');
  }

  void _onEvent(Object event) {
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    Map resMap_t = event;
    Map<String, dynamic> resMap = Map<String, dynamic>.from(resMap_t);
    String path = resMap['path'];
    Map<String, dynamic> params = Map<String, dynamic>.from(resMap['params']);
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>onSuccess:' + resMap.toString());
  }

  void _onError(Object event) {
    setState(() {
      print('>>>>>>>>>>>>>>>>>>>>>>>>>>>onError:' + event.toString());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("-- app --" + state.toString());
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (EnvironmentConfig.isDownloading) {
          print('-- app -- Downloading，please wait');
          return;
        }
        Clipboard.getData(Clipboard.kTextPlain).then((value) {
          if (value != null && value?.text != '') {
            List<String> strs = value.text.split("#");
            if (strs.length == 3 && strs[1].length == 15) {
              print('-- app --Download');
              showDialog(
                context: context,
                builder: (context) {
                  return DownloadTipDialog(
                    tip: 'Clipboard download password',
                  );
                },
              ).then((value) {
                if (value == 1) {
                  String token =
                      SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
                  if (token == null || token == '' || token == 'null') {
                    showLoginTip();
                  } else {
                    Navigator.pushAndRemoveUntil(context,
                        new MaterialPageRoute(builder: (BuildContext c) {
                      return new AppPage();
                    }), (r) => false);
                  }
                }
              });
            }
          }
        });
        break;
      case AppLifecycleState.paused: // The background
        break;
      default:
        break;
    }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EventBus.getInstance().off(Config.EVENT_BUS_SET_INDEX);
    super.dispose();
  }

  createDir(String parent, String dir) {
    Directory dirImgs = Directory(parent + dir);
    dirImgs.exists().then((v1) {
      if (!v1) {
        dirImgs.createSync();
      }
    });
  }

  Future requestPermission() async {
    PermissionStatus cameraStatus;
    PermissionStatus storageStatus;

    await [
      Permission.camera,
      Permission.microphone,
    ].request().then((value) {
      cameraStatus = value[Permission.camera];
      storageStatus = value[Permission.storage];
    });
    debugPrint("Request permission and obtain permission:$cameraStatus");
    debugPrint("Request permission and obtain permission:$storageStatus");
  }
}
