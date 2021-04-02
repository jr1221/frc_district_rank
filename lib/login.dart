import 'package:appwrite/appwrite.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:frc_district_rank/appwrite.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class Login extends StatefulWidget {
  @override
  LoginState createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  String _email;
  String _password;
  String _name;

  bool _loggedIn = false;
  bool _saving = false;

  String _messageLoggedOut = '';

  var sessionUser;

  SimpleDialog noAccount = SimpleDialog(
    title: Text(
        "Account not found.  Please check email or password, or create a new account below."),
  );

  Future<void> _checkLoggedIn() async {
    setState(() {
      _saving = true;
    });
    var result = await ManageAppwrite.getAccount();
    if (result is String) {
      setState(() {
        _saving = false;
        _loggedIn = false;
      });
    } else
      setState(() {
        _loggedIn = true;
        _saving = false;
      });
  }

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
      respPretty = 'Error: ' + resp.substring(resp.indexOf('{message:')+10, resp.indexOf(','));
    }
    SimpleDialog acc = SimpleDialog(
      title: Text(respPretty),
      titleTextStyle: TextStyle(color: Colors.blueGrey),
      titlePadding: EdgeInsets.all(12),
    );
    await showDialog(context: context, builder: (_) => acc);
    await _checkLoggedIn();
  }

  Future<void> _loginAcc() async {
    setState(() {
      _saving = true;
    });
    var resp = await ManageAppwrite.createSession(
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
      respPretty = 'Error: ' + resp.substring(resp.indexOf('{message:')+10, resp.indexOf(','));
    }
    SimpleDialog acc = SimpleDialog(
      title: Text(respPretty),
      titlePadding: EdgeInsets.all(12),
      titleTextStyle: TextStyle(color: Colors.blueGrey),
    );
    await showDialog(context: context, builder: (_) => acc);
    await _checkLoggedIn();
  }

  Future<void> _logOut({bool ofAll}) async {
    setState(() {
      _saving = true;
    });
    bool respBool;
    if (ofAll)
      respBool = await ManageAppwrite.logoutAll();
    else
      respBool = await ManageAppwrite.logout();
    setState(() {
      _saving = false;
    });
    if (!respBool) {
      SimpleDialog cannotLogout = SimpleDialog(
        title: Text("Error logging out!"),
      );
      await showDialog(context: context, builder: (_) => cannotLogout);
    }
    else
      setState(() {
        _loggedIn = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn)
      return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ModalProgressHUD(
            inAsyncCall: _saving,
            color: Colors.blueGrey,
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
                          }),
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
    else
      return Scaffold(
        appBar: AppBar(
          title: Text("Login Status"),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: [
              /* Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_name',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ), */
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_email',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
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
                  child: Text("Logout from all devices."),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
