
import "package:flutter/material.dart";
import "package:prok_mobile/models/document_model.dart";
import "package:prok_mobile/services/api_service.dart";
import "package:prok_mobile/providers/attendance_provider.dart";

class DocumentProvider extends ChangeNotifier {
  List<DocumentModel> _docs = [];
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<DocumentModel> get docs => _docs;
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  final _api = ApiService();

  Future<void> loadDocuments() async {
    _state = ProviderState.loading; notifyListeners();
    try {
      final data = await _api.get("/documents/my");
      _docs = (data as List).map((e) => DocumentModel.fromJson(e)).toList();
      _state = ProviderState.loaded;
    } catch (e) { _state = ProviderState.error; _error = e.toString().replaceAll("Exception: ", ""); }
    notifyListeners();
  }

  Future<void> uploadDocument({required String filePath, required String docType,
      required String title, String description = ""}) async {
    await _api.uploadFile("/documents/upload", filePath,
        {"doc_type": docType, "title": title, "description": description});
    await loadDocuments();
  }
}
