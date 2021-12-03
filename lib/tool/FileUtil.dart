import 'dart:io';
import 'dart:typed_data';
import 'package:filemanager/EnvironmentConfig.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'SharedUtil.dart';

class FileUtil {
  static const String DOWNLOAD_RESOURCES = "/file_manager/";
  static const String DOWNLOAD_RESOURCES2 = "/file_manager";
  static const String DOWNLOAD_PATH_IMG = "/file_manager/imgs/";
  static const String DOWNLOAD_PATH_VIDEO = "/file_manager/videos/";
  static const String DOWNLOAD_PATH_AUDIO = "/file_manager/audios/";
  static const String DOWNLOAD_PATH_DOC = "/file_manager/docs/";
  static const String DOWNLOAD_PATH_APK = "/file_manager/apks/";
  static const String DOWNLOAD_PATH_OTHER = "/file_manager/others/";
  static const String DOWNLOAD_PATH_NEW = "/file_manager/news/";
  static const String DOWNLOAD_PATH_LOCK = "/lock/";
  static const String DOWNLOAD_PATH_M3U8_IOS = "/com.SJMediaCacheServer.cache";

  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  static bool fileExistsSync(String path) {
    return File(path).existsSync();
  }

  static Future<String> getResourceLocalPath() async {
    final directory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path + DOWNLOAD_RESOURCES;
  }

  static Future<String> getM3U8LocalPath() async {
    final directory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path + DOWNLOAD_RESOURCES2;
  }

  static Future<String> getLockPath() async {
    final directory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path + DOWNLOAD_PATH_LOCK;
  }

  static Future<String> getResourceLocalPathByType(String type) async {
    final directory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    String path = DOWNLOAD_PATH_OTHER;
    switch (type) {
      case 'image':
        path = DOWNLOAD_PATH_IMG;
        break;
      case 'apk':
        path = DOWNLOAD_PATH_APK;
        break;
      case 'doc':
        path = DOWNLOAD_PATH_DOC;
        break;
      case 'audio':
        path = DOWNLOAD_PATH_AUDIO;
        break;
      case 'video':
        path = DOWNLOAD_PATH_VIDEO;
        break;
      case 'new':
        path = DOWNLOAD_PATH_NEW;
        break;
      default:
    }
    return directory.path + path;
  }

  static Future<String> getLocalPath(String path) async {
    final directory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path + path;
  }

  static upZipFile(String upZipFile, String upZipPath) async {
    if (!File(upZipFile).existsSync()) {
      Fluttertoast.showToast(msg: "Zipped folder does not exist！");
      return;
    }

    if (File(upZipPath).existsSync()) {
      File(upZipPath).delete();
    }
    print('upZipPath:{$upZipFile}');
    print('upZipPath2:{$upZipPath}');

    List<int> bytes = File(upZipFile).readAsBytesSync();

    Archive archive = ZipDecoder().decodeBytes(bytes);

    for (ArchiveFile file in archive) {
      if (file.isFile) {
        List<int> data = file.content;
        File(upZipPath + "/" + file.name)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(upZipPath + "/" + file.name)..create(recursive: true);
      }
    }
    Fluttertoast.showToast(msg: "Decompression succeeded");
    print("解压成功:${upZipPath}");
  }

  static String getFileNameFromUrl(String url) {
    List<String> strs = url.split("/");
    String fileName = strs[strs.length - 1];
    List<String> strs2 = fileName.split("\\?");
    String suffix = '';
    if (url.contains('/file_manager/m3u8/')) {
      suffix = '.mp4';
    }
    String name = strs2[0] + suffix;
    if (SharedUtil.getString(name + '_rename') != null) {
      name = SharedUtil.getString(name + '_rename');
    }
    return name;
  }

  static String getFileNameFromUrl2(String url) {
    List<String> strs = url.split("/");
    String fileName = strs[strs.length - 1];
    List<String> strs2 = fileName.split("\\?");
    String suffix = '';
    if (url.contains('/file_manager/m3u8/')) {
      suffix = '.mp4';
    }
    String name = strs2[0] + suffix;
    return name;
  }

  static String getMediaType(final String url) {
    if (url.contains('/file_manager/m3u8/')) {
      return 'video';
    }
    if (isDirection(url)) {
      return 'dir';
    }
    if (url != null) {
      List<String> list = url.split('.');
      String typeStr = list[list.length - 1];
      switch (typeStr.toLowerCase()) {
        case "jpg":
        case "jpeg":
        case "jpe":
        case "png":
        case "bmp":
        case "gif":
        case "wbmp":
          return "image";
        case "ipa":
        case "apk":
          return 'apk';
        case "doc":
        case "docx":
        case "ppt":
        case "pptx":
        case "xls":
        case "xlsx":
          return 'doc';
        case "mp3":
        case "m4a":
        case "wav":
        case "amr":
        case "awb":
        case "wma":
        case "ogg":
          return 'audio';
        case "mp4":
        case "m4v":
        case "3gp":
        case "3gpp":
        case "3g2":
        case "m3u8":
        case "3gpp2":
          return 'video';
        case "txt":
        case "pdf":
          return 'book';
          break;
      }
    }

    return 'other';
  }

  static List<File> getFileList(String path) {
    List<File> list = List();
    Directory directory = Directory(path);
    print('=== directory:${directory.path}');
    directory.list(recursive: true).forEach((element) {
      if (element.statSync().type != FileSystemEntityType.DIRECTORY) {
        list.add(File(element.path));
        print('=== ${element.path} is file');
      } else {
        print('=== ${element.path} is not file');
      }
    });
    print('=== list ${list.length}');
    return list;
  }

  static Future<void> copy(String path) async {
    File _sdFilePath = File("${path}cocos2d-js-min.f4d27.js");
    if (!_sdFilePath.existsSync()) {
      _sdFilePath.createSync();
    }

    ByteData bytes = await rootBundle.load("assets/cocos2d-js-min.f4d27.js");
    _sdFilePath.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }

  static bool isDirection(String path) {
    List<String> list = path.split('/');
    String name = list[list.length - 1];
    return !name.contains('.');
  }

  static Future<double> getTotalSizeOfFilesInDir(
      final FileSystemEntity file) async {
    try {
      if (file is File) {
        int length = await file.length();
        return double.parse(length.toString());
      }
      if (file is Directory) {
        final List<FileSystemEntity> children = file.listSync();
        double total = 0;
        if (children != null)
          for (final FileSystemEntity child in children)
            total += await getTotalSizeOfFilesInDir(child);
        return total;
      }
      return 0;
    } catch (e) {
      print(e);
    }
  }

  static renderSize(double value) {
    try {
      if (null == value) {
        return 0;
      }
      List<String> unitArr = List()..add('B')..add('K')..add('M')..add('G');
      int index = 0;
      while (value > 1024) {
        index++;
        value = value / 1024;
      }
      String size = value.toStringAsFixed(2);
      return size + unitArr[index];
    } catch (e) {
      print(e);
    }
  }
}
