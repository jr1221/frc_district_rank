import 'package:flutter/material.dart';
import 'package:frc_district_rank/ui/app.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cache_manager.dart';
import 'constants.dart';

void main() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(ProjectConstants.settingsBoxKey),
    CacheManager.init()
  ]); // open settings box and fill HiveCacheManager in CacheManager, sync

  // await Hive.box<String>(ProjectConstants.settingsBoxKey).clear(); // clear settings, needed if settings keys change!

  runApp(const MyApp());
}

// Order: most stuff, styling, child, functions
