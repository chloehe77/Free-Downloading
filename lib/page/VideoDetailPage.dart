import 'dart:async';
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
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../Config.dart';
import 'MovePage.dart';
import 'login/LoginPage.dart';

class VideoDetailPage extends StatefulWidget {
  File file;
  bool isLock;

  VideoDetailPage({this.file, this.isLock = false});

  @override
  State<StatefulWidget> createState() {
    return VideoDetailPageState();
  }
}

class VideoDetailPageState extends State<VideoDetailPage>
    with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String fileName;
  VideoPlayerController _controller;
  ChewieController chewieController;
  bool _isPlaying = false;
  bool isOperationMode = false;
  File file;
  Timer myTimer;

  @override
  void initState() {
    super.initState();
    file = widget.file;
    print('VideoDetailPage:${file.path}');
    fileName = FileUtil.getFileNameFromUrl(file.path);
    if (file.path?.contains('/file_manager/m3u8')) {
      _controller = VideoPlayerController.network(
          SharedUtil.getString(FileUtil.getFileNameFromUrl2(file.path)))

        ..addListener(() {
          final bool isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        })

        ..initialize().then((_) {
          setState(() {});
        });
    } else {
      _controller = VideoPlayerController.file(file)

        ..addListener(() {
          final bool isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        })

        ..initialize().then((_) {
          setState(() {});
        });
    }

    chewieController = ChewieController(
      videoPlayerController: _controller,
    );

    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      myTimer = timer;
      if (!chewieController.isFullScreen) {
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    });
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
        if (value == SharedUtil.getString(SharedUtil.safe_password)) {
          if (file.path.contains('/file_manager/m3u8/')) {

            List<String> list =
                SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
            if (list == null) {
              list = List();
            }
            list.add(file.path);
            SharedUtil.setStringList(SharedUtil.m3u8_file_list_lock, list);
            ToastUtil.showToast('Successfully moved to safe');
            Navigator.pop(context, 1);
          }
          moveToLock();
        } else {
          ToastUtil.showToast('Password error');
        }
      }
    });
  }

  outLock() {
    if (file.path.contains('/file_manager/m3u8/')) {
      List<String> list =
          SharedUtil.getStringList(SharedUtil.m3u8_file_list_lock);
      if (list != null && list.length > 0) {
        list.remove(file.path);
        SharedUtil.setStringList(SharedUtil.m3u8_file_list_lock, list);
        EasyLoading.dismiss();
        EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
        ToastUtil.showToast('Operation complete');
        Navigator.pop(context, 1);
      }
    } else {
      FileUtil.getResourceLocalPathByType(FileUtil.getMediaType(file.path))
          .then((value) {
        String newPath = value + FileUtil.getFileNameFromUrl(file.path);
        file.rename(newPath).then((value) {
          Future.delayed(Duration(seconds: 1)).then((value) {
            EasyLoading.dismiss();
            ToastUtil.showToast('Operation complete');
            Navigator.pop(context, 1);
          });
        });
      });
    }
  }

  moveToLock() {
    EasyLoading.show();
    FileUtil.getLockPath().then((rootPath) {
      String newPath = rootPath + FileUtil.getFileNameFromUrl(file.path);
      print("newPath:$newPath");
      file.rename(newPath).then((value) {
        Future.delayed(Duration(seconds: 3)).then((value) {
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
          if (file.path.contains('file_manager/m3u8')) {
            Directory directory = Directory(file.path);
            directory.delete(recursive: true).then((value) {
              EasyLoading.dismiss();
              Future.delayed(Duration(milliseconds: 1000)).then((value) {
                ToastUtil.showToast('Delete complete');
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                Navigator.pop(context, 1);
              });
            });
          } else {
            file.delete().then((value) {
              EasyLoading.dismiss();
              Future.delayed(Duration(milliseconds: 1000)).then((value) {
                ToastUtil.showToast('Delete complete');
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                Navigator.pop(context, 1);
              });
            });
          }
          break;
        case 11:
          if (widget.isLock) {
            outLock();
          } else {
            intoLock();
          }
          break;
        case 12:
          if (file.path.contains('/file_manager/m3u8/')) {
            ToastUtil.showToast('not support');
            return;
          }
          List<File> moveFileList = List();
          moveFileList.add(file);
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
          CommonUtil.shareToWechat(context, file.path);
          break;
        case 14:

          showDialog(
            context: context,
            builder: (context) =>
                TipsInputDialog(title: 'Please enter a file name'),
          ).then((value) {
            if (value != null) {
              if (file.path.contains('/file_manager/m3u8/')) {
                SharedUtil.saveString(
                    FileUtil.getFileNameFromUrl2(file.path) + '_rename', value);
                ToastUtil.showToast('Rename complete');
                EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                Navigator.pop(context, 1);
              } else {
                EasyLoading.show();
                List<String> strs = fileName.split('.');
                String newPath = file.path.replaceAll(strs[0], value);
                file.rename(newPath).then((value) {
                  EasyLoading.dismiss();
                  ToastUtil.showToast('Rename complete');
                  EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
                  Navigator.pop(context, 1);
                });
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
    _controller.dispose();
    chewieController?.dispose();
    myTimer?.cancel();
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
    if (isOperationMode) {
      return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: FlutterEasyLoading(child: buildMainView()));
    }
    return Scaffold(
        key: _scaffoldKey,
        // floatingActionButton: new FloatingActionButton(
        //   onPressed: _controller?.value.isPlaying
        //       ? _controller.pause
        //       : _controller.play,
        //   child: new Icon(
        //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        //   ),
        // ),
        backgroundColor: Colors.white,
        body: FlutterEasyLoading(child: buildMainView()));
  }

  buildMainView() {
    return FlutterEasyLoading(
        child: Column(
      children: [
        ViewUtils.buildTopBar(context, fileName,
            showMenuBtn: true, listener: this),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 686.w,
                  child: _controller.value.initialized

                      ? new AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: Chewie(
                            controller: chewieController,
                          ),
                        )
                      : new Container(),
                ),
              ),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context,
                    listener: this, isLock: widget.isLock)
            ],
          ),
        )
      ],
    ));
  }

  buildMainView2() {
    return FlutterEasyLoading(
        child: Column(
      children: [
        ViewUtils.buildTopBar(context, fileName,
            showMenuBtn: true, listener: this),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 686.w,
                  child: _controller.value.initialized
                      ? new AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : new Container(),
                ),
              ),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context,
                    listener: this, isLock: widget.isLock)
            ],
          ),
        )
      ],
    ));
  }
}
