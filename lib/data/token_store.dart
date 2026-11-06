import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'auth_token';

  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  Future<void> save(String token) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, token)) {
      throw StateError('Не удалось сохранить токен');
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_key)) {
      throw StateError('Не удалось удалить токен');
    }
  }
}
