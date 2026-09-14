import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = kApiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTokenKey);
  }

  Map<String, String> _headers({String? token, bool form = false}) => {
        'Content-Type': form
            ? 'application/x-www-form-urlencoded'
            : 'application/json',
        if (token != null) 'Authorization': 'Bearer \$token',
      };

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      final body = json.decode(res.body) as Map<String, dynamic>?;
      final msg = body?['detail']?.toString() ?? 'Request failed (\${res.statusCode})';
      throw ApiException(msg, statusCode: res.statusCode);
    }
  }

  // ---------- Health ----------
  Future<Map<String, dynamic>> health() async {
    final res = await http.get(Uri.parse('\$_base/health'));
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  // ---------- Auth ----------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = 'username=\${Uri.encodeComponent(email)}&password=\${Uri.encodeComponent(password)}';
    final res = await http.post(
      Uri.parse('\$_base/auth/login'),
      headers: _headers(form: true),
      body: body,
    );
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String? collegeId,
  }) async {
    final res = await http.post(
      Uri.parse('\$_base/auth/register'),
      headers: _headers(),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (collegeId != null) 'college_id': collegeId,
      }),
    );
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<UserModel> me() async {
    final token = await _getToken();
    if (token == null) throw ApiException('Not authenticated');
    final res = await http.get(
      Uri.parse('\$_base/auth/me'),
      headers: _headers(token: token),
    );
    _check(res);
    return UserModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }
}
