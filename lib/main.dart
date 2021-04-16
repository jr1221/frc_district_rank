import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:frc_district_rank/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ApiMgr.dart';
import 'account.dart';
import 'home_rank.dart';
import 'login.dart';
import 'constants.dart';

void main() {
  ApiMgr.init();
  runApp(MyApp());
  ManageAppwrite.initAppwrite();
  autoLogin();
}

Future<void> autoLogin() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final email = prefs.get('email');
  final password = prefs.get('password');
  if (email != null && password != null) {
    final String decryptedPass = Constants.encrypter
        .decrypt(Encrypted.fromBase64(password), iv: Constants.iv);
    await ManageAppwrite.createSession(email: email, password: decryptedPass);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/account': (context) => AccountInfo(),
        '/login': (context) => ShowLogin(),
      },
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
      actions: [
        IconButton(
            onPressed: () {
              if (ManageAppwrite.loggedIn)
                Navigator.pushNamed(context, '/account');
              else
                Navigator.pushNamed(context, '/login');
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
                "Powered by The Blue Alliance https://www.thebluealliance.com",
          ),
        ),
      ],
    );
  }
}
