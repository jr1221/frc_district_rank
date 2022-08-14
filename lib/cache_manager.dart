import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';

class CacheManager {
  static HiveCacheStore? hiveCacheStore;

  static HiveCacheStore init(String? path) {
    return hiveCacheStore = HiveCacheStore(path);
  }
}
