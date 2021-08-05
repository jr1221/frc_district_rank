import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ApiMgr.dart';
import 'home_rank.dart';

void main() {
  ApiMgr.init();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: Scaffold(
        body: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      title: Text('FRC District Ranking'),
      centerTitle: true,
    );
    return Scaffold(
      appBar: appBar,
      body: HomePage(),
      persistentFooterButtons: [
        Container(
          child: Linkify(
            style: TextStyle(
              fontSize: 12,
            ),
            onOpen: _onOpen,
            textAlign: TextAlign.left,
            text:
                "Powered by The Blue Alliance https://www.thebluealliance.com",
          ),
        ),
      ],
    );
  }
}
