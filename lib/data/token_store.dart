import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'auth_token';
  int _version = 0;
  Future<void> _pending = Future.value();

  int get version => _version;

  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> save(String token) {
    _version++;
    return _serialize(() => _save(token));
  }

  Future<void> _save(String token) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, token)) {
      throw StateError('Не удалось сохранить токен');
    }
  }

  Future<void> clear() {
    _version++;
    return _serialize(_clear);
  }

  Future<bool> clearIfVersion(int version) {
    if (_version != version) return Future.value(false);
    _version++;
    return _serialize(() async {
      await _clear();
      return true;
    });
  }

  Future<void> _clear() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_key)) {
      throw StateError('Не удалось удалить токен');
    }
  }
}
