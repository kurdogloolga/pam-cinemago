# CinemaGo backend template checks

This is a locally authored smoke/conformance suite for the .NET template in
`../server`. It is not the original course `05_Backend/conformance` kit and
does not claim to reproduce its 37 checks.

Run the backend in one terminal:

```powershell
cd ..\server
dotnet run
```

In another terminal, run the checks:

```powershell
cd ..\conformance
dart pub get
dart run bin\conformance.dart --base-url http://localhost:8080
```

The runner checks the template's health, authentication, protected notes CRUD,
pagination/search, standard errors, and file upload/download over HTTP. It
creates a uniquely named test account and file; the note it creates is deleted
before the run finishes.
