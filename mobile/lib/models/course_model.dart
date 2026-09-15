
class CourseModel {
  final String id;
  final String title;
  final String courseCode;
  final String department;
  final int credits;
  final String teacherName;
  final List<String> tags;

  CourseModel({required this.id, required this.title, required this.courseCode,
      required this.department, required this.credits,
      required this.teacherName, required this.tags});

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
      id: j["_id"] ?? "",
      title: j["title"] ?? "",
      courseCode: j["course_code"] ?? "",
      department: j["department"] ?? "",
      credits: j["credits"] ?? 3,
      teacherName: j["teacher_name"] ?? "TBA",
      tags: List<String>.from(j["tags"] ?? []));
}

class EnrollmentModel {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String status;

  EnrollmentModel({required this.id, required this.courseId,
      required this.courseCode, required this.courseTitle, required this.status});

  factory EnrollmentModel.fromJson(Map<String, dynamic> j) => EnrollmentModel(
      id: j["_id"] ?? "",
      courseId: j["course_id"] ?? "",
      courseCode: j["course_code"] ?? "",
      courseTitle: j["course_title"] ?? "",
      status: j["status"] ?? "active");
}

class StudentProfile {
  final String department;
  final int semester;
  final int year;
  final double? cgpa;
  final List<String> skills;
  final List<String> interests;
  final List<String> careerGoals;

  StudentProfile({required this.department, required this.semester,
      required this.year, this.cgpa, required this.skills,
      required this.interests, required this.careerGoals});

  factory StudentProfile.fromJson(Map<String, dynamic> j) => StudentProfile(
      department: j["department"] ?? "",
      semester: j["semester"] ?? 1,
      year: j["year"] ?? 1,
      cgpa: j["cgpa"]?.toDouble(),
      skills: List<String>.from(j["skills"] ?? []),
      interests: List<String>.from(j["interests"] ?? []),
      careerGoals: List<String>.from(j["career_goals"] ?? []));
}
