
class ScholarshipModel {
  final String id;
  final String name;
  final String provider;
  final double amount;
  final String currency;
  final String description;
  final String eligibility;
  final List<String> requiredDocTypes;
  final String? deadline;
  final double? minCgpa;

  ScholarshipModel({required this.id, required this.name, required this.provider,
      required this.amount, required this.currency, required this.description,
      required this.eligibility, required this.requiredDocTypes,
      this.deadline, this.minCgpa});

  factory ScholarshipModel.fromJson(Map<String, dynamic> j) => ScholarshipModel(
      id: j["_id"] ?? "",
      name: j["name"] ?? "",
      provider: j["provider"] ?? "",
      amount: (j["amount"] ?? 0).toDouble(),
      currency: j["currency"] ?? "USD",
      description: j["description"] ?? "",
      eligibility: j["eligibility"] ?? "",
      requiredDocTypes: List<String>.from(j["required_doc_types"] ?? []),
      deadline: j["deadline"],
      minCgpa: j["min_cgpa"]?.toDouble());
}

class ApplicationModel {
  final String id;
  final String scholarshipId;
  final String scholarshipName;
  final String status;
  final String appliedAt;
  final String? reviewNote;
  final List<String> missingDocs;

  ApplicationModel({required this.id, required this.scholarshipId,
      required this.scholarshipName, required this.status,
      required this.appliedAt, this.reviewNote, required this.missingDocs});

  factory ApplicationModel.fromJson(Map<String, dynamic> j) => ApplicationModel(
      id: j["_id"] ?? "",
      scholarshipId: j["scholarship_id"] ?? "",
      scholarshipName: j["scholarship_name"] ?? "",
      status: j["status"] ?? "pending",
      appliedAt: j["applied_at"] ?? "",
      reviewNote: j["review_note"],
      missingDocs: List<String>.from(j["missing_docs"] ?? []));
}
