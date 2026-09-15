
class DocumentModel {
  final String id;
  final String title;
  final String docType;
  final String status;
  final String fileUrl;
  final String uploadedAt;
  final String? reviewNote;

  DocumentModel({required this.id, required this.title, required this.docType,
      required this.status, required this.fileUrl,
      required this.uploadedAt, this.reviewNote});

  factory DocumentModel.fromJson(Map<String, dynamic> j) => DocumentModel(
      id: j["_id"] ?? "",
      title: j["title"] ?? "",
      docType: j["doc_type"] ?? "",
      status: j["status"] ?? "UNDER_REVIEW",
      fileUrl: j["file_url"] ?? "",
      uploadedAt: j["uploaded_at"] ?? "",
      reviewNote: j["review_note"]);
}
