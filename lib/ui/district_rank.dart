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
import '../district_cap.dart';
import '../repository/district_rank_repository.dart';

class DistrictRankScreen extends StatelessWidget {
  const DistrictRankScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) {
          final settings = Hive.box<String>(ProjectConstants.settingsBoxKey);
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
                  store: BackupCacheStore(
                      primary: MemCacheStore(),
                      secondary: CacheManager
                          .hiveCacheStore!), // needs CacheManager.init()
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
            actions: [
              IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(
                    Icons.settings,
                  ))
            ],
          ),
          body: DistrictRankHome(),
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
                  onOpen: (link) async {
                    final url = Uri.parse(link.url);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                  linkStyle: TextStyle(
                    color: Theme.of(context).toggleableActiveColor,
                    decoration: TextDecoration.underline,
                  ),
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
          break;
        case DistrictRankStatus.failure:
          String showErrMessage =
              state.exception?.toString() ?? 'Unknown Error';

          showDialog<Widget>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Error, showing previous results',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).errorColor)),
              content: Text(showErrMessage),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'),
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
          return const Center(
              child: CircularProgressIndicator(
            strokeWidth: 5.0,
            color: Colors.red,
          ));
        case DistrictRankStatus.loading:
          return const Center(
              child: CircularProgressIndicator(
            strokeWidth: 5.0,
          ));
        case DistrictRankStatus.success:
        case DistrictRankStatus.failure:
          if (state.districtRankModel != null) {
            return RefreshIndicator(
              onRefresh: () {
                return context
                    .read<DistrictRankCubit>()
                    .fetchData(state.team, state.year);
              },
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
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center),
                        IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
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
                            },
                            icon: const Icon(
                              Icons.open_in_new_outlined,
                              size: 16.0,
                            ))
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    if (state.districtRankModel!.baseAvatar.isNotEmpty)
                      Image(
                        image: MemoryImage(
                            base64Decode(state.districtRankModel!.baseAvatar),
                            scale: 0.75),
                        alignment: Alignment.topCenter,
                        fit: BoxFit.none,
                        width: ProjectConstants.avatarW.toDouble(),
                        height: ProjectConstants.avatarH.toDouble(),
                      ),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                              text: 'Team ${state.team}\n',
                              style: const TextStyle(
                                fontSize: 26,
                              )),
                          TextSpan(
                              text:
                                  '${state.districtRankModel!.districtRankPretty}\n',
                              style: TextStyle(
                                fontSize: (state.districtRankModel!
                                            .districtRankPretty.length ==
                                        3)
                                    ? 80
                                    : (state.districtRankModel!
                                                .districtRankPretty.length ==
                                            4)
                                        ? 56
                                        : (state
                                                    .districtRankModel!
                                                    .districtRankPretty
                                                    .length ==
                                                5)
                                            ? 50
                                            : 58,
                              )),
                          TextSpan(
                            text:
                                '${state.districtRankModel!.districtPretty}\n',
                            style: const TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          if (state.year == 2019)
                            TextSpan(
                              text: DistrictCap(
                                      districtKey:
                                          state.districtRankModel!.districtKey)
                                  .prettyCapacity(),
                              style: const TextStyle(
                                fontSize: 22,
                              ),
                            ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Center(
                      child: DropdownButton<String>(
                        hint: Text(state.year.toString(),
                            style: TextStyle(
                                fontSize: 28,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface)),
                        icon: const Icon(
                          Icons.arrow_downward,
                        ),
                        iconSize: 28,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                        ),
                        onChanged: (newValue) {
                          context
                              .read<DistrictRankCubit>()
                              .fetchData(state.team, int.parse(newValue!));
                        },
                        items: state.districtRankModel!.yearsRanked
                            .map<DropdownMenuItem<String>>((String value) {
                          // TODO, actually fix 2015, or at least provide hint
                          if (value == '2015' ||
                              value == state.year.toString()) {
                            return DropdownMenuItem<String>(
                              enabled: false,
                              value: value,
                              child: Center(
                                child: Text(
                                  value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: Theme.of(context).disabledColor),
                                ),
                              ),
                            );
                          }
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center(
                              child: Text(
                                value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                                      title: const Text(
                                        'Enter Team Number',
                                        textAlign: TextAlign.center,
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Form(
                                            key: _teamSelectFormKey,
                                            child: Column(
                                              children: <Widget>[
                                                TextFormField(
                                                  autofocus: true,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  controller:
                                                      _teamSelectTextController,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty ||
                                                        int.tryParse(value) ==
                                                            null) {
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
                                                          .read<
                                                              DistrictRankCubit>()
                                                          .fetchData(
                                                              team, state.year);
                                                      Navigator.pop(context);
                                                      return;
                                                    }
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        'Team # from last 7 years',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (_teamSelectFormKey
                                                      .currentState!
                                                      .validate()) {
                                                    int team = int.parse(
                                                        _teamSelectTextController
                                                            .text);
                                                    context
                                                        .read<
                                                            DistrictRankCubit>()
                                                        .fetchData(
                                                            team, state.year);
                                                    Navigator.pop(context);
                                                    return;
                                                  }
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                        expanded: Center(
                          child: DataTable(
                            columns: const <DataColumn>[
                              DataColumn(
                                label: Text(
                                  'Rank',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Team',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Points',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                            rows: state.districtRankModel!.rowList(),
                          ),
                        ),
                        collapsed: const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Text('Unknown error');
          }
      }
    });
  }
}
