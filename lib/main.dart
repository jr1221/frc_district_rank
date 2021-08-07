import 'dart:convert';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frc_district_rank/data_model.dart';
import 'api_mgr.dart';
import 'constants.dart';
import 'district_cap.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
  ApiMgr.init();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRC District Ranking',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.light,
        primaryColor: Colors.blueGrey,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.white,
        primaryColorBrightness: Brightness.dark,
        primaryColorLight: Colors.black,
        brightness: Brightness.dark,
        primaryColorDark: Colors.black,
        indicatorColor: Colors.white,
        canvasColor: Colors.black,
        dialogBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.black,
            shape: const RoundedRectangleBorder(
                side: BorderSide(width: 3.0, color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
        appBarTheme: const AppBarTheme(
            brightness: Brightness.dark, backgroundColor: Colors.black),
      ),
      home: Scaffold(
          appBar: AppBar(
            title: const Text('FRC District Ranking'),
            centerTitle: true,
          ),
          body: const HomePage(),
          bottomSheet: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text.rich(
                buildTextSpan(
                  [
                    TextElement("Data provided by "),
                    LinkableElement(
                        "The Blue Alliance", "https://thebluealliance.com"),
                  ],
                  onOpen: (link) => onOpen(link),
                  linkStyle: const TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _teamSelectTextController =
      TextEditingController();
  final _teamSelectFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    AsyncValue<DataModel> _data = ref.watch(dataProv);
    return _data.when(
        loading: () => const Center(
                child: CircularProgressIndicator(
              strokeWidth: 5.0,
            )),
        error: (err, stack) => AlertDialog(
              title: const Text(
                'Error, redirecting to previous results',
                textAlign: TextAlign.center,
              ),
              content: Text('Details: $err'),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(teamProv).state =
                              ref.read(prevTeamProv).state == -1
                                  ? Constants.defaultTeam
                                  : ref.read(prevTeamProv).state;
                          ref.read(yearProv).state =
                              ref.read(prevYearProv).state == -1
                                  ? Constants.defaultYear
                                  : ref.read(prevYearProv).state;
                          ref.refresh(dataProv);
                        },
                        child: const Text("Ok"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(dataProv);
            },
            child: ExpandableTheme(
              data: ExpandableThemeData(
                iconColor: Theme.of(context).primaryColor,
              ),
              child: ListView(
                children: <Widget>[
                  const SizedBox(
                    height: 5,
                  ),
                  if (data.baseAvatar.isNotEmpty)
                    Image(
                      image: MemoryImage(base64Decode(data.baseAvatar),
                          scale: 0.75),
                      alignment: Alignment.topCenter,
                      fit: BoxFit.scaleDown,
                      width: DataModel.avatarW.toDouble(),
                      height: DataModel.avatarH.toDouble(),
                    ),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: 'Team ${data.team}\n',
                            style: const TextStyle(
                              fontSize: 26,
                            )),
                        TextSpan(
                            text: '${data.districtRankPretty}\n',
                            style: TextStyle(
                              fontSize: (data.districtRankPretty.length == 3)
                                  ? 80
                                  : (data.districtRankPretty.length == 4)
                                      ? 56
                                      : (data.districtRankPretty.length == 5)
                                          ? 50
                                          : 58,
                            )),
                        TextSpan(
                          text: '${data.districtPretty}\n',
                          style: const TextStyle(
                            fontSize: 22,
                          ),
                        ),
                        if (data.year == 2019)
                          TextSpan(
                            text: DistrictCap(districtKey: data.districtKey)
                                .prettyCapacity(),
                            style: const TextStyle(
                              fontSize: 22,
                            ),
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: DefaultTextStyle.of(context).style,
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Center(
                    child: DropdownButton<String>(
                      value: data.year.toString(),
                      icon: const Icon(
                        Icons.arrow_downward,
                      ),
                      iconSize: 28,
                      elevation: 16,
                      underline: Container(
                        height: 2,
                      ),
                      onChanged: (newValue) {
                        ref.read(yearProv).state = int.parse(newValue!);
                        ref.refresh(dataProv);
                      },
                      items: data.yearsRanked
                          .map<DropdownMenuItem<String>>((String value) {
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
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: ElevatedButton(
                        child: const Text(
                          "Choose Team",
                          textAlign: TextAlign.center,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
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
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          controller: _teamSelectTextController,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty ||
                                                int.tryParse(value) == null) {
                                              return 'Empty or incorrect team number';
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (value) {
                                            if (_teamSelectFormKey.currentState!
                                                .validate()) {
                                              ref.read(teamProv).state =
                                                  int.parse(
                                                      _teamSelectTextController
                                                          .text);
                                              ref.refresh(dataProv);
                                              Navigator.pop(context);
                                              return;
                                            }
                                          },
                                          decoration: const InputDecoration(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_teamSelectFormKey.currentState!
                                              .validate()) {
                                            ref.read(teamProv).state =
                                                int.parse(
                                                    _teamSelectTextController
                                                        .text);
                                            ref.refresh(dataProv);
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
                        }),
                  ),
                  Container(
                    // expander about
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: ExpandablePanel(
                      header: const Text(
                        "About Team",
                        style: TextStyle(fontSize: 20),
                      ),
                      expanded: Center(
                        child: Linkify(
                          textAlign: TextAlign.center,
                          text: data.aboutText,
                          onOpen: onOpen,
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
                        "Awards",
                        style: TextStyle(fontSize: 20),
                      ),
                      expanded: Center(
                        child: Text(
                          data.awardText,
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
                        "Scoring",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      expanded: Center(
                          child: Text(
                        data.scoreInfo,
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
                        "Leaderboard",
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
                          rows: data.rowList(context),
                        ),
                      ),
                      collapsed: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
