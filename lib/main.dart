import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frc_district_rank/district_rank.dart';
import 'package:frc_district_rank/settings.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'api_mgr.dart';
import 'constants.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    ApiMgr.init();
    await GetStorage().initStorage;

    int districtRank = -1;
    final rankings = await ApiMgr.api
        .getDistrictApi()
        .getDistrictRankings(districtKey: inputData!['districtKey'])
        .then((value) => value.data!.asList());
    for (DistrictRanking element in rankings) {
      if (element.teamKey == 'frc${inputData['team']}') {
        districtRank = element.rank;
        break;
      }
    }

    if (GetStorage().read(Constants.prevRankNotifStorageKey) != districtRank) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '1',
        'rank-change',
        'Notify of Rank Change',
        playSound: false,
        importance: Importance.max,
        priority: Priority.high,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        'Rank Change!',
        'Team ${inputData['team']} is now ranked $districtRank in ${inputData['districtKey'].toString().substring(4).toUpperCase()}',
        platformChannelSpecifics,
      );

      GetStorage().write(Constants.prevRankNotifStorageKey, districtRank);
    }

    return Future.value(true);
  });
}

void main() async {
  runApp(Phoenix(child: const ProviderScope(child: MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool?> get _getTheme async {
    await GetStorage().initStorage;
    return GetStorage().read(Constants.darkModeNotifStorageKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _getTheme,
      builder: (BuildContext context, AsyncSnapshot<bool?> snapshot) {
        return MaterialApp(
          title: 'FRC District Ranking',
          initialRoute: '/',
          routes: {
            '/': (context) => const DistrictRankWidget(),
            '/settings': (context) => const SettingsWidget(),
          },
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            brightness: Brightness.light,
            primaryColor: Colors.blueGrey,
          ),
          darkTheme: ThemeData(
            primaryColor: Colors.white,
            primaryColorBrightness: Brightness.dark,
            primaryColorLight: Colors.black,
            brightness: Brightness.dark,
            primaryColorDark: Colors.black,
            indicatorColor: Colors.white,
            canvasColor: Colors.black,
            accentColor: Colors.white,
            accentColorBrightness: Brightness.dark,
            dialogBackgroundColor: Colors.black,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                shape: const RoundedRectangleBorder(
                    side: BorderSide(width: 3.0, color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
              ),
            ),
            appBarTheme: const AppBarTheme(
                brightness: Brightness.dark, backgroundColor: Colors.black),
          ),
          themeMode: snapshot.data == null
              ? ThemeMode.system
              : snapshot.data!
                  ? ThemeMode.dark
                  : ThemeMode.light,
        );
      },
    );
  }
}
