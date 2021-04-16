import 'package:appwrite/appwrite.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ManageAppwrite {
  static Client client = Client();
  static late Account account;

  static bool loggedIn = false;

  static void initAppwrite() {
    client
            .setEndpoint('https://am.encrypt.se/v1') // Your Appwrite Endpoint
            .setProject('605b81a2cfd2b') // Your project ID
            .setSelfSigned() // Remove in production
        ;
    account = Account(client);
  }

  static Future<dynamic> createUser(
      {required String email,
      required String password,
      required String name}) async {
    Response result;
    if (loggedIn)
      try {
        await account.deleteSessions();
      } catch (Ignored) {}
    try {
      result = await account.create(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  static Future<dynamic> createSession(
      {required String email,
      required String password,
      bool sendToShared = true}) async {
    if (loggedIn)
      try {
        await account.deleteSession(sessionId: 'current');
      } catch (Ignored) {}
    Response result;
    try {
      result = await account.createSession(
        email: email,
        password: password,
      );
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    loggedIn = true;
    if (sendToShared) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("email", email);
      prefs.setString('password',
          Constants.encrypter.encrypt(password, iv: Constants.iv).base64);
    }
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

  static Future<bool> deleteAccount() async {
    Response result;
    try {
      result = await account.delete();
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
    Response result;
    try {
      result = await account.get();
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      }
      return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  static Future<dynamic> updatePref(
      {required String key, required String value}) async {
    Response result;
    try {
      result = await account.updatePrefs(prefs: {key: value});
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      } else
        return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  static Future<dynamic> getPrefs(
      {bool getAll = false, required String key}) async {
    Response result;
    try {
      result = await account.getPrefs();
    } catch (e) {
      if (e is AppwriteException) {
        return e.message;
      } else
        return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    if (getAll) return result;
    return result.data[key];
  }
}
