import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frc_district_rank/ui/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(ProjectConstants.settingsBoxKey);
  if (!kIsWeb) {
    Hive.box<String>(ProjectConstants.settingsBoxKey).put(
        ProjectConstants.tempDirStorageKey,
        (await getTemporaryDirectory()).path);
  }
  //await Hive.box<String>(ProjectConstants.settingsBoxKey).clear(); // clear settings, needed if settings keys change!
  runApp(const MyApp());
}
