# cinemago

A new Flutter project.

## Local backend (L5)

Start the .NET server from `server` with `dotnet run`. Login, registration,
movies, screenings and reservations use the server. A new database starts with
an empty catalog; movies and screenings must first be added through the API.
For example, after registering an account in the app, use PowerShell with the
same email and password:

```powershell
$base = 'http://localhost:8080'
$login = @{ email = 'your-email@example.com'; password = 'your-password' } | ConvertTo-Json
$auth = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $login
$headers = @{ Authorization = "Bearer $($auth.token)" }
$movie = @{ title = 'Тестовый фильм'; genre = 'Драма'; durationMin = 120; posterUrl = ''; rating = 8 } | ConvertTo-Json
$createdMovie = Invoke-RestMethod -Method Post -Uri "$base/movies" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($movie))
$screening = @{ movieId = $createdMovie.id; hall = 'Зал 1'; dateTime = '2027-10-10T18:00:00+02:00'; price = 100 } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$base/screenings" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($screening))
```

Replace the example credentials and screening date. These commands add real
records to the server database; use a test account and database when testing.
The profile's personal details are still static placeholders.

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

This test creates a user, a movie and a screening in that test database.
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
