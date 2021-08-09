import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_mgr.dart';
import 'constants.dart';

Future<void> onOpen(LinkableElement link) async {
  if (await canLaunch(link.url)) {
    await launch(link.url);
  } else {
    throw 'Could not launch ${link.url}';
  }
}

Future<List<int>> _getKeys() async {
  int? team = GetStorage().read('team');
  int? year = GetStorage().read('year');
  if (team != null && year != null) {
    return [team, year];
  } else {
    return [-1, -1];
  }
}

Future<void> _init() async {
  ApiMgr.init();
  await GetStorage().initStorage;
}

Future<void> _fillKeys(int team, int year) async {
  GetStorage().write('team', team);
  GetStorage().write('year', year);
}

final teamProv = StateProvider<int>((_) => -1);
final yearProv = StateProvider<int>((_) => -1);

final prevTeamProv = StateProvider<int>((_) => -1);
final prevYearProv = StateProvider<int>((_) => -1);

final dataProv = FutureProvider.autoDispose<DataModel>((ref) async {
  int team = ref.read(teamProv).state;
  int year = ref.read(yearProv).state;

  if (team == -1 || year == -1) {
    await _init();
    await _getKeys().then((value) {
      team = (team != -1)
          ? team
          : (value.first != -1 ? value.first : Constants.defaultTeam);
      year = (year != -1)
          ? year
          : (value.last != -1 ? value.last : Constants.defaultYear);
    });
  }

  DataModel model = DataModel(team, year);

  try {
    Future<void> districtKeyGet = model.getDistrictKey();
    Iterable<Future> futures = <Future>[
      model.getTeamAbout(),
      model.getTeamAwards(),
      model.getTeamAvatar(),
    ];
    await districtKeyGet;
    Future<void> districtRankingsGet = model.getDistrictRankings();
    await Future.wait(futures);
    await districtRankingsGet;
  } on DioError {
    rethrow;
  } catch (e) {
    rethrow;
  }

  ref.read(prevTeamProv).state = team;
  ref.read(prevYearProv).state = year;

  _fillKeys(team, year);

  return model;
});

class DataModel {
  static const avatarW = 40;
  static const avatarH = 60;

  late int team;
  late int year;

  int districtRank = -1;
  String districtKey = '';
  List<Award> awards = [];
  List<DistrictRanking> rankings = [];
  String baseAvatar = '';
  Team? teamObj;

  List<String> yearsRanked = [];

  DataModel(this.team, this.year);

  /*
  Uses - team
  Fills - yearsRanked, districtKey
   */
  Future<void> getDistrictKey() async {
    try {
      final response = await ApiMgr.api
          .getDistrictApi()
          .getTeamDistricts(teamKey: 'frc$team');
      if (response.data!.isNotEmpty) {
        yearsRanked.clear();
        bool done = false;
        for (DistrictList element in response.data!) {
          yearsRanked.add(element.year.toString());
          if (element.year == year) {
            districtKey = element.key;
            done = true;
          }
        }
        if (!done) {
          int failedYear = year;
          year = response.data!.last.year;
          throw {'Team $team may not have competed in $failedYear.'};
        }
      } else {
        throw 'No Districts for $team';
      }
    } on DioError catch (e) {
      if (e.response == null) {
        throw 'Cannot connect to server.  Check your internet connection!';
      }
      if (e.response!.statusCode != null && e.response!.statusCode == 404) {
        throw e.response.toString();
      } // Choose team, team doesnt exist
      throw e.toString();
    } catch (e) {
      if (e is Set && e.first is int && e.first == 3) {
        throw '${e.elementAt(1)}';
      }
      rethrow;
    }
  }

  /*
  Uses - team
  Fills - teamObj
   */
  Future<void> getTeamAbout() async {
    teamObj = await ApiMgr.api
        .getTeamApi()
        .getTeam(teamKey: 'frc$team')
        .then((value) => value.data!);
  }

  /*
  Uses - team, year
  Fills - awards
   */
  Future<void> getTeamAwards() async {
    awards = await ApiMgr.api
        .getTeamApi()
        .getTeamAwardsByYear(teamKey: 'frc$team', year: year)
        .then((value) => value.data!.asList());
  }

  /*
  Uses - team, year
  Fills - baseAvatar
   */
  Future<void> getTeamAvatar() async {
    final response = await ApiMgr.api
        .getTeamApi()
        .getTeamMediaByYear(teamKey: 'frc$team', year: year);

    if (response.data!.isNotEmpty &&
        response.data!.first.details.toString().contains('base64Image')) {
      baseAvatar = response.data!.first.details
          .toString()
          .substring(14, response.data!.first.details.toString().length - 1);
    }
  }

