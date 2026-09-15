
class AttendanceSummary {
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final int totalSessions;
  final int present;
  final int percentage;

  AttendanceSummary({required this.courseId, required this.courseCode,
      required this.courseTitle, required this.totalSessions,
      required this.present, required this.percentage});

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) => AttendanceSummary(
      courseId: j["course_id"] ?? "",
      courseCode: j["course_code"] ?? "",
      courseTitle: j["course_title"] ?? "",
      totalSessions: j["total_sessions"] ?? 0,
      present: j["present"] ?? 0,
      percentage: j["percentage"] ?? 0);
}
