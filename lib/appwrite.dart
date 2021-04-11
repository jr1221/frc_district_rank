import 'package:appwrite/appwrite.dart';
import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ManageAppwrite {
  static Client client = Client();
  static Account account;

  static bool loggedIn = false;

  static void initAppwrite()  {
    client
            .setEndpoint('https://am.encrypt.se/v1') // Your Appwrite Endpoint
            .setProject('605b81a2cfd2b') // Your project ID
            .setSelfSigned() // Remove in production
        ;
    account = Account(client);
  }

  static Future<dynamic> createUser(
      {String email, String password, String name}) async {
    Response result;
    try {
      await account.deleteSessions();
    } catch (Ignored) {}
    try {
      result = await account.create(
        email: email,
        password: password,
        name: name,
      );
      if (result.statusCode >= 400) {
        return "Unknown error: \n ${result.statusMessage}";
      }
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    return result;
  }

  static Future<dynamic> createSession({String email, String password}) async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (Ignored) {}
    Response result;
    try {
      result = await account.createSession(
        email: email,
        password: password,
      );
      if (result.statusCode >= 400) {
        return "Unknown error: \n ${result.statusMessage}";
      }
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    loggedIn = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("email", email);
    prefs.setString('password',
        Constants.encrypter.encrypt(password, iv: Constants.iv).base64);
    return result;
  }

  static Future<bool> logout() async {
    Response result;
    try {
      result = await account.deleteSession(sessionId: 'current');
    } catch (e) {
      if (e is AppwriteException) {
        return false;
      } else
        return false;
    }
    if (result.statusCode == 204) {
      loggedIn = false;
      return true;
    } else
      return false;
  }

  static Future<bool> logoutAll() async {
    Response result;
    try {
      result = await account.deleteSessions();
    } catch (e) {
      if (e is AppwriteException) {
        return false;
      } else
        return false;
    }
    if (result.statusCode == 204) {
      loggedIn = false;
      return true;
    } else
      return false;
  }

  static Future<dynamic> getAccount() async {
    var user;
    try {
      user = await account.get();
      if (user.statusCode >= 400) {
        return "Unknown error: \n ${user.statusMessage}";
      }
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    return user;
  }

  static Future<dynamic> addPref({String key, String value}) async {
    var result;
    try {
      result = await account.updatePrefs(prefs: {key: value});
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      } else
        return "Unknown error: \n ${e.toString()}";
    }
    return result;
  }
}
