import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_io.dart'
    if (dart.library.html) 'storage_service_web.dart';

abstract class StorageService {
  Future<String?> loadOrderJson();
  Future<void> saveOrderJson(String jsonString);
  Future<void> downloadOrExportJson(String jsonString, String filename);
}

StorageService createStorageService() => getPlatformStorageService();
