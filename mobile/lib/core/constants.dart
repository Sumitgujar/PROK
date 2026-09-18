
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
      "API_BASE_URL", defaultValue: "http://10.0.2.2:8000");
}

class AppRoutes {
  static const String splash = "/";
  static const String login = "/login";
  static const String studentHome = "/student/home";
  static const String studentAskProk = "/student/ask-prok";
  static const String studentAttendance = "/student/attendance";
  static const String studentDocuments = "/student/documents";
  static const String studentScholarships = "/student/scholarships";
  static const String studentCourses = "/student/courses";
  static const String studentNotifications = "/student/notifications";
  static const String studentProfile = "/student/profile";
  static const String teacherHome = "/teacher/home";
  static const String teacherMarkAttendance = "/teacher/mark-attendance";
  static const String teacherAttendanceHistory = "/teacher/attendance-history";
  static const String teacherClassDetails = "/teacher/class-details";
}
