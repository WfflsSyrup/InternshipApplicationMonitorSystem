# Internship Monitor Web client

Flutter Web client for the Internship Application Monitor. It connects to the Laravel API using `API_BASE_URL`, which defaults to `http://localhost:8000/api`.

```powershell
flutter pub get
flutter run -d chrome --web-port=5000
```

Run `flutter analyze` and `flutter test` to validate the client. See the repository-level [setup guide](../SETUP_AND_RUN.md) for Laravel, XAMPP, CORS, and scheduler instructions.

The Week 13 API is unauthenticated and is intended only for local development with synthetic data.
