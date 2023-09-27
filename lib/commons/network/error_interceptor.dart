part of 'wpy_dio.dart';

class ErrorInterceptor extends InterceptorsWrapper {
  @override
  Future onError(DioException e, handler) async {
    if (e is WpyDioException) return handler.reject(e);

    var errStr = '';
    if (e.type == DioExceptionType.connectionTimeout)
      errStr = "网络连接超时";
    else if (e.type == DioExceptionType.sendTimeout)
      errStr = "发送请求超时";
    else if (e.type == DioExceptionType.receiveTimeout)
      errStr = "响应超时";

    /// 除了以上列出的错误之外，其他的所有错误给一个统一的名称，防止让用户看到奇奇怪怪的错误代码
    else if (!EnvConfig.isTest) errStr = "发生未知错误，请联系开发人员解决";

    return handler.reject(DioException(
        requestOptions: e.requestOptions,
        error: errStr,
        message: e.message,
        stackTrace: e.stackTrace));
  }
}

/// 办公网Error判定
class ClassesErrorInterceptor extends InterceptorsWrapper {
  @override
  Future onError(DioException e, handler) async {
    if (e is WpyDioException) return handler.reject(e);
    var errStr = '';
    if (e.type == DioExceptionType.badResponse) {
      switch (e.response?.statusCode) {
        case 500:
          errStr = "服务器发生了未知错误";
          break;
        case 401:
          if ((e.response?.data.toString().contains("验证码错误") ?? false) ||
              (e.response?.data.toString().contains("Mismatch") ?? false))
            errStr = "验证码输入错误";
          else
            errStr = "密码输入错误";
          break;
        case 302:
          errStr = "办公网绑定失效，请重新绑定";
          break;
      }
    }

    /// 除了以上列出的错误之外，其他的所有错误给一个统一的名称，防止让用户看到奇奇怪怪的错误代码
    else if (!EnvConfig.isTest) errStr = "发生未知错误，请联系开发人员解决";

    return handler.reject(DioException(
        requestOptions: e.requestOptions,
        error: errStr,
        message: e.message,
        stackTrace: e.stackTrace));
  }
}

class WpyDioException extends DioException {
  @override
  final String error;

  WpyDioException({required this.error, String path = 'unknown'})
      : super(requestOptions: RequestOptions(path: path));
}
