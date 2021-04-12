import 'package:appwrite/appwrite.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:frc_district_rank/appwrite.dart';
import 'package:loading_overlay/loading_overlay.dart';

class ShowLogin extends StatefulWidget {
  @override
  ShowLoginState createState() {
    return ShowLoginState();
  }
}

class ShowLoginState extends State<ShowLogin> {
  final _formKey = GlobalKey<FormState>();

  String _email;
  String _password;
  String _name;

  bool _saving = false;

  String _messageLoggedOut = '';

  var sessionUser;

  SimpleDialog noAccount = SimpleDialog(
    title: Text(
        "Account not found.  Please check email or password, or create a new account below."),
  );

  Future<void> _createAcc() async {
    setState(() {
      _saving = true;
    });
    var resp = await ManageAppwrite.createUser(
        email: _email, password: _password, name: _name);
    setState(() {
      _saving = false;
    });
    print(resp);
    print(resp.runtimeType);
    String respPretty = '';
    if (resp is Response) {
      respPretty = "Successful account creation.  Please login now.";
    } else if (resp is String) {
      respPretty = 'Error: ' + resp;
    }
    SimpleDialog acc = SimpleDialog(
      title: Text(respPretty),
      titleTextStyle: TextStyle(color: Colors.blueGrey),
      titlePadding: EdgeInsets.all(12),
    );
    await showDialog(context: context, builder: (_) => acc);
  }

  Future<void> _loginAcc() async {
    setState(() {
      _saving = true;
    });
    final resp = await ManageAppwrite.createSession(
      email: _email,
      password: _password,
    );
    setState(() {
      _saving = false;
    });
    String respPretty = '';
    if (resp is Response) {
      respPretty = "Successful Login";
    } else if (resp is String) {
      respPretty = 'Error: ' + resp;
    }
    SimpleDialog acc = SimpleDialog(
      title: Text(respPretty),
      titlePadding: EdgeInsets.all(12),
      titleTextStyle: TextStyle(color: Colors.blueGrey),
    );
    await showDialog(context: context, builder: (_) => acc);
    if (resp is Response) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (ManageAppwrite.loggedIn)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/account', (Route<dynamic> route) => false);
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!ManageAppwrite.loggedIn)
      return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: LoadingOverlay(
            isLoading: _saving,
            child: ListView(
              children: [
                Form(
                  child: Column(
                    children: <Widget>[
                      if (_messageLoggedOut.isNotEmpty)
                        Text(
                          _messageLoggedOut,
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      Text("Already have an account? Sign in here."),
                      TextFormField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Email",
                        ),
                        onChanged: (value) {
                          _email = value;
                        },
                      ),
                      TextFormField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          _password = value;
                        },
                        onFieldSubmitted: (value) async {
                          await _loginAcc();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await _loginAcc();
                          },
                          child: Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Text("First time logging in? Create account here."),
                      TextFormField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Name",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          _name = value;
                          return null;
                        },
                      ),
                      TextFormField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Email",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!EmailValidator.validate(value)) {
                            return 'Please check your email';
                          }
                          _email = value;
                          return null;
                        },
                      ),
                      TextFormField(
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            helperText: "Must be at least 6 characters",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            if (value.length < 6) {
                              return 'Please use 6 or more characters';
                            }
                            return null;
                          },
                          obscureText: true,
                          onChanged: (value) {
                            _password = value;
                          }),
                      TextFormField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Confirm Password",
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          if (value != _password ||
                              _password == null ||
                              _password.length < 6) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              await _createAcc();
                            }
                          },
                          child: Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
