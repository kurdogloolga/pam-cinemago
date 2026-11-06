# cinemago

A new Flutter project.

## Local backend authentication (L5)

Start the .NET server from `server` with `dotnet run`. During this stage, login
and registration use the server, while the cinema catalog and tickets still
use mock data.

The default server address is `http://10.0.2.2:8080` on the Android emulator
and `http://localhost:8080` on desktop or web. For a physical device, pass the
computer's local network address when launching, for example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Replace the example address with the computer's actual address. Android debug
builds allow HTTP for this local laboratory server; production deployments
should use HTTPS.

To run the optional authentication integration test against a running server:

```powershell
flutter test --no-pub --dart-define=AUTH_TEST_BASE_URL=http://127.0.0.1:8080 test\auth_api_integration_test.dart
```

The test registers a unique user in the server's database, so use a test
database rather than one containing data you want to keep unchanged.

The HTTP cinema repository can also be tested against an isolated server:

```powershell
flutter test --no-pub --dart-define=AUTH_TEST_BASE_URL=http://127.0.0.1:8080 test\http_cinema_repository_integration_test.dart
```

This test creates a user, a movie and a screening in that test database. Until
the next integration stage, the application itself still uses mock cinema data.
The server's movie schema has no year, director or description; the interface
indicates that these details are unavailable when they are not supplied.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
