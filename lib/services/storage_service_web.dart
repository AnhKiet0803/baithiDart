// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'storage_service.dart';

class WebStorageService implements StorageService {
  static const String _storageKey = 'order_json_data';

  @override
  Future<String?> loadOrderJson() async {
    try {
      return html.window.localStorage[_storageKey];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveOrderJson(String jsonString) async {
    try {
      html.window.localStorage[_storageKey] = jsonString;
    } catch (_) {}
  }

  @override
  Future<void> downloadOrExportJson(String jsonString, String filename) async {
    try {
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }
}

StorageService getPlatformStorageService() => WebStorageService();
