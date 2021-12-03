import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DioDownDataClass {

  Future downloadWithChunks(url, savePath,
      {ProgressCallback onReceivedProgress, CancelToken cancelToken}) async {

    const firstChunkSize = 99999999;

    const maxChunk = 1;

    int total = 0;
    int start = 0;
    //
    var dio = Dio();

    var progress = <int>[];
    File file = File(savePath);
    if (file.existsSync()) {
      start = file.lengthSync();
    }

    createCallback(no) {
      return (int received, _) {
        progress[no] = received;
        print('onReceivedProgress:${progress[no]} total:${total}');
        if (onReceivedProgress != null && total != 0) {
          onReceivedProgress(progress[no], total);
        }
      };
    }


    Future<Response> downloadChunk(url, start, end, nomber) {
      progress.add(0);
      --end;
      return dio.download(url, savePath + "temp$nomber",
          onReceiveProgress: createCallback(nomber),
          cancelToken: cancelToken,
          options: Options(
            headers: {"range": "byte=$start-$end"},
          ));
    }

    Future mergeTempFiles(chunk) async {
      File f = File(savePath + "temp0");
      IOSink ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);

      for (int i = 1; i < chunk; i++) {
        File _f = File(savePath + "temp$i");
        await ioSink.addStream(_f.openRead());
        await _f.delete();
      }
      await ioSink.close();
      await f.rename(savePath);
    }

    Response response = await downloadChunk(url, start, firstChunkSize, 0);
    if (response.statusCode == 200) {

      total = int.parse(response.headers
          .value(HttpHeaders.contentRangeHeader)
          .split("/")
          .last);
      print('=== total:${total}');
      int reserved = total -
          int.parse(response.headers.value(HttpHeaders.contentLengthHeader));
      int chunk = (reserved / firstChunkSize).ceil() + 1; //分成多少段
      if (chunk > 1) {
        int chunkSize = firstChunkSize;
        if (chunk > maxChunk + 1) {

          chunk = maxChunk + 1;

          chunkSize = (reserved / maxChunk).ceil();
        }
        var futures = <Future>[];
        for (var i = 0; i < maxChunk; i++) {

          int start = firstChunkSize + i * chunkSize;

          futures.add(downloadChunk(url, start, start + chunkSize, i + 1));
        }

        await Future.wait(futures);
      }

      await mergeTempFiles(chunk);
    }
  }
}
