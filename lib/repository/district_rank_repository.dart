import 'package:dio/dio.dart';
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
      await Future.wait([
        _fetchDistrictKey(team).then((districtList) async {
          for (DistrictList element in districtList) {
            yearsRanked.add(element.year.toString());
            if (element.year == year) {
              districtKey = element.key;
            }
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
        }),
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
    } on DioError catch (e) {
      if (e.response == null) {
        throw 'Cannot connect to server.  Check your internet connection!';
      } else if (e.response!.statusCode != null &&
          e.response!.statusCode == 404) {
        throw e.response.toString(); // Some other err
      } else {
        throw e.toString(); // Team doesn't exist most likely
      }
    } catch (e) {
      print(e.runtimeType);
      if (e is Set && e.first is int && e.first == 3) {
        throw '${e.elementAt(1)}'; // TODO wtf
      }
      rethrow;
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

  Future<List<DistrictRanking>> _fetchDistrictRankings(
      String districtKey) async {
    final response = await tbaApi
        .getDistrictApi()
        .getDistrictRankings(districtKey: districtKey);
    return response.data!.toList();
  }
}
