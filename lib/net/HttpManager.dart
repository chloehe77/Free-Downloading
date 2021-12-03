import 'dart:io';

import 'package:dio/dio.dart';
import 'package:filemanager/tool/SharedUtil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../EnvironmentConfig.dart';
import 'DioDownDataClass.dart';
import 'ErrorData.dart';

class HttpManager {
  static HttpManager _instance = HttpManager._internal();
  Dio _dio;
  DioDownDataClass dioDownDataClass;

  static const CODE_SUCCESS = 200;
  static const CODE_TIME_OUT = -1;

  factory HttpManager() => _instance;


  HttpManager._internal({String baseUrl}) {
    if (null == _dio) {
      _dio = new Dio(new BaseOptions(
          baseUrl: EnvironmentConfig.baseURL, connectTimeout: 60000));

      dioDownDataClass = DioDownDataClass();
    }
  }

  static HttpManager getInstance({String baseUrl, ResponseType responseType}) {
    if (baseUrl == null) {
      return _instance._normal(responseType: responseType);
    } else {
      return _instance._baseUrl(baseUrl);
    }
  }

  HttpManager _baseUrl(String baseUrl) {
    if (_dio != null) {
      _dio.options.baseUrl = baseUrl;
      String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
      _dio.options.headers = {
        HttpHeaders.authorizationHeader: token,
        HttpHeaders.contentTypeHeader: "application/json; charset=utf-8",
      };
    }
    return this;
  }

  HttpManager _normal({ResponseType responseType}) {
    if (_dio != null) {
      if (_dio.options.baseUrl != EnvironmentConfig.baseURL) {
        _dio.options.baseUrl = EnvironmentConfig.baseURL;
      }
      if (responseType != null) {
        _dio.options.responseType = responseType;
      } else {
        _dio.options.responseType = ResponseType.json;
      }

      String token = SharedUtil.getString(SharedUtil.SP_LOGIN_TOKEN);
      _dio.options.headers = {
        HttpHeaders.authorizationHeader: token,
        HttpHeaders.contentTypeHeader: "application/json; charset=utf-8",
      };
    }
    return this;
  }

  Future<Response<T>> request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    Options options,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
    Function(ErrorData) errorCallBack,
    Function(Response<T>) successCallBack,
  }) async {
    //EasyLoading.show();
    Response response = await _dio.request(path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
    //EasyLoading.dismiss();

    if (response.statusCode == 200) {
      if (successCallBack != null) {
        successCallBack(response);
      }
    } else {
      ErrorData errorData = ErrorData.fromJson(response.data);
      if (errorCallBack != null) {
        errorCallBack(errorData);
      }
    }
    return response;
  }

  get(api, {params, withLoading = true}) async {
    if (withLoading) {
      //EasyLoading.show();
    }

    Response response;
    try {
      response = await _dio.get(api, queryParameters: params);
      if (withLoading) {
        //EasyLoading.dismiss();
      }
    } on DioError catch (e) {
      if (withLoading) {
        //EasyLoading.dismiss();
      }
      // return resultError(e);
    }
    return response.data;
  }

  post<T>(api, {params, withLoading = true}) async {
    if (withLoading) {
      //EasyLoading.show();
    }
    Response response;
    try {
      response = await _dio.post(api, data: params);
      if (withLoading) {
        //EasyLoading.dismiss();
      }
    } on DioError catch (e) {
      if (withLoading) {
        //EasyLoading.dismiss();
      }
      // return resultError(e);
    }

    if (response.data is DioError) {
      // return resultError(response.data['code']);
    }

    return response.data;
  }

  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback onReceiveProgress,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options options,
  }) async {
    Options op;
    File file = File(savePath);
    int start = 0;
    int end = 99999999;
    if (file.existsSync()) {
      start = file.lengthSync();
      print('=== start:${start}');
      op = Options(

        headers: {"range": "byte=$start-$end"},
      );
    }
    Response response = await _dio.download(urlPath, savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: op == null ? options : op);
    return response;
  }

  Future<Response> download2(
    String urlPath,
    savePath, {
    ProgressCallback onReceiveProgress,
    CancelToken cancelToken,
  }) async {
    Response response = await dioDownDataClass.downloadWithChunks(
        urlPath, savePath,
        onReceivedProgress: onReceiveProgress);
    return response;
  }

  Future<Response> upload(
    String urlPath,
    FormData formData,
  ) async {
    Response response = await _dio.post(urlPath, data: formData);
    return response;
  }
}
