import 'dart:convert';

abstract class Model<T> {
  T fromJsonMap(Map<String, dynamic> map);

  T fromJson(jsonStr) =>
      fromJsonMap(jsonStr is String ? json.decode(jsonStr) : jsonStr);

  Map<String, dynamic> toJson();

  String toString() => json.encode(this);

  static transformFromJson<T>(data, Model<T> fromJson(item)) {
    if (data is List) {
      return data.map((item) => fromJson(item)).toList();
    }
    return fromJson(data);
  }
}
