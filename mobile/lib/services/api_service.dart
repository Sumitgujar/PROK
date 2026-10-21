import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prok_mobile/core/constants.dart';

class ApiService {
  static const _tokenKey = 'prok_token';
  static const _timeout = Duration(seconds: 20);
  static const _maxRetries = 2;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _parse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
    } else {
      body = <String, dynamic>{};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception('You do not have permission to perform this action.');
    }
    final detail = body is Map
        ? (body['detail'] ?? body['message'] ?? response.reasonPhrase)
        : (body is String && body.isNotEmpty ? body : response.reasonPhrase);
    throw Exception(detail?.toString() ?? 'Request failed (\${response.statusCode}).');
  }

  bool _isRetryable(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is TimeoutException ||
      (error is Exception && error.toString().toLowerCase().contains('timeout'));

  Future<dynamic> get(String path, {int retries = _maxRetries}) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('\${ApiConfig.baseUrl}$path'),
              headers: await _headers(),
            )
            .timeout(_timeout);
        return _parse(response);
      } on Exception catch (error) {
        lastError = error;
        if (!_isRetryable(error) || attempt == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw Exception(lastError?.toString() ?? 'Request failed.');
  }

  Future<dynamic> post(
    String path,
    dynamic body, {
    bool auth = true,
    int retries = 0,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('\${ApiConfig.baseUrl}$path'),
              headers: await _headers(auth: auth),
              body: jsonEncode(body),
            )
            .timeout(_timeout);
        return _parse(response);
      } on Exception catch (error) {
        lastError = error;
        if (!_isRetryable(error) || attempt == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw Exception(lastError?.toString() ?? 'Request failed.');
  }

  Future<dynamic> put(String path, dynamic body) async {
    final response = await http
        .put(
          Uri.parse('\${ApiConfig.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final response = await http
        .patch(
          Uri.parse('\${ApiConfig.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }

  Future<dynamic> uploadFile(
    String path,
    String filePath,
    Map<String, String> fields,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('\${ApiConfig.baseUrl}$path'),
    );
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields.addAll(fields);
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed).timeout(_timeout);
    return _parse(response);
  }
}
