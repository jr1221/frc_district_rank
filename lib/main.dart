import 'package:flutter/material.dart';
import 'package:frc_district_rank/appwrite.dart';
import 'package:tba_api_client/api.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_rank.dart';
import 'ApiKey.dart';
import 'login.dart';

void main() {
  ManageAppwrite.initAppwrite();
  defaultApiClient.getAuthentication<ApiKeyAuth>('apiKey').apiKey =
      ApiKey.TBAKey;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  String _lastModified = '';

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  Future<void> _getStatus() async {
    var apiInstance = TBAApi();

    try {
      var value = await apiInstance.getStatusWithHttpInfo();
      value.headers.forEach((key, value) {
        if (key == "last-modified") {
          setState(() {
            _lastModified = value;
          });
          return;
        }
      });
    } catch (e) {
      print("$e");
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => new AlertDialog(
          title: new Text('Error!'),
          content: Text('$e'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getStatus();
  }

  Future selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      title: Text('FRC District Ranking'),
      centerTitle: true,
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
            icon: const Icon(Icons.login)),
      ],
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
                "Data last modified on $_lastModified\nPowered by The Blue Alliance https://www.thebluealliance.com",
          ),
        ),
      ],
    );
  }
}
