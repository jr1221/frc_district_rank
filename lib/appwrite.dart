import 'dart:collection';

import 'package:appwrite/appwrite.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ManageAppwrite {
  static Client client = Client();
  static late Account account;

  static bool loggedIn = false;


  /*
  required to configure appwrite!  Call this only one time ever before any other method is run
   */

  static void initAppwrite() {
    client
            .setEndpoint('https://am.encrypt.se/v1') // Your Appwrite Endpoint
            .setProject('605b81a2cfd2b') // Your project ID
            .setSelfSigned() // Remove in production
        ;
    account = Account(client);
  }

  /*
  Creates a new user with credentails
   */

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
        return e.message ?? '';
      }
      return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  /*
  Takes in email and password and attempts to login, returning pretty error if failure, such as invalid credentials, etc.

  if sendToShared is turned to false, caching credentials will be disabled
   */

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
        return e.message ?? '';
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

  /*
  true/false
   */

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

  /*
  true/false
   */

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
  /*
  Returns true for success and false for failure to delete account
  */
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

  /*
  Gets logged in account information
   */

  static Future<dynamic> getAccount() async {
    Response result;
    try {
      result = await account.get();
    } catch (e) {
      if (e is AppwriteException) {
        return e.message ?? '';
      }
      return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  /*
  Adds or changes preferences taken in by a Map
   */

  static Future<dynamic> updatePrefs(
      {required Map<String, String> prefs}) async {
    Response result;
    try {
      result = await account.updatePrefs(prefs: prefs);
    } catch (e) {
      if (e is AppwriteException) {
        return e.message ?? '';
      } else
        return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    return result;
  }

  /*
  Scenarios:
  1.) Use bool sendAll = true and get back a Map of keys/values
  2.) Use string key and input key to get back a string value
  3.) Use List keyList to get back a Map of keys/values of only your specified keys, if missing a blank string for value is returned

  Any error and an empty string is returned
   */

  static Future<dynamic> getPrefs(
      {bool returnAll = false, String key = '', List<String>? keyList}) async {
    Response result;
    try {
      result = await account.getPrefs();
    } catch (e) {
      if (e is AppwriteException) {
        return e.message ?? '';
      } else
        return "Unknown error: \n ${e.toString()}";
    }
    if (result.statusCode! >= 400) {
      return "Unknown error: \n ${result.statusMessage}";
    }
    if (returnAll) return result.data ?? '';
    if (key.isNotEmpty) return result.data[key] ?? '';
    if (keyList != null && keyList.isNotEmpty) {
      assert(result.data is LinkedHashMap);
      Map<String, String> keyValResult = Map<String, String>();
      for (String keyStrList in keyList)
        keyValResult[keyStrList] = result.data[keyStrList] ?? '';
      return keyValResult;
    }
    return '';
  }
}
