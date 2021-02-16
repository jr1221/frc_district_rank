import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:tba_api_client/api.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:expandable/expandable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';

import 'districtCap.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ConfettiController _confettiController;

  int _districtRank = 0;

  String _district;
  List<Award> _awards;
  List<DistrictRanking> _rankings;
  String _baseAvatar =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=';
  Team _teamObj;

  String _districtRankPretty = '';
  String _districtPretty = '';

  int _team;

  double _fontRank = 60;

  String _year;

  List<String> _yearsRanked = [];

  double _avatarW = 40;
  double _avatarH = 60;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  Future<void> _fillKeys() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('teamNum') == null)
      _team = 1;
    else
      _team = prefs.getInt('teamNum');
    if (prefs.getInt('year') == null)
      _year = '2020';
    else
      _year = prefs.getInt('year').toString();
  }

  Future<void> _addKey({int team, int year}) async {
    final prefs = await SharedPreferences.getInstance();
    if (team != null)
      prefs.setInt('teamNum', team);
    else
      prefs.setInt('year', year);
  }

  Future<bool> _getDistrictKey() async {
    var apiInstance = TeamApi();

    try {
      var value = await apiInstance.getTeamDistricts('frc$_team');
      String lastDistrict = value.last.key;
      _yearsRanked.clear();
      bool done = false;
      for (var element in value) {
        _yearsRanked.add(element.year.toString());
        if (element.year.toString() == _year) {
          _district = element.key;
          done = true;
        }
      }
      if (!done) {
        String failedYear = _year;
        _year = lastDistrict.substring(0, 4);
        _district = lastDistrict;
        _addKey(year: int.parse(_year));
        throw Exception(
            'Team $_team may not have competed in $failedYear. Redirecting to $_year.');
      } else
        return true;
    } catch (e) {
      bool districtMiss;
      String exceptMessage;
      districtMiss = e.toString().contains('may not have');
      if (districtMiss) {
        exceptMessage = e.toString();
      } else {
        exceptMessage =
            'This team does not exist (in recent years), make sure to enter a valid team!';
      }
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => new AlertDialog(
          title: new Text('Error!'),
          content: Text(exceptMessage),
        ),
      );
      if (!districtMiss) {
        _chooseTeam();
        return false;
      } else {
        return true;
      }
    }
  }

  Future<void> _getTeamAbout() async {
    var apiInstance = TeamApi();

    try {
      _teamObj = await apiInstance.getTeam('frc$_team');
    } catch (e) {}
  }

  Future<void> _getAwards() async {
    var apiInstance = TeamApi();

    try {
      _awards =
          await apiInstance.getTeamAwardsByYear('frc$_team', int.parse(_year));
    } catch (e) {}
  }

  Future<void> _getAvatar() async {
    var apiInstance = TeamApi();

    try {
      var value =
          await apiInstance.getTeamMediaByYear('frc$_team', int.parse(_year));
      if (value.first.details.toString().contains('base64Image')) {
        _baseAvatar = value.first.details
            .toString()
            .substring(14, value.first.details.toString().length - 1);
        _avatarH = 40;
        _avatarW = 60;
      } else {
        _baseAvatar =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=';
        _avatarH = 0;
        _avatarW = 0;
      }
    } catch (e) {
      _baseAvatar =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=';
      _avatarH = 0;
      _avatarW = 0;
    }
  }

  Future<void> _getDistrictRankings() async {
    var apiInstance = DistrictApi();

    try {
      _rankings = await apiInstance.getDistrictRankings(_district);
      for (var element in _rankings) {
        if (element.teamKey == 'frc$_team') {
          _districtRank = element.rank;
          return;
        }
      }
    } catch (e) {}
  }

  void _format() {
    _districtPretty = _district.substring(4).toUpperCase() ?? 'N/A';
    _districtPretty += " District";
    switch (_districtRank
        .toString()
        .substring(_districtRank.toString().length - 1)) {
      case '1':
        _districtRankPretty = _districtRank.toString() + 'st';
        break;
      case '2':
        _districtRankPretty = _districtRank.toString() + 'nd';
        break;
      case '3':
        _districtRankPretty = _districtRank.toString() + 'rd';
        break;
      default:
        _districtRankPretty = _districtRank.toString() + 'th';
    }
    switch (_districtRankPretty.length) {
      case 3:
        _fontRank = 80;
        return;
      case 4:
        _fontRank = 56;
        return;
      case 5:
        _fontRank = 50;
        return;
      default:
        _fontRank = 58;
    }
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  _createAbout() {
    if (_teamObj != null && _awards.isNotEmpty) {
      String aboutText = '';
      aboutText += '${_teamObj.nickname}';
      aboutText += '\n\n${_teamObj.name}';
      aboutText += '\n\n${_teamObj.website}';
      aboutText += '\n\nRookie year: ${_teamObj.rookieYear}';
      aboutText += '\n\n${_teamObj.schoolName}';
      aboutText +=
          '\n${_teamObj.city}, ${_teamObj.stateProv}, ${_teamObj.country} ${_teamObj.postalCode}';
      return Linkify(
        text: aboutText,
        onOpen: _onOpen,
        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
      );
    } else
      return Text('No data here:(  Team $_team may not have played in $_year.');
  }

  _createAwards() {
    if (_awards != null && _awards.isNotEmpty) {
      String awardText = '';
      _awards.forEach((element) {
        awardText += "${element.name} -- Event: ${element.eventKey}\n\n";
        if (element.recipientList != null &&
            element.recipientList.isNotEmpty &&
            element.recipientList.first.awardee != null) {
          awardText += '\nGiven to: ';
          element.recipientList.forEach((element) {
            awardText += "${element.awardee} (${element.teamKey})  ";
          });
        }
      });
      return Text(
        awardText,
        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
        textAlign: TextAlign.center,
      );
    } else {
      return Text("No awards in $_year");
    }
  }

  _createScoring() {
    if (_rankings != null && _rankings.isNotEmpty) {
      String scoreInfo;
      for (var element in _rankings) {
        if (_team.toString() == element.teamKey.substring(3)) {
          scoreInfo = '${element.pointTotal} Points';
          if (element.rookieBonus != 0)
            scoreInfo = '${element.rookieBonus} rookie points.';
          scoreInfo += '\n\nEvents:';
          element.eventPoints.forEach((element2) {
            scoreInfo += '\n\n${element2.eventKey}';
            if (element2.districtCmp) scoreInfo += '\nDistrict Event';
            scoreInfo += '\n${element2.total} Total Points.  Breakdown;';
            scoreInfo += '\nAwards:          ${element2.alliancePoints}';
            scoreInfo += '\nPlayoff:           ${element2.elimPoints}';
            scoreInfo += '\nAlliance:          ${element2.alliancePoints}';
            scoreInfo += '\nQualification: ${element2.qualPoints}';
          });
          return Text(scoreInfo);
        }
      }
      return Text('Team $_team does not compete in $_year!');
    } else {
      return Text('Team $_team does not compete in $_year!');
    }
  }

  _createLeaderboard() {
    List<DataRow> rowList = <DataRow>[];
    for (var element in _rankings) {
      if (_team.toString() == element.teamKey.substring(3)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(element.rank.toString(),
              style: TextStyle(fontWeight: FontWeight.w900))),
          DataCell(Text(
            element.teamKey.substring(3),
            style: TextStyle(fontWeight: FontWeight.w900),
          )),
          DataCell(Text(element.pointTotal.toString(),
              style: TextStyle(fontWeight: FontWeight.w900))),
        ]));
      } else if (6 > (element.rank - _districtRank) &&
          -6 < (element.rank - _districtRank)) {
        rowList.add(DataRow(cells: <DataCell>[
          DataCell(Text(element.rank.toString())),
          DataCell(Text(element.teamKey.substring(3))),
          DataCell(Text(element.pointTotal.toString())),
        ]));
      }
    }
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            'Rank',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Team',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Points',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
      rows: rowList,
    );
  }

  _chooseTeam() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Enter Team Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  if (num.tryParse(value) != null) {
                    _team = int.parse(value);
                  } else
                    _team = null;
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      if (_team != null && _team != 0) {
                        await _addKey(team: _team);
                        Navigator.pop(context);
                        _refreshController.requestRefresh();
                      }
                    },
                    child: Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (await _getDistrictKey() == false) {
      _refreshController.refreshCompleted();
      return;
    }
    await _getTeamAbout();
    await _getAwards();
    await _getAvatar();
    await _getDistrictRankings()
        .whenComplete(() => _refreshController.refreshCompleted());
    _format();
    print(_districtRank);
    print(_districtRankPretty);
    print(_year);
    print(_district);
    print(_districtPretty);
    print(_team);
    print(_yearsRanked.toString());
    setState(() {
      _districtRankPretty = _districtRankPretty;
      _fontRank = _fontRank;
      _team = _team;
      _districtPretty = _districtPretty;
      _district = _district;
      _year = _year;
      _yearsRanked = _yearsRanked;
    });
    if (_year == '2019' && DistrictCap(_district).capacity >= _districtRank)
      _confettiController.play();
  }

  Future<void> _initialRef() async {
    await _fillKeys();
    await _onRefresh();
  }

  @override
  void initState() {
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    super.initState();
    _initialRef();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Align conf = Align(
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
    RichText dataText = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
              text: 'Team $_team\n',
              style: TextStyle(fontSize: 26, color: Colors.black)),
          TextSpan(
              text: '$_districtRankPretty\n',
              style: TextStyle(fontSize: _fontRank, color: Colors.blueGrey)),
          TextSpan(
            text: '$_districtPretty\n',
            style: TextStyle(fontSize: 22, color: Colors.black),
          ),
          if (_district != null && _district.substring(0, 4) == '2019')
            TextSpan(
              text: DistrictCap(_district).prettyCapacity(),
              style: TextStyle(fontSize: 22, color: Colors.black),
            ),
        ],
      ),
    );

    Container changeTeam = Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: ElevatedButton(
        onPressed: _chooseTeam,
        child: Text(
          "Choose Team",
          textAlign: TextAlign.center,
        ),
      ),
    );

    Container expanderAbout = Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 20),
      child: ExpandableTheme(
        data: ExpandableThemeData(
          iconColor: Colors.blueGrey,
        ),
        child: ExpandablePanel(
          header: Text(
            "About Team $_team",
            style: TextStyle(fontSize: 20, color: Colors.blueGrey),
          ),
          expanded: _createAbout(),
        ),
      ),
    );
    Container expanderAwards = Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 20),
      child: ExpandableTheme(
        data: ExpandableThemeData(
          iconColor: Colors.blueGrey,
        ),
        child: ExpandablePanel(
          header: Text(
            "Awards",
            style: TextStyle(fontSize: 20, color: Colors.blueGrey),
          ),
          expanded: _createAwards(),
        ),
      ),
    );
    Container expanderScoring = Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 20),
      child: ExpandableTheme(
        data: ExpandableThemeData(
          iconColor: Colors.blueGrey,
        ),
        child: ExpandablePanel(
          header: Text(
            "Scoring",
            style: TextStyle(fontSize: 20, color: Colors.blueGrey),
          ),
          expanded: _createScoring(),
        ),
      ),
    );

    return SmartRefresher(
        enablePullDown: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 5,
            ),
            conf,
            if (_baseAvatar != null)
              Image(
                image: MemoryImage(base64Decode(_baseAvatar), scale: 0.75),
                alignment: Alignment.topCenter,
                fit: BoxFit.scaleDown,
                width: _avatarW,
                height: _avatarH,
              ),
            dataText,
            SizedBox(
              height: 30.0,
            ),
            if (_yearsRanked.isNotEmpty)
              Center(
                child: DropdownButton<String>(
                  value: _year,
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
                  onChanged: (String newValue) {
                    _addKey(year: int.parse(newValue));
                    setState(() {
                      _year = newValue;
                      _refreshController.requestRefresh();
                    });
                  },
                  items: _yearsRanked
                      .map<DropdownMenuItem<String>>((String value) {
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
              ),
            SizedBox(
              height: 20.0,
            ),
            changeTeam,
            expanderAbout,
            expanderAwards,
            expanderScoring,
            if (_rankings != null)
              Container(
                padding: EdgeInsets.only(left: 16, right: 16, top: 20),
                child: ExpandableTheme(
                  data: ExpandableThemeData(
                    iconColor: Colors.blueGrey,
                  ),
                  child: ExpandablePanel(
                    header: Text(
                      "Leaderboard",
                      style: TextStyle(fontSize: 20, color: Colors.blueGrey),
                    ),
                    expanded: _createLeaderboard(),
                  ),
                ),
              ),
          ],
        ));
  }
}
