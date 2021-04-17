import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:expandable/expandable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';

import 'ApiMgr.dart';
import 'districtCap.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InfoPackage dataPack = InfoPackage();
  InfoPackage dataPackStable = InfoPackage();

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  _createAvatarSection() {
    return dataPack.createAvatar();
  }

  _createRankBlockSection() {
    return dataPack.createRankBlock();
  }

  _createYearDropdownInside() {
    return Center(
      child: DropdownButton<String>(
        value: dataPack.year.toString(),
        icon: Icon(
          Icons.arrow_downward,
          color: Colors.blueGrey,
        ),
        iconSize: 28,
        elevation: 16,
        style: TextStyle(color: Colors.blueGrey),
        underline: Container(
          height: 2,
          color: Colors.blueGrey,
        ),
        onChanged: (newValue) {
          setState(() {
            dataPack.year = int.parse(newValue!);
            _refreshController.requestRefresh();
          });
        },
        items:
            dataPack.yearsRanked.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Center(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  _createAboutSection() {
    return dataPack.createAbout();
  }

  _createAwardsSection() {
    return dataPack.createAwards();
  }

  _createScoringSection() {
    return dataPack.createScoring();
  }

  _createLeaderboardSection() {
    return dataPack.createLeaderboard();
  }

  _chooseTeam() {
    int team = 0;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Team Number',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Team # from last 7 years',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  if (num.tryParse(value) != null) {
                    team = int.parse(value);
                  } else
                    team = 0;
                },
                onSubmitted: (String value) async {
                  if (num.tryParse(value) != null) {
                    team = int.parse(value);
                  }
                }),
            SizedBox(
              height: 6,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (team != 0) {
                        dataPack.team = team;
                        Navigator.pop(context);
                        _refreshController.requestRefresh();
                        return;
                      }
                    },
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final String result = await dataPack.refresh();

    if (result != '0') {
      print(result);
      setState(() {
        _refreshController.refreshFailed();
        _refreshController.headerStatus;
      });
      if (result == '2') {
        await showDialog(
            context: context,
            builder: (_) => SimpleDialog(
                  title: Text(
                      "Team is either missing from the database or has not registered in a district in recent years. Please enter a different team."),
                  children: [
                    ElevatedButton(
                      child: Text("Ok"),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _chooseTeam();
                        return;
                      },
                    )
                  ],
                ));
      }
      else if (result.startsWith('3')) {
        await showDialog(
            context: context,
            builder: (_) => SimpleDialog(
                  title: Text(result.substring(1)),
                  children: [
                    ElevatedButton(
                      child: Text("Ok"),
                      onPressed: () async {
                        _refreshController.requestRefresh();
                        Navigator.pop(context);
                        return;
                      },
                    )
                  ],
                ));
      } else {
        await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text('Error'),
                  content: Container(
                    height: 300,
                    width: 300,
                    child: ListView(
                      children: [
                        Text(result),
                        SizedBox(height: 15),
                        Text(
                          'You can retry the same search or you may need to cancel and try a different search.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      child: Text("Retry"),
                      onPressed: () {
                        _refreshController.requestRefresh();
                        Navigator.pop(context);
                        return;
                      },
                    ),
                    ElevatedButton(
                      child: Text("Cancel"),
                      onPressed: () {
                        dataPack = dataPackStable.clone();
                        setState(() {
                          _refreshController.refreshCompleted();
                          _refreshController.headerStatus;
                        });
                        Navigator.pop(context);
                        return;
                      },
                    ),
                  ],
                ));
      }
      return;
    }
    dataPackStable = dataPack.clone();
    _refreshController.refreshCompleted();
    setState(() {
      _refreshController.headerStatus;
    });
    if (dataPack.year == 2019 &&
        DistrictCap(districtKey: dataPack.district).capacity >=
            dataPack.districtRank) _confettiController.play();
  }

  Future<void> _fillKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? team = prefs.getInt('team');
    int? year = prefs.getInt('year');
    if (team != null && year != null) {
      dataPack.team = team;
      dataPack.year = year;
    }
  }

  Future<void> _refreshWithKeys() async {}

  @override
  void initState() {
    super.initState();
    _refreshWithKeys();
    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      await _fillKeys();
      _refreshController.requestRefresh();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Align confetti = Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        minBlastForce: 19,
        emissionFrequency: 0.2, // how often it should emit
        numberOfParticles: 4, // number of particles to emit
        gravity: 0.7,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple
        ],
      ),
    );

    return SmartRefresher(
        enablePullUp: false,
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: ListView(
          children: <Widget>[
            if (_refreshController.headerStatus == RefreshStatus.completed)
              Column(
                children: <Widget>[
                  SizedBox(
                    height: 5,
                  ),
                  confetti,
                  _createAvatarSection(),
                  _createRankBlockSection(),
                  SizedBox(
                    height: 30.0,
                  ),
                  _createYearDropdownInside(),
                  SizedBox(
                    height: 20.0,
                  ),
                  Container(
                    // change team button
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: ElevatedButton(
                      onPressed: _chooseTeam,
                      child: Text(
                        "Choose Team",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Container(
                    // expander about
                    padding: EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: ExpandableTheme(
                      data: ExpandableThemeData(
                        iconColor: Colors.blueGrey,
                      ),
                      child: ExpandablePanel(
                        header: Text(
                          "About Team ${dataPack.team}",
                          style:
                              TextStyle(fontSize: 20, color: Colors.blueGrey),
                        ),
                        expanded: _createAboutSection(),
                        collapsed: SizedBox(),
                      ),
                    ),
                  ),
                  Container(
                    // expander awards
                    padding: EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: ExpandableTheme(
                      data: ExpandableThemeData(
                        iconColor: Colors.blueGrey,
                      ),
                      child: ExpandablePanel(
                        header: Text(
                          "Awards",
                          style:
                              TextStyle(fontSize: 20, color: Colors.blueGrey),
                        ),
                        expanded: _createAwardsSection(),
                        collapsed: SizedBox(),
                      ),
                    ),
                  ),
                  Container(
                    // expander scoring
                    padding: EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: ExpandableTheme(
                      data: ExpandableThemeData(
                        iconColor: Colors.blueGrey,
                      ),
                      child: ExpandablePanel(
                        header: Text(
                          "Scoring",
                          style:
                              TextStyle(fontSize: 20, color: Colors.blueGrey),
                        ),
                        expanded: _createScoringSection(),
                        collapsed: SizedBox(),
                      ),
                    ),
                  ),
                  Container(
                    // expander leaderboard
                    padding: EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: ExpandableTheme(
                      data: ExpandableThemeData(
                        iconColor: Colors.blueGrey,
                      ),
                      child: ExpandablePanel(
                        header: Text(
                          "Leaderboard",
                          style:
                              TextStyle(fontSize: 20, color: Colors.blueGrey),
                        ),
                        expanded: _createLeaderboardSection(),
                        collapsed: SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ));
  }
}

class InfoPackage {
  int team = 2712;
  int year = 2019;

  int districtRank = 1;

  String district = '2019ne';
  List<Award> awards = [];
  List<DistrictRanking> rankings = [];
  String baseAvatar = '';
  Team? teamObj;

  String districtRankPretty = '';
  String districtPretty = '';

  double fontRank = 60;

  List<String> yearsRanked = [];

  double avatarW = 40;
  double avatarH = 60;

  InfoPackage();

  InfoPackage.clone(
      {required this.team,
      required this.year,
      required this.districtRank,
      required this.district,
      required this.awards,
      required this.rankings,
      required this.baseAvatar,
      required this.teamObj,
      required this.districtRankPretty,
      required this.districtPretty,
      required this.fontRank,
      required this.yearsRanked,
      required this.avatarW,
      required this.avatarH});

  InfoPackage clone() {
    return InfoPackage.clone(
        team: team,
        year: year,
        districtRank: districtRank,
        district: district,
        awards: awards,
        rankings: rankings,
        baseAvatar: baseAvatar,
        teamObj: teamObj,
        districtRankPretty: districtRankPretty,
        districtPretty: districtPretty,
        fontRank: fontRank,
        yearsRanked: yearsRanked,
        avatarW: avatarW,
        avatarH: avatarH);
  }

  Future<void> _addKeys() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('team', team);
    prefs.setInt('year', year);
  }

  Future<String> refresh() async {
    // 2 is ask for new team // 0 is success // a map of 3 (int) and string message is notify of auto-correct year // all other string is a failure message
    try {
      await getDistrictKey();
      await getTeamAbout();
      assert(teamObj != null);
      await getAwards();
      await getAvatar(); // TODO: maybe API will throw error on no avatar, examine response so blank avatar can be inserted
      await getDistrictRankings();
      format();
      _addKeys();
    } on DioError catch (e) {
      return e.message;
    } catch (e) {
      if (e is String) {
        return '4$e';
      }
      if (e is int && e == 2) {
        return '2';
      }
      if (e is Set && e.first == 3) {
        return '3${e.elementAt(1)}';
      }
      return '4Unknown Error\n' + e.toString();
    }
    return '0';
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  void format() {
    districtPretty = district.substring(4).toUpperCase();
    districtPretty += " District";
    switch (
        districtRank.toString().substring(districtRank.toString().length - 1)) {
      case '1':
        districtRankPretty = districtRank.toString() + 'st';
        break;
      case '2':
        districtRankPretty = districtRank.toString() + 'nd';
        break;
      case '3':
        districtRankPretty = districtRank.toString() + 'rd';
        break;
      default:
        districtRankPretty = districtRank.toString() + 'th';
    }
    switch (districtRankPretty.length) {
      case 3:
        fontRank = 80;
        return;
      case 4:
        fontRank = 56;
        return;
      case 5:
        fontRank = 50;
        return;
      default:
        fontRank = 58;
    }
  }

  Future<void> getDistrictKey() async {
    try {
      final response = await ApiMgr.api
          .getDistrictApi()
          .getTeamDistricts(teamKey: 'frc$team');
      if (response.data!.isNotEmpty) {
        yearsRanked.clear();
        bool done = false;
        for (var element in response.data!) {
          yearsRanked.add(element.year.toString());
          if (element.year == year) {
            district = element.key;
            done = true;
          }
        }
        if (!done) {
          int failedYear = year;
          year = response.data!.last.year;
          district = response.data!.last.key;
          yearsRanked.remove(year);
          throw {
            3,
            'Team $team may not have competed in $failedYear. Redirecting to $year.'
          };
        }
      } else
        throw 2;
    } on DioError catch (e) {
      if (e.response == null)
        throw 'Cannot connect to server.  Check your internet connection!';
      if (e.response!.statusCode != null &&
          e.response!.statusCode == 404 &&
          e.response.toString().contains('does not exist'))
        throw 2; // Choose team, team doesnt exist
      throw e.message;
    } catch (e) {
      if (e is Set && e.first is int && e.first == 3) {
        throw e;
      }
      if (e is int) throw 2;
      throw "4Unknown Error\n" + e.toString();
    }
  }

  Future<void> getTeamAbout() async {
    teamObj = await ApiMgr.api
        .getTeamApi()
        .getTeam(teamKey: 'frc$team')
        .then((value) => value.data!);
  }

  Future<void> getAwards() async {
    awards = await ApiMgr.api
        .getTeamApi()
        .getTeamAwardsByYear(teamKey: 'frc$team', year: year)
        .then((value) => value.data!.asList());
  }

  Future<void> getAvatar() async {
    final response = await ApiMgr.api
        .getTeamApi()
        .getTeamMediaByYear(teamKey: 'frc$team', year: year);

    if (response.data!.isNotEmpty &&
        response.data!.first.details.toString().contains('base64Image')) {
      baseAvatar = response.data!.first.details
          .toString()
          .substring(14, response.data!.first.details.toString().length - 1);
      avatarH = 40;
      avatarW = 60;
    } else {
      baseAvatar = '';
      avatarH = 0;
      avatarW = 0;
    }
  }

  Future<void> getDistrictRankings() async {
    rankings = await ApiMgr.api
        .getDistrictApi()
        .getDistrictRankings(districtKey: district)
        .then((value) => value.data!.asList());
    for (var element in rankings) {
      if (element.teamKey == 'frc$team') {
        districtRank = element.rank;
        return;
      }
    }
  }

  Image createAvatar() {
    if (baseAvatar.isEmpty) {
      baseAvatar =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=';
      avatarW = 0;
      avatarH = 0;
    }
    return Image(
      image: MemoryImage(base64Decode(baseAvatar), scale: 0.75),
      alignment: Alignment.topCenter,
      fit: BoxFit.scaleDown,
      width: avatarW,
      height: avatarH,
    );
  }

  RichText createRankBlock() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
              text: 'Team $team\n',
              style: TextStyle(fontSize: 26, color: Colors.black)),
          TextSpan(
              text: '$districtRankPretty\n',
              style: TextStyle(fontSize: fontRank, color: Colors.blueGrey)),
          TextSpan(
            text: '$districtPretty\n',
            style: TextStyle(fontSize: 22, color: Colors.black),
          ),
          if (year == 2019)
            TextSpan(
              text: DistrictCap(districtKey: district).prettyCapacity(),
              style: TextStyle(fontSize: 22, color: Colors.black),
            ),
        ],
      ),
    );
  }

  Center createAbout() {
    String aboutText = '';
    aboutText += '${teamObj!.nickname}';
    aboutText += '\n\n${teamObj!.name}';
    aboutText += '\n\n${teamObj!.website}';
    aboutText += '\n\nRookie year: ${teamObj!.rookieYear}';
    aboutText += '\n\n${teamObj!.schoolName}';
    aboutText +=
        '\n${teamObj!.city}, ${teamObj!.stateProv}, ${teamObj!.country} ${teamObj!.postalCode}';
    return Center(
      child: Linkify(
        textAlign: TextAlign.center,
        text: aboutText,
        onOpen: _onOpen,
        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
      ),
    );
  }

  Center createAwards() {
    String awardText = '';
    awards.forEach((element) {
      awardText += "\n\n\n${element.name} -- Event: ${element.eventKey}\n";
      if (element.recipientList.isNotEmpty) {
        awardText += '\nGiven to: ';
        element.recipientList.forEach((element) {
          awardText += "${element.awardee ?? ''} (${element.teamKey ?? ''})  ";
        });
      }
    });
    if (awardText.isEmpty)
      awardText = 'This team did not win any awards that year.';
    return Center(
      child: Text(
        awardText,
        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Center createScoring() {
    String scoreInfo;
    for (var element in rankings) {
      if (team.toString() == element.teamKey.substring(3) &&
          element.pointTotal != 0) {
        scoreInfo = '${element.pointTotal} Points';
        if (element.rookieBonus != 0)
          scoreInfo = '${element.rookieBonus} rookie points.';
        scoreInfo += '\n\nEvents:';
        element.eventPoints!.forEach((element2) {
          scoreInfo += '\n\n${element2.eventKey}';
          if (element2.districtCmp) scoreInfo += '\nDistrict Event';
          scoreInfo += '\n${element2.total} Total Points.  Breakdown;';
          scoreInfo += '\nAwards:           ${element2.alliancePoints}';
          scoreInfo += '\nPlayoff:            ${element2.elimPoints}';
          scoreInfo += '\nAlliance:           ${element2.alliancePoints}';
          scoreInfo += '\nQualification:  ${element2.qualPoints}';
        });
        return Center(
            child: Text(
          scoreInfo,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey),
        ));
      }
    }
    return Center(
      child: Text(
        'Team $team does not or has not competed in $year!',
        style: TextStyle(color: Colors.blueGrey),
      ),
    );
  }

  Center createLeaderboard() {
    List<DataRow> rowList = <DataRow>[];
    for (var element in rankings) {
      if (team.toString() == element.teamKey.substring(3)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(element.rank.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.blueGrey))),
          DataCell(Text(
            element.teamKey.substring(3),
            style:
                TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey),
          )),
          DataCell(Text(element.pointTotal.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.blueGrey))),
        ]));
      } else if (6 > (element.rank - districtRank) &&
          -6 < (element.rank - districtRank)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(element.rank.toString(),
              style: TextStyle(color: Colors.blueGrey))),
          DataCell(Text(element.teamKey.substring(3),
              style: TextStyle(color: Colors.blueGrey))),
          DataCell(Text(element.pointTotal.toString(),
              style: TextStyle(color: Colors.blueGrey))),
        ]));
      }
    }
    return Center(
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Text(
              'Rank',
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          ),
          DataColumn(
            label: Text(
              'Team',
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          ),
          DataColumn(
            label: Text(
              'Points',
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          ),
        ],
        rows: rowList,
      ),
    );
  }
}
