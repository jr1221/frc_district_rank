import 'package:flutter/material.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';

class DistrictRankModel {
  final int _team;
  final int _year;

  final int districtRank;
  final String districtKey;
  final List<Award> awards;
  final List<DistrictRanking> rankings;
  final Team teamObj;

  final String baseAvatar;
  final List<int> yearsRanked;

  DistrictRankModel(this._team, this._year,
      {required this.districtRank,
      required this.districtKey,
      required this.awards,
      required this.rankings,
      required this.baseAvatar,
      required this.teamObj,
      required this.yearsRanked});

  String get aboutText {
    String aboutText = '';
    aboutText += teamObj.nickname!;
    aboutText += '\n\n${teamObj.name}';
    aboutText += '\n\nRookie year: ${teamObj.rookieYear}';
    aboutText += '\n\n${teamObj.schoolName}';
    aboutText +=
        '\n${teamObj.city}, ${teamObj.stateProv}, ${teamObj.country} ${teamObj.postalCode}';
    return aboutText;
  }

  String? get teamWebsite =>
      teamObj.website?.replaceFirst('http://', 'https://');

  /*
  Uses - awards, team
   */
  String get awardText {
    String awardText = '';
    for (Award award in awards) {
      awardText += '\n\n\n${award.name} -- Event: ${award.eventKey}\n';
      if (award.recipientList.isNotEmpty) {
        awardText += '\nGiven to: ';
        for (AwardRecipient awardRecipient in award.recipientList) {
          awardText +=
              "${awardRecipient.awardee ?? ''} (${awardRecipient.teamKey ?? ''})  ";
        }
      }
    }
    if (awardText.isEmpty) {
      awardText = 'This team did not win any awards in $_year.';
    }
    return awardText;
  }

  /*
  Uses - districtRank
   */
  String get districtPretty {
    String districtPretty = districtKey.substring(4).toUpperCase();
    districtPretty += ' District';
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
        districtRankPretty = '${districtRank}st';
        break;
      case '2':
        districtRankPretty = '${districtRank}nd';
        break;
      case '3':
        districtRankPretty = '${districtRank}rd';
        break;
      default:
        districtRankPretty = '${districtRank}th';
    }
    return districtRankPretty;
  }

  /*
  Uses - team, year, rankings
   */
  String get scoreInfo {
    String scoreInfo = 'Team $_team does not or has not competed in $_year!';
    for (DistrictRanking rankedTeam in rankings) {
      if (_team.toString() == rankedTeam.teamKey.substring(3) &&
          rankedTeam.pointTotal != 0) {
        scoreInfo = '${rankedTeam.pointTotal} Points';
        if (rankedTeam.rookieBonus != 0) {
          scoreInfo = '${rankedTeam.rookieBonus} rookie points.';
        }
        scoreInfo += '\n\nEvents:';
        for (final eventPoints in rankedTeam.eventPoints!) {
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
  List<DataRow> rowList() {
    List<DataRow> rowList = <DataRow>[];
    for (DistrictRanking teamRanked in rankings) {
      if (_team.toString() == teamRanked.teamKey.substring(3)) {
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
