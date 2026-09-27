
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prok_mobile/core/constants.dart';

class ApiService {
  static const _tokenKey = 'prok_token';
  static const _timeout = Duration(seconds: 15);
  static const _maxRetries = 2;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer \$token';
    }
    return headers;
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    }
    if (res.statusCode == 401) throw Exception('Session expired. Please log in again.');
    if (res.statusCode == 403) throw Exception('You do not have permission for this action.');
    if (res.statusCode == 404) throw Exception('Not found.');
    final body = res.body.isNotEmpty ? (jsonDecode(res.body) as dynamic) : {};
    final detail = body is Map ? (body['detail'] ?? res.reasonPhrase) : res.reasonPhrase;
    throw Exception(detail.toString());
  }

  bool _isRetryable(dynamic e) =>
    e is SocketException || e is HttpException || e is Exception && e.toString().contains('timeout');

  Future<dynamic> get(String path, {int retries = _maxRetries}) async {
    Exception? last;
    for (int i = 0; i <= retries; i++) {
      try {
        final res = await http.get(
          Uri.parse('\${ApiConfig.baseUrl}\$path'),
          headers: await _headers(),
        ).timeout(_timeout);
        return _parse(res);
      } on Exception catch (e) {
        last = e;
        if (!_isRetryable(e) || i == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    throw last ?? Exception('Request failed');
  }

  Future<dynamic> post(String path, dynamic body, {bool auth = true, int retries = 0}) async {
    Exception? last;
    for (int i = 0; i <= retries; i++) {
      try {
        final res = await http.post(
          Uri.parse('\${ApiConfig.baseUrl}\$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        ).timeout(_timeout);
        return _parse(res);
      } on Exception catch (e) {
        last = e;
        if (!_isRetryable(e) || i == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    throw last ?? Exception('Request failed');
  }

  Future<dynamic> put(String path, dynamic body) async {
    final res = await http.put(
      Uri.parse('\${ApiConfig.baseUrl}\$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _parse(res);
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final res = await http.patch(
      Uri.parse('\${ApiConfig.baseUrl}\$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _parse(res);
  }

  Future<dynamic> uploadFile(String path, String filePath, Map<String, String> fields) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('\${ApiConfig.baseUrl}\$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer \$token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields.addAll(fields);
    final streamed = await request.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }
}
