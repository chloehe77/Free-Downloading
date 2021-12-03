import 'package:filemanager/tool/FileUtil.dart';
import 'package:flutter/material.dart';

class FileReaderPage extends StatefulWidget {
  final String filePath;

  FileReaderPage({Key: Key, this.filePath});

  @override
  _FileReaderPageState createState() => _FileReaderPageState();
}

class _FileReaderPageState extends State<FileReaderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FileUtil.getFileNameFromUrl(widget.filePath)),
      ),
      // body: FileReaderView(
      //   filePath: widget.filePath,
      // ),
    );
  }
}
