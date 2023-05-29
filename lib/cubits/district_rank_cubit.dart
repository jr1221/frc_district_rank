import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frc_district_rank/constants.dart';
import 'package:frc_district_rank/exceptions.dart';
import 'package:hive/hive.dart';

import '../model/district_rank_model.dart';
import '../repository/district_rank_repository.dart';

part 'district_rank_state.dart';

class DistrictRankCubit extends Cubit<DistrictRankState> {
  final DistrictRankRepository districtRankRepository;

  DistrictRankCubit({
    required this.districtRankRepository,
  }) : super(
          const DistrictRankState(),
        );

  Future<void> fetchData(int team, int year) async {
    emit(
      state.copyWith(
        status: DistrictRankStatus.loading,
      ),
    );
    try {
      final model = await districtRankRepository.fetchModel(
        team,
        year,
      );
      emit(
        state.copyWith(
          status: DistrictRankStatus.success,
          team: team,
          year: year,
          districtRankModel: model,
        ),
      );
      final settings = Hive.box<String>(ProjectConstants.settingsBoxKey);
      settings.put(
        ProjectConstants.lastTeamStorageKey,
        team.toString(),
      );
      settings.put(
        ProjectConstants.lastYearStorageKey,
        year.toString(),
      );
    } on FetchException catch (e) {
      emit(
        state.copyWith(
          status: DistrictRankStatus.failure,
          exception: e,
        ),
      );
    } catch (exception) {
      if (kDebugMode) {
        print('BAD: $exception');
      }
      emit(
        state.copyWith(
          status: DistrictRankStatus.failure,
          exception: Exception(exception),
        ),
      );
    }
  }
}
