
import "package:flutter/material.dart";
import "package:prok_mobile/models/notification_model.dart";
import "package:prok_mobile/services/api_service.dart";
import "package:prok_mobile/providers/attendance_provider.dart";

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  final _api = ApiService();

  Future<void> loadNotifications() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/notifications/");
      _notifications = (data as List).map((e) => NotificationModel.fromJson(e)).toList();
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _api.post("/notifications/$id/read", {});
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = NotificationModel(
          id: _notifications[idx].id, title: _notifications[idx].title,
          message: _notifications[idx].message, ntype: _notifications[idx].ntype,
          isRead: true, createdAt: _notifications[idx].createdAt);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _api.post("/notifications/mark-all-read", {});
    _notifications = _notifications.map((n) => NotificationModel(
        id: n.id, title: n.title, message: n.message,
        ntype: n.ntype, isRead: true, createdAt: n.createdAt)).toList();
    notifyListeners();
  }
}
