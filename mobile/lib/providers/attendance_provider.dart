
import "package:flutter/material.dart";
import "package:prok_mobile/models/attendance_model.dart";
import "package:prok_mobile/services/api_service.dart";

enum ProviderState { initial, loading, loaded, error }

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceSummary> _summary = [];
  List<Map<String, dynamic>> _teacherCourses = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _courseHistory = [];
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<AttendanceSummary> get summary => _summary;
  List<Map<String, dynamic>> get teacherCourses => _teacherCourses;
  List<Map<String, dynamic>> get enrolledStudents => _enrolledStudents;
  List<Map<String, dynamic>> get courseHistory => _courseHistory;
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  final _api = ApiService();

  Future<void> loadSummary() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/attendance/student/summary");
      _summary = (data as List).map((e) => AttendanceSummary.fromJson(e)).toList();
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> loadTeacherCourses() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/attendance/teacher/courses");
      _teacherCourses = List<Map<String, dynamic>>.from(data);
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> loadEnrolledStudents(String courseId) async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/attendance/courses/$courseId/students");
      _enrolledStudents = List<Map<String, dynamic>>.from(data);
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> loadCourseHistory(String courseId) async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/attendance/courses/$courseId/history");
      _courseHistory = List<Map<String, dynamic>>.from(data);
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> submitAttendance({required String courseId, required List<Map<String, dynamic>> records}) async {
    await _api.post("/attendance/mark", {"course_id": courseId, "records": records});
  }
}
