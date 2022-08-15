import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frc_district_rank/ui/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'cache_manager.dart';
import 'constants.dart';

void main() async {
  await Hive.initFlutter();
  final box = await Hive.openBox<String>(ProjectConstants.settingsBoxKey);
  box.put(ProjectConstants.colorSchemeStorageKey,
      Colors.redAccent.value.toString());
  if (!kIsWeb) {
    CacheManager.init(
        '${(await getTemporaryDirectory()).path}${ProjectConstants.tempDirFolderAppend}');
  } else {
    CacheManager.init(null);
  }
  //await Hive.box<String>(ProjectConstants.settingsBoxKey).clear(); // clear settings, needed if settings keys change!
  runApp(const MyApp());
}
