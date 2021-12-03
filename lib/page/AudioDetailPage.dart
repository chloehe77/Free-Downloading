import 'dart:io';
import 'package:filemanager/dialog/InputDialog.dart';
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

import '../Config.dart';
import 'MovePage.dart';
import 'login/LoginPage.dart';

class AudioDetailPage extends StatefulWidget {
  File file;
  List<File> fileList;
  int index;
  bool isLock;

  AudioDetailPage({this.file, this.fileList, this.index, this.isLock = false});

  @override
  State<StatefulWidget> createState() {
    return AudioDetailPageState();
  }
}

class AudioDetailPageState extends State<AudioDetailPage>
    with ClickMenuListener {
  GlobalKey _scaffoldKey = new GlobalKey<ScaffoldState>();
  String fileName;
  // AudioPlayer audioPlayer;
  bool isplaying = false;
  int total = -1;
  String totalStr = '0:00';
  String currentStr = '0:00';
  double progress = 0;
  int position;
  File currentFile;
  bool isOperationMode = false;

  @override
  void initState() {
    super.initState();
    position = widget.index;
    currentFile = widget.file;
    initAudioPlayer();
  }

  initAudioPlayer() {
    fileName = FileUtil.getFileNameFromUrl(currentFile.path);
    // audioPlayer = AudioPlayer();
    // audioPlayer.onAudioPositionChanged.listen((event) {
    //   if (mounted) {
    //     setState(() {
    //       int m = (event.inSeconds / 60).floor();
    //       int s = event.inSeconds - m * 60;
    //       String sStr = s.toString();
    //       if (s < 10) {
    //         sStr = '0' + sStr;
    //       }
    //       currentStr = '${m}:${sStr}';
    //       if (total != -1) {
    //         progress = event.inSeconds / total;
    //       }
    //     });
    //   }
    // });
    // audioPlayer.onDurationChanged.listen((event) {
    //   if (total == -1) {
    //     setState(() {
    //       total = event.inSeconds;
    //       print('total:$total');
    //       int m = (total / 60).floor();
    //       int s = total - m * 60;
    //       String sStr = s.toString();
    //       if (s < 10) {
    //         sStr = '0' + sStr;
    //       }
    //       totalStr = '${m}:${sStr}';
    //     });
    //   }
    // });
    // audioPlayer.onPlayerCompletion.listen((event) {
    //   setState(() {
    //     audioPlayer.seek(Duration(seconds: 0));
    //     progress = 0;
    //     isplaying = false;
    //   });
    // });
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
          moveToLock();
        } else {
          ToastUtil.showToast('password error');
        }
      }
    });
  }

  outLock() {
    FileUtil.getResourceLocalPathByType(FileUtil.getMediaType(currentFile.path))
        .then((value) {
      String newPath = value + FileUtil.getFileNameFromUrl(currentFile.path);
      currentFile.rename(newPath).then((value) {
        Future.delayed(Duration(seconds: 1)).then((value) {
          EasyLoading.dismiss();
          ToastUtil.showToast('操作完成');
          Navigator.pop(context, 1);
        });
      });
    });
  }

  moveToLock() {
    EasyLoading.show();
    FileUtil.getLockPath().then((rootPath) {
      String newPath = rootPath + FileUtil.getFileNameFromUrl(currentFile.path);
      print("newPath:$newPath");
      currentFile.rename(newPath).then((value) {
        Future.delayed(Duration(seconds: 2)).then((value) {
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
      //右上角菜单键
      setState(() {
        isOperationMode = !isOperationMode;
      });
    } else {
      switch (type) {
        case 10:
          EasyLoading.show();
          currentFile.delete().then((value) {
            EasyLoading.dismiss();
            ToastUtil.showToast('Delete complete');
            EventBus.getInstance().send(Config.EVENT_BUS_FILE_REFRESH);
            Navigator.pop(context, 1);
          });
          break;
          if (widget.isLock) {
            outLock();
          } else {
            intoLock();
          }
          break;
        case 12:
          List<File> moveFileList = List();
          moveFileList.add(currentFile);
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
          CommonUtil.shareToWechat(context, currentFile.path);
          break;
        case 14:
          showDialog(
            context: context,
            builder: (context) =>
                InputDialog(title: 'Please enter a file name'),
          ).then((value) {
            if (value != null) {
              EasyLoading.show();
              List<String> strs = fileName.split('.');
              String newPath = currentFile.path.replaceAll(strs[0], value);
              currentFile.rename(newPath).then((value) {
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

  play() {
    // if (isplaying) {
    //   audioPlayer.pause();
    // } else {
    //   audioPlayer.play(currentFile.path, isLocal: true);
    // }
    // setState(() {
    //   isplaying = !isplaying;
    // });
  }

  pre() {
    if (widget.fileList == null) {
      ToastUtil.showToast('No more ahead');
      return;
    }
    if (position == 0) {
      ToastUtil.showToast('No more ahead');
      return;
    }
    total = -1;
    // audioPlayer.stop();
    position--;
    currentFile = widget.fileList[position];
    initAudioPlayer();
    isplaying = false;
    play();
  }

  next() {
    if (widget.fileList == null) {
      ToastUtil.showToast('Not in the back');
      return;
    }
    if (position == widget.fileList.length - 1) {
      ToastUtil.showToast('Not in the back');
      return;
    }
    total = -1;
    // audioPlayer.stop();
    position++;
    currentFile = widget.fileList[position];
    initAudioPlayer();
    isplaying = false;
    play();
  }

  @override
  void dispose() {
    // audioPlayer.release();
    super.dispose();
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ViewUtils.buildTopBar(context, 'Music',
            showMenuBtn: true, listener: this),
        Expanded(
          child: Stack(
            children: [
              buidAudioView(),
              if (isOperationMode)
                ViewUtils.buildBottomBar(context,
                    listener: this, isLock: widget.isLock)
            ],
          ),
        )
      ],
    );
  }

  buidAudioView() {
    return Column(
      children: [
        CommonUtil.getH_Magin(52.w),
        ViewUtils.getTextView(fileName, 36, ColorConfig.main_txt_color),
        CommonUtil.getH_Magin(148.w),
        Image.asset(
          'images/bg_audio_page.png',
          width: 370.w,
          height: 356.w,
        ),
        CommonUtil.getH_Magin(290.w),
        Row(
          children: [
            CommonUtil.getW_Magin(64.w),
            ViewUtils.getTextView(currentStr, 24, Color(0xffB0B3BE)),
            Container(
                width: 464.w,
                margin: EdgeInsets.only(left: 24.w, right: 24.w),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                  value: (progress == null || progress.isNaN) ? 0 : progress,
                )),
            ViewUtils.getTextView(totalStr, 24, Color(0xffB0B3BE)),
          ],
        ),
        CommonUtil.getH_Magin(92.w),
        Row(
          children: [
            CommonUtil.getW_Magin(140.w),
            GestureDetector(
              onTap: () => pre(),
              child: Image.asset(
                'images/icon_pre.png',
                width: 40.w,
                height: 44.w,
              ),
            ),
            CommonUtil.getW_Magin(176.w),
            GestureDetector(
              onTap: () => play(),
              child: Image.asset(
                isplaying ? 'images/icon_pause.png' : 'images/icon_play.png',
                width: 40.w,
                height: 44.w,
              ),
            ),
            CommonUtil.getW_Magin(176.w),
            GestureDetector(
              onTap: () => next(),
              child: Image.asset(
                'images/icon_next.png',
                width: 40.w,
                height: 44.w,
              ),
            ),
          ],
        )
      ],
    );
  }
}
