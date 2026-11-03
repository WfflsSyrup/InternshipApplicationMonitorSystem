# Internship Application Monitor: local setup

Workspace layout:

- `frontend/`: Flutter Web client
- `backend/`: Laravel API
- `docs/week13/`: Week 13 boundary map, API contract, logs, and maintainability note

## Prerequisites

- XAMPP with Apache and MySQL
- PHP 8.1+ and Composer
- Flutter 3.9+

## Laravel API and MySQL

1. Start MySQL in the XAMPP control panel and create a database named `internship_monitor` using `utf8mb4_unicode_ci`.
2. Configure `backend/.env` with:

   ```dotenv
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=http://localhost:8000

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=internship_monitor
   DB_USERNAME=root
   DB_PASSWORD=

   AUTOMATION_STALLED_AFTER_DAYS=14
   CORS_ALLOWED_ORIGINS=http://localhost:5000,http://127.0.0.1:5000
   ```

3. Install and initialize Laravel:

   ```powershell
   cd backend
   composer install
   php artisan key:generate
   php artisan migrate
   ```

4. Run the API on port 8000:

   ```powershell
   php artisan serve --host=127.0.0.1 --port=8000
   ```

   Check `http://localhost:8000/api/health`. For Apache hosting instead, configure an Apache virtual host whose `DocumentRoot` points to `backend/public`, enable `mod_rewrite`, and set the matching `APP_URL` and `API_BASE_URL`.

5. To run scheduled automation locally, use a second terminal:

   ```powershell
   cd backend
   php artisan schedule:work
   ```

   The weekly summary is generated Monday at 01:00 for the previous full week. Stalled applications are checked daily at 08:00. You can also run either command manually:

   ```powershell
   php artisan automation:generate-weekly-summary
   php artisan automation:escalate-stalled-applications
   ```

## Flutter Web

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-port=5000
```

The default API base URL is `http://localhost:8000/api`. Override it at build/run time with `--dart-define=API_BASE_URL=http://localhost:8000/api` when the backend origin differs. Keep `CORS_ALLOWED_ORIGINS` aligned with the actual frontend origin.

## Validation

```powershell
cd frontend
flutter analyze
flutter test
```

```powershell
cd backend
php artisan route:list --path=api
php artisan schedule:list
```

The Week 13 API is unauthenticated and intended only for local development with synthetic records. Do not expose it publicly or use real student data until authentication and role-based authorization are implemented.
