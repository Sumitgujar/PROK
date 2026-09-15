
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:prok_mobile/models/user_model.dart";
import "package:prok_mobile/services/api_service.dart";

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  final _api = ApiService();
  static const _tokenKey = "prok_token";
  static const _userKey = "prok_user_role";

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;
    try {
      final data = await _api.get("/auth/me");
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.post("/auth/login",
          {"email": email, "password": password}, auth: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data["access_token"]);
      _user = UserModel.fromJson(data["user"]);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _user = null;
    notifyListeners();
  }
}
