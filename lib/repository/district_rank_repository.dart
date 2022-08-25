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
    Team? teamObj;
    List<Award> awards = [];

    List<String> yearsRanked = [];
    String districtKey = '';
    String baseAvatar = '';
    int districtRank = -1;
    List<DistrictRanking> districtRankingsFin = [];

    try {
      await _fetchDistrictKey(team).then((districtList) async {
        for (DistrictList element in districtList) {
          yearsRanked.add(element.year.toString());
          if (element.year == year) {
            districtKey = element.key;
          }
        }

        // Basically if team didnt compete that year
        if (districtKey.isEmpty) {
          //   int closestYear = yearsRanked;

          throw FetchException('Team $team did not compete in $year',
              FetchExceptionType.wrongYear);
        }

        await _fetchDistrictRankings(districtKey).then((districtRankings) {
          districtRankingsFin = districtRankings;
          for (DistrictRanking element in districtRankings) {
            if (element.teamKey == 'frc$team') {
              districtRank = element.rank;
              break;
            }
          }
        });
      });
      await Future.wait([
        _fetchTeamAwards(team, year).then((value) => awards = value),
        _fetchTeamAvatar(team, year).then((avatarMedia) {
          try {
            if (avatarMedia.isNotEmpty &&
                avatarMedia.first.details.toString().contains('base64Image')) {
              baseAvatar = avatarMedia.first.details!.toString().substring(
                  14, avatarMedia.first.details.toString().length - 1);
            }
          } catch (_) {
            baseAvatar = '';
          }
        }),
        _fetchTeamAbout(team).then((value) => teamObj = value)
      ], eagerError: true);
    } on FetchException {
      // team did not compete in the given year
      rethrow;
    } on DioError catch (e) {
      print(e.response?.data.runtimeType);
      print(e.response?.data);

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

    return DistrictRankModel(team, year,
        districtRank: districtRank,
        districtKey: districtKey,
        awards: awards,
        rankings: districtRankingsFin,
        baseAvatar: baseAvatar,
        teamObj: teamObj ?? Team(),
        // TODO hacky
        yearsRanked: yearsRanked);
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

  Future<List<DistrictRanking>> _fetchDistrictRankings(String districtKey) async {
    final response = await tbaApi
        .getDistrictApi()
        .getDistrictRankings(districtKey: districtKey);
    return response.data!.toList();
  }
}
