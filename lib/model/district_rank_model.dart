import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';

import '../cubits/district_rank_cubit.dart';

const Map<String, int> knownDistrictCapacities = {
  '2019chs': 58,
  '2019fim': 160,
  '2019fma': 60,
  '2019fnc': 32,
  '2019in': 32,
  '2019isr': 45,
  '2019ne': 64,
  '2019ont': 80,
  '2019pch': 45,
  '2019pnw': 64,
  '2019tx': 64,
};

class DistrictRankModel {
  final int _team;
  final int _year;

  // public for the dropdownmenu
  final List<int> yearsRanked;

  // Private as getters return pretty versions or parsed versions of this stuff
  final Team _teamObj;
  final List<Award> _awards;
  final List<Media> _avatarMedia;
  final List<DistrictRanking> _districtRankings;

  final String _districtKey;

  DistrictRankModel(
    this._team,
    this._year, {
    required this.yearsRanked,
    required Team teamObj,
    required List<Award> awards,
    required List<Media> avatarMedia,
    required List<DistrictRanking> districtRankings,
    required String districtKey,
  })  : _teamObj = teamObj,
        _awards = awards,
        _avatarMedia = avatarMedia,
        _districtRankings = districtRankings,
        _districtKey = districtKey;

  // Uses _districtRankings
  int get districtRank {
    for (DistrictRanking element in _districtRankings) {
      if (element.teamKey == 'frc$_team') {
        return element.rank;
      }
    }
    return -1;
  }

  // Uses _avatarMedia
  /// Returns the avatar of the team that year, or null if none
  String? get baseAvatar {
    String? baseAvatar;
    try {
      if (_avatarMedia.isNotEmpty &&
          _avatarMedia.first.details.toString().contains('base64Image')) {
        baseAvatar = _avatarMedia.first.details!.toString().substring(
              14,
              _avatarMedia.first.details.toString().length - 1,
            );
      }
    } catch (_) {}

    return baseAvatar;
  }

  // Uses teamObj
  /// Returns a helpful summary of the team
  String get aboutText {
    String aboutText = '';
    aboutText += _teamObj.nickname!;
    aboutText += '\n\n${_teamObj.name}';
    aboutText += '\n\nRookie year: ${_teamObj.rookieYear}';
    aboutText += '\n\n${_teamObj.schoolName}';
    aboutText +=
        '\n${_teamObj.city}, ${_teamObj.stateProv}, ${_teamObj.country} ${_teamObj.postalCode}';
    return aboutText;
  }

  // Uses teamObj
  /// Returns the team website in https:// format, or null if none listed
  String? get teamWebsite => _teamObj.website?.replaceFirst(
        'http://',
        'https://',
      );

  // Uses - awards, team
  /// Returns the team awards in that year, or a message saying no awards were won that year
  String get awardText {
    String awardText = '';
    for (Award award in _awards) {
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

  // Uses - districtKey
  /// Returns the capacity w/ label if such districtKey was manually entered into the system
  String? get prettyCapacity {
    int? capacity;

    for (final entry in knownDistrictCapacities.entries) {
      if (entry.key == _districtKey) {
        capacity = entry.value;
        break;
      }
    }
    if (capacity != null) {
      return 'Capacity: $capacity';
    }
    return null;
  }

  // Uses - districtRank
  ///  Returns the district pretty
  String get districtPretty {
    String districtPretty = _districtKey.substring(4).toUpperCase();
    districtPretty += ' District';
    return districtPretty;
  }

  // Uses - districtRank
  /// Returns the district rank pretty (ex. ##th)
  String get districtRankPretty {
    String districtRankPretty;
    if ((11 <= districtRank && districtRank <= 13) ||
        (111 <= districtRank && districtRank <= 113)) {
      districtRankPretty = '${districtRank}th';
    } else {
      switch (districtRank
          .toString()
          .substring(districtRank.toString().length - 1)) {
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
    }
    return districtRankPretty;
  }

  // Uses - team, year, rankings
  /// Returns the score info for each event the team competed in that year
  String get scoreInfo {
    String scoreInfo = 'Team $_team does not or has not competed in $_year!';
    for (DistrictRanking rankedTeam in _districtRankings) {
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

  // Uses - team, year, rankings
  DataTableSource rankingsSource(BuildContext context) {
    return RankingDataTableSource(
      _districtRankings,
      _team,
      _year,
      context,
    );
  }
}

class RankingDataTableSource extends DataTableSource {
  final List<DistrictRanking> _districtRankings;
  final int _team;
  final int _year;
  final BuildContext _context;

  RankingDataTableSource(
    this._districtRankings,
    this._team,
    this._year,
    this._context,
  );

  @override
  DataRow? getRow(int index) {
    final teamRanked = _districtRankings.elementAt(index);
    if (_team.toString() == teamRanked.teamKey.substring(3)) {
      return DataRow.byIndex(index: index, cells: [
        DataCell(
          Text(
            teamRanked.rank.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(
          Text(
            teamRanked.teamKey.substring(3),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(
          Text(
            teamRanked.pointTotal.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ]);
    } else {
      return DataRow.byIndex(
        index: index,
        cells: [
          DataCell(
            Text(
              textAlign: TextAlign.center,
              teamRanked.rank.toString(),
            ),
          ),
          DataCell(
            Text(
              textAlign: TextAlign.center,
              teamRanked.teamKey.substring(3),
            ),
            onTap: () => _context
                .read<DistrictRankCubit>()
                .fetchData(int.parse(teamRanked.teamKey.substring(3)), _year),
          ),
          DataCell(
            Text(
              textAlign: TextAlign.center,
              teamRanked.pointTotal.toString(),
            ),
          ),
        ],
      );
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _districtRankings.length;

  @override
  int get selectedRowCount => 0;
}
