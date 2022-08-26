import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:frc_district_rank/exceptions.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';

import '../model/district_rank_model.dart';

class DistrictRankRepository {
  final TbaApiDartDioClient tbaApi;

  DistrictRankRepository({required this.tbaApi});

  Future<DistrictRankModel> fetchModel(int team, int year) async {
    List<int>? yearsRanked;
    Team? teamObj;
    List<Award>? awards;
    List<Media>? avatarMedia;
    List<DistrictRanking>? districtRankings;

    String? districtKey;

    try {
      await _fetchDistrictKey(team).then((districtList) async {
        // iterate through the district and find the one for this year, or else throw the exception with nearby years
        DistrictList districtForThisYear = districtList
            .firstWhere((element) => year == element.year, orElse: () {
          int closestYear = _sort(year, districtList.map((e) => e.year));

          throw FetchException(
              'Team $team does not have records from $year, maybe try $closestYear.',
              FetchExceptionType.wrongYear);
        });

        // Since team did compete that year, pass the yearsRanked and districtKey to model, and then fetch the actual rankings for that districtKey

        yearsRanked = districtList.map((e) => e.year).toList();
        districtKey = districtForThisYear.key;

        await _fetchDistrictRankings(districtKey!)
            .then((value) => districtRankings = value);
      });
      await Future.wait([
        _fetchTeamAwards(team, year).then((value) => awards = value),
        _fetchTeamAvatar(team, year).then((value) => avatarMedia = value),
        _fetchTeamAbout(team).then((value) => teamObj = value)
      ], eagerError: true);
    } on FetchException {
      // team did not compete in the given year
      rethrow;
    } on DioError catch (e) {
      // no response from server
      if (e.response == null) {
        throw const FetchException(
            'Cannot connect to server.  Check your internet connection!',
            FetchExceptionType.noConnection);
      }

      if (e.response!.statusCode != null && e.response!.statusCode == 404) {
        // special case, if team does not exist
        if ((e.response!.data is LinkedHashMap<String, dynamic>) &&
            e.response!.data.entries.first.value
                .toString()
                .contains('frc$team does not exist')) {
          throw FetchException(
              'Team $team does not exist, or has not competed in recent years.',
              FetchExceptionType.noTeam);
        } else {
          // Other 404 error, should not hit!
          debugPrint('Unknown 404 Error: ${e.response!.data}');
          throw FetchException(
              '404 Error: ${e.response?.data.toString() ?? 'Unknown'}',
              FetchExceptionType.other);
        }
      }
    } catch (e, s) {
      // parse error on client usually, should not hit!
      debugPrint('Unknown Parse/Serialize Error: $e \n\n $s');
      throw FetchException('Unknown Error: $e', FetchExceptionType.other);
    }

    return DistrictRankModel(
      team,
      year,
      yearsRanked: yearsRanked ?? [],
      teamObj: teamObj ?? Team(),
      awards: awards ?? [],
      avatarMedia: avatarMedia ?? [],
      districtRankings: districtRankings ?? [],
      districtKey: districtKey ?? '',
    );
  }

  Future<List<DistrictList>> _fetchDistrictKey(int team) async {
    final response =
        await tbaApi.getDistrictApi().getTeamDistricts(teamKey: 'frc$team');
    return response.data!.toList();
  }

  Future<Team> _fetchTeamAbout(int team) async {
    final response = await tbaApi.getTeamApi().getTeam(
          teamKey: 'frc$team',
        );
    return response.data!;
  }

  Future<List<Award>> _fetchTeamAwards(int team, int year) async {
    final response = await tbaApi
        .getTeamApi()
        .getTeamAwardsByYear(teamKey: 'frc$team', year: year);
    return response.data!.asList();
  }

  Future<List<Media>> _fetchTeamAvatar(int team, int year) async {
    final response = await tbaApi
        .getTeamApi()
        .getTeamMediaByYear(teamKey: 'frc$team', year: year);
    return response.data!.toList();
  }

  Future<List<DistrictRanking>> _fetchDistrictRankings(
      String districtKey) async {
    final response = await tbaApi
        .getDistrictApi()
        .getDistrictRankings(districtKey: districtKey);
    return response.data!.toList();
  }

  int _sort(int year, Iterable<int> yearsRanked) {
    // try bigger and smaller, yearsRanked sorted earliest ro most recent
    if (year > yearsRanked.last) {
      return yearsRanked.last;
    }
    if (year < yearsRanked.first) {
      return yearsRanked.first;
    }

    // just give middle year
    return yearsRanked.elementAt((yearsRanked.length / 2.0).round());
  }
}
