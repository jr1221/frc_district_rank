import 'package:appwrite/appwrite.dart';
import 'dart:core';

class ManageAppwrite {
  static Client client = Client();
  static Account account;

  static void initAppwrite() async {
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
        return '${e.response}, ${e.message}, ${e.code}';
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
        return '${e.response}, ${e.message}, ${e.code}';
      }
      return "Unknown error: \n ${e.toString()}";
    }
    return result;
  }

  static Future<bool> logout() async {
    Response result;
    try {
      result = await account.deleteSession(sessionId: 'current');
    } catch (Ignored) {
      return false;
    }
    if (result.statusCode == 204)
      return true;
    else
      return false;
  }

  static Future<bool> logoutAll() async {
    Response result;
    try {
      result = await account.deleteSessions();
    } catch (Ignored) {
      return false;
    }
    if (result.statusCode == 204)
      return true;
    else
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
        return '${e.response}, ${e.message}, ${e.code}';
      }
      return "Unknown error: \n ${e.toString()}";
    }
    return user;
  }

  static Future<String> addPref({String key, String value}) async {
    Response result = await account.updatePrefs(prefs: {key: value});
    if (result.statusCode >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    } else
      return '';
  }
}
