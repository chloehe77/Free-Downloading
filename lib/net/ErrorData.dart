import 'dart:convert' as dartConvert;
import 'Model.dart';

class ErrorData extends Model<ErrorData> {
  int status;
  String msg;
  dynamic data;

  String key;

  ErrorData({
    int status,
    String msg,
    String key,
    String data,
  }) {
    this.msg = msg;
    this.status = status;
    this.key = key;
    this.data = data;
  }

  ErrorData.fromJson(Map<String, dynamic> map) {
    if (map != null) {
      status = map['status'];
      msg = map['msg'];
      key = map['key'];
      data = map['data'];
    }
  }

  @override
  ErrorData fromJsonMap(Map<String, dynamic> map) {
    return ErrorData.fromJson(map);
  }

  @override
  String toString() {
    return dartConvert.json.encode(this);
  }

  @override
  Map<String, dynamic> toJson() => {
        'msg': msg,
        'status': status,
        'key': key,
        'data': data,
      };
}
