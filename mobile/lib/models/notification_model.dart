
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String ntype;
  final bool isRead;
  final String createdAt;

  NotificationModel({required this.id, required this.title,
      required this.message, required this.ntype,
      required this.isRead, required this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
      id: j["_id"] ?? "",
      title: j["title"] ?? "",
      message: j["message"] ?? "",
      ntype: j["ntype"] ?? "general",
      isRead: j["is_read"] ?? false,
      createdAt: j["created_at"] ?? "");
}
