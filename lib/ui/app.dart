import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:frc_district_rank/ui/settings.dart';
import 'package:hive_flutter/adapters.dart';

import '../constants.dart';
import 'district_rank.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<String>>(
      valueListenable: Hive.box<String>(ProjectConstants
              .settingsBoxKey) // Listen to darkMode and colorScheme hive changes
          .listenable(
        keys: [
          ProjectConstants.darkModeStorageKey,
          ProjectConstants.colorSchemeStorageKey,
        ],
      ),
      builder: (
        context,
        box,
        widget,
      ) {
        bool? darkMode;
        switch (box.get(
          ProjectConstants.darkModeStorageKey,
          defaultValue: 'unset',
        )) {
          case 'true': // darkMode ON
            darkMode = true;
            break;
          case 'false': // darkMode OFF
            darkMode = false;
            break;
          case 'unset': // darkMode platform preference
            darkMode = null;
            break;
          default: // Shouldn't reach
            throw UnimplementedError(
                'Didn\'t find parsable type for dark mode!');
        }

        // If no colorScheme in hive, put blueGrey as default
        if (box.get(ProjectConstants.colorSchemeStorageKey) == null) {
          box.put(
            ProjectConstants.colorSchemeStorageKey,
            Colors.blueGrey.value.toString(),
          );
        }

        // get colorScheme color from hive, default to blueGrey (shouldn't need)
        final colorSchemeColor = Color(
          int.parse(box.get(
            ProjectConstants.colorSchemeStorageKey,
            defaultValue: Colors.blueGrey.value.toString(),
          )!),
        );

        return MaterialApp(
          title: 'FRC District Ranking',
          initialRoute: '/',
          routes: {
            '/': (context) => const DistrictRankScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
          builder: BotToastInit(),
          theme: ThemeData.from(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorSchemeColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData.from(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorSchemeColor,
              brightness: Brightness.dark,
            ),
          ),
          // darkMode ON or OFF if manually set, else use platform mode
          themeMode: (darkMode ??
                  View.of(context).platformDispatcher.platformBrightness ==
                      Brightness.dark)
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      },
    );
  }
}