  /*
  Uses - districtKey
  Fills - rankings, districtRank
   */
  Future<void> getDistrictRankings() async {
    rankings = await ApiMgr.api
        .getDistrictApi()
        .getDistrictRankings(districtKey: districtKey)
        .then((value) => value.data!.asList());
    for (DistrictRanking element in rankings) {
      if (element.teamKey == 'frc$team') {
        districtRank = element.rank;
        return;
      }
    }
  }

  /*
  Uses - teamObj
   */
  String get aboutText {
    String aboutText = '';
    aboutText += teamObj!.nickname!;
    aboutText += '\n\n${teamObj!.name}';
    aboutText += '\n\n${teamObj!.website}';
    aboutText += '\n\nRookie year: ${teamObj!.rookieYear}';
    aboutText += '\n\n${teamObj!.schoolName}';
    aboutText +=
        '\n${teamObj!.city}, ${teamObj!.stateProv}, ${teamObj!.country} ${teamObj!.postalCode}';
    return aboutText;
  }

  /*
  Uses - awards, team
   */
  String get awardText {
    String awardText = '';
    for (Award award in awards) {
      awardText += "\n\n\n${award.name} -- Event: ${award.eventKey}\n";
      if (award.recipientList.isNotEmpty) {
        awardText += '\nGiven to: ';
        for (AwardRecipient awardRecipient in award.recipientList) {
          awardText +=
              "${awardRecipient.awardee ?? ''} (${awardRecipient.teamKey ?? ''})  ";
        }
      }
    }
    if (awardText.isEmpty) {
      awardText = 'This team did not win any awards in $year.';
    }
    return awardText;
  }

  /*
  Uses - districtRank
   */
  String get districtPretty {
    String districtPretty = districtKey.substring(4).toUpperCase();
    districtPretty += " District";
    return districtPretty;
  }

  /*
  Uses - districtRank
   */
  String get districtRankPretty {
    String districtRankPretty;
    switch (
        districtRank.toString().substring(districtRank.toString().length - 1)) {
      case '1':
        districtRankPretty = districtRank.toString() + 'st';
        break;
      case '2':
        districtRankPretty = districtRank.toString() + 'nd';
        break;
      case '3':
        districtRankPretty = districtRank.toString() + 'rd';
        break;
      default:
        districtRankPretty = districtRank.toString() + 'th';
    }
    return districtRankPretty;
  }

  /*
  Uses - team, year, rankings
   */
  String get scoreInfo {
    String scoreInfo = 'Team $team does not or has not competed in $year!';
    for (DistrictRanking rankedTeam in rankings) {
      if (team.toString() == rankedTeam.teamKey.substring(3) &&
          rankedTeam.pointTotal != 0) {
        scoreInfo = '${rankedTeam.pointTotal} Points';
        if (rankedTeam.rookieBonus != 0) {
          scoreInfo = '${rankedTeam.rookieBonus} rookie points.';
        }
        scoreInfo += '\n\nEvents:';
        for (DistrictRankingEventPoints eventPoints
            in rankedTeam.eventPoints!) {
          scoreInfo += '\n\n${eventPoints.eventKey}';
          if (eventPoints.districtCmp) scoreInfo += '\nDistrict Event';
          scoreInfo += '\n${eventPoints.total} Total Points.  Breakdown;';
          scoreInfo += '\nAwards:           ${eventPoints.alliancePoints}';
          scoreInfo += '\nPlayoff:            ${eventPoints.elimPoints}';
          scoreInfo += '\nAlliance:           ${eventPoints.alliancePoints}';
          scoreInfo += '\nQualification:  ${eventPoints.qualPoints}';
        }
      }
    }
    return scoreInfo;
  }

  /*
  Uses - team, rankings
   */
  List<DataRow> rowList(BuildContext context) {
    List<DataRow> rowList = <DataRow>[];
    for (DistrictRanking teamRanked in rankings) {
      if (team.toString() == teamRanked.teamKey.substring(3)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(teamRanked.rank.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900))),
          DataCell(Text(
            teamRanked.teamKey.substring(3),
            style: const TextStyle(fontWeight: FontWeight.w900),
          )),
          DataCell(Text(teamRanked.pointTotal.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900))),
        ]));
      } else if (6 > (teamRanked.rank - districtRank) &&
          -6 < (teamRanked.rank - districtRank)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(
            teamRanked.rank.toString(),
          )),
          DataCell(Text(
            teamRanked.teamKey.substring(3),
          )),
          DataCell(Text(
            teamRanked.pointTotal.toString(),
          )),
        ]));
      }
    }
    return rowList;
  }
}
