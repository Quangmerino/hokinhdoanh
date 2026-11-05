import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final base = ApiConstants.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final urlStr = '$base$path';

    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return Uri.parse(urlStr).replace(queryParameters: sanitizedParams);
    }
    return Uri.parse(urlStr);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'Không thể kết nối đến máy chủ backend. Vui lòng kiểm tra mạng hoặc khởi động backend.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Yêu cầu kết nối quá thời gian chờ (Timeout). Vui lòng thử lại.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'Không thể kết nối đến máy chủ backend. Vui lòng kiểm tra backend đang chạy.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .patch(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await http
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String errorMessage = 'Đã có lỗi xảy ra (${response.statusCode})';
    if (decoded is Map<String, dynamic>) {
      final msg = decoded['message'];
      if (msg is String) {
        errorMessage = msg;
      } else if (msg is List) {
        errorMessage = msg.join('\n');
      } else if (decoded['error'] is String) {
        errorMessage = decoded['error'];
      }
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
    );
  }
}
