import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:frc_district_rank/api_key.dart';
import 'package:hive/hive.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cache_manager.dart';
import '../constants.dart';
import '../cubits/district_rank_cubit.dart';
import '../repository/district_rank_repository.dart';

class DistrictRankScreen extends StatelessWidget {
  const DistrictRankScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) {
          final settings = Hive.box<String>(ProjectConstants.settingsBoxKey);
          Hive.box<List<int>>(ProjectConstants.favoriteTeamsBoxKey)
              .put(ProjectConstants.favoriteTeamsStorageKey, [237, 195, 118]);
          int prevLaunchTeam = int.parse(settings.get(
              ProjectConstants.lastTeamStorageKey,
              defaultValue: ProjectConstants.defaultTeam.toString())!);
          int prevLaunchYear = int.parse(settings.get(
              ProjectConstants.lastYearStorageKey,
              defaultValue: ProjectConstants.defaultYear.toString())!);

          final api = TbaApiDartDioClient()
            ..dio.interceptors.add(DioCacheInterceptor(
                    options: CacheOptions(
                  policy: CachePolicy.request,
                  hitCacheOnErrorExcept: [401, 403, 404],
                  // on not found, show errer, then use cubit to restore previous state
                  store:
                      CacheManager.hiveCacheStore!, // needs CacheManager.init()
                )))
            ..setApiKey('apiKey',
                apiKey); // from lib/api_key.dart, variable const apiKey = 'XXXXX'; <-- TBA api key from account settings

          return DistrictRankCubit(
              districtRankRepository: DistrictRankRepository(tbaApi: api))
            ..fetchData(prevLaunchTeam, prevLaunchYear);
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('FRC District Ranking'),
            centerTitle: true,
            leading: const Image(image: AssetImage('assets/logo/logo.png')),
            actions: [
              IconButton(
                  icon: const Icon(
                    Icons.settings,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/settings')),
            ],
          ),
          body: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 21),
            child: DistrictRankHome(),
          ),
          bottomSheet: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text.rich(
                buildTextSpan(
                  [
                    TextElement('Powered by '),
                    LinkableElement(
                        'The Blue Alliance', 'https://thebluealliance.com'),
                  ],
                  linkStyle: const TextStyle(
                    color: Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                  onOpen: (link) async {
                    final url = Uri.parse(link.url);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }
}

class DistrictRankHome extends StatelessWidget {
  DistrictRankHome({Key? key}) : super(key: key);

  final _teamSelectTextController = TextEditingController();
  final _teamSelectFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DistrictRankCubit, DistrictRankState>(
        listener: (context, state) {
      switch (state.status) {
        case DistrictRankStatus.initial:
          break;
        case DistrictRankStatus.loading:
          break;
        case DistrictRankStatus.success:
          _teamSelectTextController.clear();
          break;
        case DistrictRankStatus.failure:
          String showErrMessage =
              state.exception?.toString() ?? 'Unknown Error';

          showDialog<Widget>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Error, showing previous results',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center),
              content: Text(showErrMessage),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        child: const Text('Ok'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          break;
      }
    }, builder: (context, state) {
      switch (state.status) {
        case DistrictRankStatus.initial:
        case DistrictRankStatus.loading:
          return const Center(
              child: CircularProgressIndicator(
            strokeWidth: 5.0,
          ));
        case DistrictRankStatus.success:
        case DistrictRankStatus.failure:
          if (state.districtRankModel != null) {
            final favoriteTeamRecord =
                Hive.box<List<int>>(ProjectConstants.favoriteTeamsBoxKey).get(
                    ProjectConstants.favoriteTeamsStorageKey,
                    defaultValue: [])!;
            return RefreshIndicator(
              child: ExpandableTheme(
                data: ExpandableThemeData(
                  iconColor: Theme.of(context).colorScheme.inverseSurface,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('View more info on The Blue Alliance',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12)),
                        IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.open_in_new_outlined,
                              size: 16.0,
                            ),
                            onPressed: () async {
                              final url = Uri.parse(
                                  'https://www.thebluealliance.com/team/${state.team}/${state.year}');
                              if (await canLaunchUrl(url)) {
                                launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                BotToast.showText(
                                    text: 'Failed to launch ${url.toString()}');
                              }
                            })
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    if (state.districtRankModel!.baseAvatar != null)
                      Image(
                          alignment: Alignment.topCenter,
                          fit: BoxFit.none,
                          width: ProjectConstants.avatarW.toDouble(),
                          height: ProjectConstants.avatarH.toDouble(),
                          image: MemoryImage(
                              base64Decode(
                                  state.districtRankModel!.baseAvatar!),
                              scale: 0.75)),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 26,
                            ),
                            text: 'Team ${state.team}\n',
                          ),
                          TextSpan(
                            style: TextStyle(
                              fontSize: (state.districtRankModel!
                                          .districtRankPretty.length ==
                                      3)
                                  ? 80
                                  : (state.districtRankModel!.districtRankPretty
                                              .length ==
                                          4)
                                      ? 56
                                      : (state.districtRankModel!
                                                  .districtRankPretty.length ==
                                              5)
                                          ? 50
                                          : 58,
                            ),
                            text:
                                '${state.districtRankModel!.districtRankPretty}\n',
                          ),
                          TextSpan(
                              style: const TextStyle(
                                fontSize: 22,
                              ),
                              text:
                                  '${state.districtRankModel!.districtPretty}\n'),
                          TextSpan(
                              style: const TextStyle(
                                fontSize: 22,
                              ),
                              text: state.districtRankModel!.prettyCapacity),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Center(
                      child: DropdownButton<int>(
                          hint: Text(state.year.toString(),
                              style: TextStyle(
                                  fontSize: 28,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface)),
                          icon: const Icon(
                            Icons.arrow_downward,
                          ),
                          value: state.year,
                          iconSize: 28,
                          elevation: 16,
                          underline: Container(
                            height: 2,
                          ),
                          items: state.districtRankModel!.yearsRanked
                              .map<DropdownMenuItem<int>>((int value) {
                            if (value == state.year) {
                              return DropdownMenuItem<int>(
                                  value: value,
                                  child: Center(
                                    child: Text(
                                      value.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                  onTap: () => BotToast.showText(
                                      text:
                                          'You were already on ${state.year}'));
                            }
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Center(
                                child: Text(
                                  value.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != state.year) {
                              context
                                  .read<DistrictRankCubit>()
                                  .fetchData(state.team, newValue!);
                            }
                          }),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Container(
                      // change team button
                      padding: const EdgeInsets.only(left: 64, right: 64),
                      child: ElevatedButton(
                          child: const Text(
                            'Choose Team',
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            showDialog<Widget>(
                                context: context,
                                barrierDismissible: true,
                                builder: (_) {
                                  return BlocProvider<DistrictRankCubit>.value(
                                    value: context.read<DistrictRankCubit>(),
                                    child: AlertDialog(
                                        scrollable: true,
                                        title: const Text(
                                          'Enter Team Number',
                                          textAlign: TextAlign.center,
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.center,
                                        actionsPadding: const EdgeInsets.only(
                                            left: 16.0, right: 16.0),
                                        contentPadding:
                                            const EdgeInsets.only(bottom: 6.0),
                                        content: Form(
                                          key: _teamSelectFormKey,
                                          child: TextFormField(
                                            autofocus: true,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            controller:
                                                _teamSelectTextController,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Team # from last 7 years',
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty ||
                                                  int.tryParse(value) == null) {
                                                return 'Empty or incorrect team number';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (value) {
                                              if (_teamSelectFormKey
                                                  .currentState!
                                                  .validate()) {
                                                int team = int.parse(
                                                    _teamSelectTextController
                                                        .text);
                                                context
                                                    .read<DistrictRankCubit>()
                                                    .fetchData(
                                                        team, state.year);
                                                Navigator.pop(context);
                                                return;
                                              }
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          Row(children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                child: const Text('Save'),
                                                onPressed: () {
                                                  if (_teamSelectFormKey
                                                      .currentState!
                                                      .validate()) {
                                                    Navigator.pop(context);
                                                    int team = int.parse(
                                                        _teamSelectTextController
                                                            .text);
                                                    context
                                                        .read<
                                                            DistrictRankCubit>()
                                                        .fetchData(
                                                            team, state.year);
                                                    return;
                                                  }
                                                },
                                              ),
                                            ),
                                          ]),
                                          if (favoriteTeamRecord.isNotEmpty)
                                            const Divider(),
                                          if (favoriteTeamRecord.isNotEmpty)
                                            const Center(
                                                child: Text('Favorites')),
                                          if (favoriteTeamRecord.isNotEmpty)
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: favoriteTeamRecord
                                                    .map<Widget>((team) =>
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              context
                                                                  .read<
                                                                      DistrictRankCubit>()
                                                                  .fetchData(
                                                                      team,
                                                                      state
                                                                          .year);
                                                            },
                                                            child:
                                                                Text('$team')))
                                                    .toList())
                                        ]),
                                  );
                                });
                          }),
                    ),
                    Container(
                      // expander about
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 20),
                      child: ExpandablePanel(
                        header: Row(
                          children: [
                            Text('About Team ${state.team}',
                                style: const TextStyle(fontSize: 20)),
                            IconButton(
                                onPressed: () async {
                                  if (state.districtRankModel!.teamWebsite !=
                                      null) {
                                    try {
                                      final url = Uri.parse(state
                                          .districtRankModel!.teamWebsite!);
                                      if (await canLaunchUrl(url)) {
                                        launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      } else {
                                        BotToast.showText(
                                            text:
                                                'Failed to launch website ${url.toString()}');
                                      }
                                    } catch (e) {
                                      BotToast.showText(
                                          text: 'Failed to parse website');
                                    }
                                  } else {
                                    BotToast.showText(
                                        text:
                                            'Team ${state.team} doesn\'t have a website on file');
                                  }
                                },
                                icon: const Icon(Icons.open_in_new))
                          ],
                        ),
                        expanded: Center(
                          child: SelectableText(
                            state.districtRankModel!.aboutText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        collapsed: const SizedBox(),
                      ),
                    ),
                    Container(
                      // expander awards
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 20),
                      child: ExpandablePanel(
                        header: const Text(
                          'Awards',
                          style: TextStyle(fontSize: 20),
                        ),
                        expanded: Center(
                          child: SelectableText(
                            state.districtRankModel!.awardText,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        collapsed: const SizedBox(),
                      ),
                    ),
                    Container(
                      // expander scoring
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 20),
                      child: ExpandablePanel(
                        header: const Text(
                          'Scoring',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        expanded: Center(
                            child: SelectableText(
                          state.districtRankModel!.scoreInfo,
                          textAlign: TextAlign.center,
                        )),
                        collapsed: const SizedBox(),
                      ),
                    ),
                    Container(
                        // expander leaderboard
                        padding:
                            const EdgeInsets.only(left: 16, right: 16, top: 20),
                        child: ExpandablePanel(
                          header: const Text(
                            'Leaderboard',
                            style: TextStyle(fontSize: 20),
                          ),
                          collapsed: const SizedBox(),
                          expanded: Center(
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 1,
                                    child: PaginatedDataTable(
                                      showFirstLastButtons: true,
                                      showCheckboxColumn: false,
                                      initialFirstRowIndex: state
                                          .districtRankModel!.districtRank
                                          .closestLowerMultiple(10),
                                      rowsPerPage: 10,
                                      horizontalMargin: 60,
                                      columns: const <DataColumn>[
                                        DataColumn(
                                          label: Text(
                                            'Rank',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Team',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Points',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                      source: state.districtRankModel!
                                          .rankingsSource(context),
                                    ))
                              ],
                            ),
                          ),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (favoriteTeamRecord.contains(state.team))
                          IconButton(
                              onPressed: () {
                                favoriteTeamRecord.remove(state.team);
                                Hive.box<List<int>>(
                                        ProjectConstants.favoriteTeamsBoxKey)
                                    .put(
                                        ProjectConstants
                                            .favoriteTeamsStorageKey,
                                        favoriteTeamRecord);
                                context.read<DistrictRankCubit>().fetchData(
                                    state.team,
                                    state
                                        .year); // TODO restate icon without reloading
                              },
                              icon: const Icon(Icons.star)),
                        if (!favoriteTeamRecord.contains(state.team))
                          IconButton(
                              onPressed: () {
                                if (favoriteTeamRecord.length >= 5) {
                                  BotToast.showText(
                                      text:
                                          'No more than 5 favorites are allowed.');
                                  return;
                                }
                                favoriteTeamRecord.add(state.team);
                                Hive.box<List<int>>(
                                        ProjectConstants.favoriteTeamsBoxKey)
                                    .put(
                                        ProjectConstants
                                            .favoriteTeamsStorageKey,
                                        favoriteTeamRecord);
                                context
                                    .read<DistrictRankCubit>()
                                    .fetchData(state.team, state.year);
                              },
                              icon: const Icon(Icons.star_border)),
                        if (favoriteTeamRecord.contains(state.team))
                          const Text('Unset Favorite'),
                        if (!favoriteTeamRecord.contains(state.team))
                          const Text('Set Favorite')
                      ],
                    )
                  ],
                ),
              ),
              onRefresh: () {
                return context
                    .read<DistrictRankCubit>()
                    .fetchData(state.team, state.year);
              },
            );
          } else {
            return Center(
                child: Column(
              children: [
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Cannot connect to TBA server or build cache!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                ElevatedButton(
                  child: const Text(
                    'Retry',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28.0),
                  ),
                  onPressed: () {
                    context.read<DistrictRankCubit>().fetchData(
                        ProjectConstants.defaultTeam,
                        ProjectConstants.defaultYear);
                  },
                )
              ],
            ));
          }
      }
    });
  }
}

extension ClosestMultiple on int {
  int closestLowerMultiple(int multiple) {
    int result = multiple * (this / multiple).truncate();
    if (this % 10 == 0) {
      result -= 10;
    }
    return result;
  }
}
