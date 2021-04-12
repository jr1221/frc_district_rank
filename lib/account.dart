import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appwrite.dart';

class AccountInfo extends StatefulWidget {
  @override
  _AccountInfoState createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  String _email = 'Loading...';
  String _name = 'Loading...';

  Future<void> _logOut({bool ofAll}) async {
    if (ofAll)
      await ManageAppwrite.logoutAll();
    else
      await ManageAppwrite.logout();
    if (!ManageAppwrite.loggedIn)
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  Future<void> _deleteAccount() async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Delete account?'),
              content: Text(
                  'This will delete all user preferences and data automatically.  You will not be able to recreate your account!'),
              actions: [
                ElevatedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    return;
                  },
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Yes, delete account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ));
    await ManageAppwrite.deleteAccount();
    if (!ManageAppwrite.loggedIn) {
      SharedPreferences.getInstance().then((value) => value.clear());
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  Future<void> _addUserInfo() async {
    var result = await ManageAppwrite.getAccount();
    if (result is Response)
      setState(() {
        _name = result.data['name'];
        _email = result.data['email'];
      });
  }

  @override
  void initState() {
    super.initState();
    if (!ManageAppwrite.loggedIn)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      });
    else
      _addUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (ManageAppwrite.loggedIn)
      return Scaffold(
        appBar: AppBar(
          title: Text("Login Status"),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_name',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_email',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    await _logOut(ofAll: false);
                  },
                  child: Text("Logout"),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    await _logOut(ofAll: true);
                  },
                  child: Text("Logout from all devices"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () async {
                    //await _deleteAccount();
                  },
                  child: Text("Delete Account"),
                ),
              ),
            ],
          ),
        ),
      );
    else {
      return Container(
        height: 0,
        width: 0,
      );
    }
  }
}
