part of 'district_rank_cubit.dart';

enum DistrictRankStatus { initial, loading, success, failure }

class DistrictRankState {
  final DistrictRankStatus status;
  final int year;
  final int team;
  final DistrictRankModel? districtRankModel;
  final Exception? exception;

  const DistrictRankState(
      {this.status = DistrictRankStatus.initial,
      this.year = 2019,
      this.team = 1,
      this.districtRankModel,
      this.exception});

  DistrictRankState copyWith(
      {DistrictRankStatus? status,
      int? year,
      int? team,
      DistrictRankModel? districtRankModel,
      Exception? exception}) {
    return DistrictRankState(
        status: status ?? this.status,
        year: year ?? this.year,
        team: team ?? this.team,
        districtRankModel: districtRankModel ?? this.districtRankModel,
        exception: exception ?? this.exception);
  }
}
