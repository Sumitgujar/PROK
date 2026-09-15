
import "package:flutter/material.dart";
import "package:prok_mobile/models/course_model.dart";
import "package:prok_mobile/services/api_service.dart";
import "package:prok_mobile/providers/attendance_provider.dart";

class CourseProvider extends ChangeNotifier {
  List<CourseModel> _courses = [];
  List<EnrollmentModel> _enrollments = [];
  StudentProfile? _profile;
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<CourseModel> get courses => _courses;
  List<EnrollmentModel> get enrollments => _enrollments;
  StudentProfile? get profile => _profile;
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  final _api = ApiService();

  Future<void> loadCourses() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/courses/");
      _courses = (data as List).map((e) => CourseModel.fromJson(e)).toList();
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> loadEnrolled() async {
    try {
      final data = await _api.get("/courses/my-enrollments");
      _enrollments = (data as List).map((e) => EnrollmentModel.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadProfile() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/courses/profile");
      if (data != null) _profile = StudentProfile.fromJson(data);
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString(); }
    notifyListeners();
  }

  Future<void> enroll(String courseId) async {
    await _api.post("/courses/enroll", {"course_id": courseId});
    await loadEnrolled();
  }
}
