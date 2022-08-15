import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:frc_district_rank/ui/settings.dart';
import 'package:frc_district_rank/ui/theme_selection.dart';
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
            .listenable(keys: [
          ProjectConstants.darkModeStorageKey,
          ProjectConstants.colorSchemeStorageKey
        ]),
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

          final accentColor = Color(int.parse(box.get(
              ProjectConstants.colorSchemeStorageKey,
              defaultValue: Colors.blueGrey.value.toString())!));

          return MaterialApp(
            title: 'FRC District Ranking',
            initialRoute: '/',
            routes: {
              '/': (context) => const DistrictRankScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/settings/theme': (context) => const ThemeSelectionScreen()
            },
            builder: BotToastInit(),
            theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: accentColor, brightness: Brightness.light)),
            darkTheme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: accentColor, brightness: Brightness.dark)),
            themeMode: (darkMode ??
                    SchedulerBinding.instance.window.platformBrightness ==
                        Brightness.dark)
                ? ThemeMode.dark
                : ThemeMode.light,
          );
        });
  }
}
