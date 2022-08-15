import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

class CacheManager {
  static HiveCacheStore? hiveCacheStore;

  /// initialize [hiveCacheStore] with getTemporaryDirectory() + [ProjectConstants.tempDirFolderAppend] except null on web
  static Future<HiveCacheStore> init() async {
    if (kIsWeb) {
      return hiveCacheStore = HiveCacheStore(null);
    } else {
      return hiveCacheStore = HiveCacheStore(
          '${(await getTemporaryDirectory()).path}${ProjectConstants.tempDirFolderAppend}');
    }
  }
}
