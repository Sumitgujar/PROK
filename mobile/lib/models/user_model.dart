
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String collegeId;

  UserModel({required this.id, required this.email,
      required this.fullName, required this.role, required this.collegeId});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
      id: j["_id"] ?? "",
      email: j["email"] ?? "",
      fullName: j["full_name"] ?? "",
      role: j["role"] ?? "",
      collegeId: j["college_id"] ?? "");
}
