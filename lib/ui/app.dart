import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:frc_district_rank/ui/settings.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

import '../constants.dart';
import 'district_rank.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<String>>(
        valueListenable: Hive.box<String>(ProjectConstants.settingsBoxKey)
            .listenable(keys: [ProjectConstants.darkModeStorageKey]),
        builder: (context, box, widget) {
          bool? darkMode;
          switch (box.get('darkMode', defaultValue: 'unset')) {
            case 'true':
              darkMode = true;
              break;
            case 'false':
              darkMode = false;
              break;
            case 'unset':
              darkMode = null;
              break;
            default:
              throw UnimplementedError(
                  'Didn\'t find parsable type for dark mode!');
          }
          return MaterialApp(
            title: 'FRC District Ranking',
            initialRoute: '/',
            routes: {
              '/': (context) => const DistrictRankScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blueGrey, brightness: Brightness.light)),
            darkTheme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blueGrey, brightness: Brightness.dark)),
            themeMode: (darkMode ??
                    SchedulerBinding.instance.window.platformBrightness ==
                        Brightness.dark)
                ? ThemeMode.dark
                : ThemeMode.light,
          );
        });
  }
}
