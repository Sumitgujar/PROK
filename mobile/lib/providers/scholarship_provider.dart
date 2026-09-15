
import "package:flutter/material.dart";
import "package:prok_mobile/models/scholarship_model.dart";
import "package:prok_mobile/services/api_service.dart";
import "package:prok_mobile/providers/attendance_provider.dart";

class ScholarshipProvider extends ChangeNotifier {
  List<ScholarshipModel> _scholarships = [];
  List<ApplicationModel> _applications = [];
  Set<String> _appliedIds = {};
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<ScholarshipModel> get scholarships => _scholarships;
  List<ApplicationModel> get applications => _applications;
  Set<String> get appliedIds => _appliedIds;
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  final _api = ApiService();

  Future<void> load() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final [s, a] = await Future.wait([
        _api.get("/scholarships/"),
        _api.get("/scholarships/my-applications"),
      ]);
      _scholarships = (s as List).map((e) => ScholarshipModel.fromJson(e)).toList();
      _applications = (a as List).map((e) => ApplicationModel.fromJson(e)).toList();
      _appliedIds = {for (var app in _applications) app.scholarshipId};
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> apply(String scholarshipId) async {
    await _api.post("/scholarships/apply", {"scholarship_id": scholarshipId});
    await load();
  }
}
