import 'dart:io';
import 'storage_service.dart';

class IoStorageService implements StorageService {
  final File _file = File('order.json');

  @override
  Future<String?> loadOrderJson() async {
    try {
      if (await _file.exists()) {
        return await _file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveOrderJson(String jsonString) async {
    try {
      await _file.writeAsString(jsonString);
    } catch (_) {}
  }

  @override
  Future<void> downloadOrExportJson(String jsonString, String filename) async {
    await saveOrderJson(jsonString);
  }
}

StorageService getPlatformStorageService() => IoStorageService();
