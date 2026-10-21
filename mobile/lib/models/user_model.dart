class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String collegeId;
  final String? department;
  final int? semester;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.collegeId,
    this.department,
    this.semester,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        collegeId: (json['college_id'] ?? '').toString(),
        department: json['department']?.toString(),
        semester: json['semester'] is num ? (json['semester'] as num).toInt() : null,
      );
}
