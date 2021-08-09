import 'package:frc_district_rank/constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';
import 'package:workmanager/workmanager.dart';

import 'api_mgr.dart';
import 'main.dart';

Future<void> notifCreate() async {
  String districtKey = '';
  int prevRank = -1;
  try {
    final response = await ApiMgr.api.getDistrictApi().getTeamDistricts(
        teamKey: 'frc${GetStorage().read(Constants.teamNotifStorageKey)}');
    if (response.data!.isNotEmpty) {
      bool done = false;
      for (DistrictList element in response.data!) {
        if (element.year == Constants.defaultYear) {
          districtKey = element.key;
          done = true;
        }
      }
      if (!done) {
        throw {
          'Team ${GetStorage().read(Constants.teamNotifStorageKey)} may not have competed in ${Constants.defaultYear}.'
        };
      }
    } else {
      throw 'No Districts for ${GetStorage().read(Constants.teamNotifStorageKey)}';
    }
  } catch (e) {
    if (e is Set && e.first is int && e.first == 3) {
      throw '${e.elementAt(1)}';
    }
    rethrow;
  }

  final rankings = await ApiMgr.api
      .getDistrictApi()
      .getDistrictRankings(districtKey: districtKey)
      .then((value) => value.data!.asList());
  for (DistrictRanking element in rankings) {
    if (element.teamKey ==
        'frc${GetStorage().read(Constants.teamNotifStorageKey)}') {
      prevRank = element.rank;
      break;
    }
  }

  GetStorage().write(Constants.prevRankNotifStorageKey, prevRank);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().cancelAll();
  Workmanager().registerPeriodicTask(
    "1",
    "simpleTask",
    existingWorkPolicy: ExistingWorkPolicy.replace,
    initialDelay: const Duration(seconds: 4),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    inputData: <String, dynamic>{
      'team': GetStorage().read(Constants.teamNotifStorageKey),
      'year': Constants.defaultYear,
      'districtKey': districtKey,
    },
  );
  GetStorage().write(Constants.shoudNotifStorageKey, true);
}
