import 'package:shared_preferences/shared_preferences.dart';

class SharedUtil {
  static const String SP_LOGIN_TOKEN = "SP_LOGIN_TOKEN";
  static const String EXPIRES_IN = "expires_in";
  static const String safe_password_key = "safe_password_key";
  static const String safe_password = "safe_password";
  static const String m3u8_file_list = "m3u8_file_list";
  static const String m3u8_file_list_lock = "m3u8_file_list_lock";
  static const String downloading_url = "downloading_url";
  static const String downloading_url_list = "downloading_url_list";

  static SharedPreferences preferences;
  static Future<bool> getInstance() async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    return true;
  }

  static Future<void> initEnVir() async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
  }

  static Future saveString(String key, String value) async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    preferences.setString(key, value);
  }

  static String getString(key) {
    if (preferences == null) return null;
    return preferences.getString(key);
  }

  static Future setStringList(String key, List<String> value) async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    preferences.setStringList(key, value);
  }

  static List<String> getStringList(key) {
    if (preferences == null) return null;
    return preferences.getStringList(key);
  }

  static Future<String> getAuthorization(Function(String) tokenCall) async {
    if (preferences == null) return null;
    tokenCall(preferences.getString(SharedUtil.SP_LOGIN_TOKEN));
    return preferences.getString(SharedUtil.SP_LOGIN_TOKEN);
  }

  static Future saveInt(String key, int value) async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    preferences.setInt(key, value);
  }

  static int getInt(key) {
    if (preferences == null) return null;
    return preferences.getInt(key);
  }

  static Future saveDouble(String key, double value) async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    preferences.setDouble(key, value);
  }

  static double getDouble(key) {
    if (preferences == null) return null;
    return preferences.getDouble(key);
  }

  static Future saveBool(String key, bool value) async {
    if (preferences == null) {
      preferences = await SharedPreferences.getInstance();
    }
    preferences.setBool(key, value);
  }

  static bool getBool(key) {
    if (preferences == null) return null;
    return preferences.getBool(key);
  }

  static Future deleteUserInfo(String key) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove(key);
  }
}
