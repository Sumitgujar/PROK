
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:prok_mobile/core/constants.dart";

class ApiService {
  static const _tokenKey = "prok_token";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{"Content-Type": "application/json"};
    if (auth) {
      final token = await getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    }
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    final detail = body is Map ? (body["detail"] ?? res.reasonPhrase) : res.reasonPhrase;
    throw Exception(detail.toString());
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}$path"), headers: await _headers());
    return _parse(res);
  }

  Future<dynamic> post(String path, dynamic body, {bool auth = true}) async {
    final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: await _headers(auth: auth),
        body: jsonEncode(body));
    return _parse(res);
  }

  Future<dynamic> put(String path, dynamic body) async {
    final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: await _headers(),
        body: jsonEncode(body));
    return _parse(res);
  }

  Future<dynamic> uploadFile(String path, String filePath,
      Map<String, String> fields) async {
    final token = await getToken();
    final request = http.MultipartRequest(
        "POST", Uri.parse("${ApiConfig.baseUrl}$path"));
    if (token != null) request.headers["Authorization"] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath("file", filePath));
    request.fields.addAll(fields);
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }
}
