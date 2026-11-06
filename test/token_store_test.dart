import 'package:cinemago/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'other_setting': 'keep'});
  });

  test('returns null before a token is saved', () async {
    expect(await TokenStore().read(), isNull);
  });

  test('saves and reads the token from another store instance', () async {
    await TokenStore().save('test-token');

    expect(await TokenStore().read(), 'test-token');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('auth_token'), 'test-token');
    expect(preferences.getKeys(), {'auth_token', 'other_setting'});
  });

  test('replaces an existing token and clears only the token', () async {
    final store = TokenStore();
    await store.save('old-token');
    await store.save('new-token');
    expect(await store.read(), 'new-token');

    await store.clear();
    expect(await TokenStore().read(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('other_setting'), 'keep');
  });
}
