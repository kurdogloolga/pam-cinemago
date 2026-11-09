import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment('AUTH_TEST_BASE_URL');

  test(
    'registers, logs in, reports auth errors and logs out against backend',
    () async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousOverrides);
      SharedPreferences.setMockInitialValues({});
      final tokens = TokenStore();
      final auth = AuthApi(baseUrl, tokens);
      final email =
          'auth-test-${DateTime.now().microsecondsSinceEpoch}@example.test';

      expect(
        await auth.register(email, 'password123', 'CinemaGo'),
        isA<Ok<void>>(),
      );
      expect(await tokens.read(), isNotEmpty);

      final duplicate = await auth.register(email, 'password123', 'CinemaGo');
      expect(duplicate, isA<Err<void>>());
      expect(
        (duplicate as Err<void>).msg,
        'Аккаунт с этим email уже существует',
      );

      await auth.logout();
      expect(await tokens.read(), isNull);
      final badLogin = await auth.login(email, 'wrong-password');
      expect(badLogin, isA<Err<void>>());
      expect((badLogin as Err<void>).msg, 'Неверный email или пароль');
      expect(await tokens.read(), isNull);

      expect(await auth.login(email, 'password123'), isA<Ok<void>>());
      expect(await TokenStore().read(), isNotEmpty);
      final profile = await auth.fetchProfile();
      expect(profile, isA<Ok<UserProfile>>());
      expect((profile as Ok<UserProfile>).value.name, 'CinemaGo');
      expect(profile.value.email, email);
      await auth.logout();
      expect(await tokens.read(), isNull);
    },
    skip: baseUrl.isEmpty
        ? 'Set AUTH_TEST_BASE_URL to run against an isolated backend.'
        : false,
  );
}
