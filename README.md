# Internship Application Monitor

A local-development full-stack foundation for tracking internship applications from initial application through requirements verification, endorsement, partner submission, interviews, and placement confirmation.

The project is split into a Flutter Web client and a Laravel API backed by MySQL. The API owns workflow validation and scheduled automation; the Flutter client presents workflow and coordinator-focused automation views with explicit loading, empty, network-error, and business-rule states.

> **Development and security notice:** The Week 13 API is currently unauthenticated. Run it only on a trusted local development machine with synthetic data. Do not expose it publicly or use real student records until authentication, role-based authorization, and production security controls have been implemented.

## Contents

- [Project capabilities](#project-capabilities)
- [Workflow and business rules](#workflow-and-business-rules)
- [Architecture](#architecture)
- [Technology requirements](#technology-requirements)
- [Local setup](#local-setup)
- [Configuration](#configuration)
- [API overview](#api-overview)
- [Automation and scheduling](#automation-and-scheduling)
- [Validation and tests](#validation-and-tests)
- [Project structure](#project-structure)
- [Known limitations and production readiness](#known-limitations-and-production-readiness)
- [Documentation](#documentation)

## Project capabilities

### Flutter Web client

- Responsive dashboard and application workflow views.
- Views for upcoming and overdue milestone reminders, incomplete records, stalled-application escalations, and weekly placement summaries.
- Explicit loading, populated, empty, transient network-error, and permanent business-rule failure states.
- API service with bounded retries for transient GET failures. Permanent client/business errors are surfaced without retry; state-changing PATCH requests are not retried.
- Provider-based dashboard state management.

### Laravel API and MySQL

- JSON API for reading application and automation data.
- Server-side validation of workflow transitions and interview outcomes.
- Migration-defined application, milestone, incomplete-record, escalation, and weekly-summary data.
- Scheduled escalation and weekly-summary generation.
- Structured Laravel log context for important automation and workflow events.

## Workflow and business rules

Applications progress through these stages, in order:

1. `application`
2. `verification`
3. `endorsement`
4. `partner_submission`
5. `interview`
6. `placement_confirmation`

The API is authoritative and only permits advancing one stage at a time. Before moving from verification to endorsement, required milestones must be complete and incomplete-record alerts must be resolved. Placement confirmation requires an `offer_received` interview outcome. A `declined` outcome marks the application rejected.

The API returns HTTP `422 Unprocessable Entity` when a submitted transition violates a workflow rule. The client treats this as a permanent, human-reviewable error rather than retrying it.

## Architecture

```text
Student or coordinator
        |
        v
Flutter Web client (frontend/)
        |  HTTP + JSON
        v
Laravel API (backend/)
        |  Eloquent ORM
        v
MySQL database (XAMPP)

Laravel scheduler --> stalled-application escalations
                  --> weekly placement summaries
```

Flutter is a client, not a trusted enforcement boundary. Laravel validates input and workflow rules, and MySQL persists application state. No external email, SMS, or ticketing provider is connected.

## Technology requirements

- Windows with PowerShell (commands below use PowerShell syntax).
- XAMPP with MySQL. Apache is optional when using `php artisan serve`.
- PHP 8.1 or later and Composer.
- Flutter/Dart SDK satisfying the frontend constraint (`^3.9.0`).
- A modern browser such as Chrome or Edge.

The backend uses Laravel 10, MySQL, and Laravel Sanctum as a declared dependency. Sanctum authentication is **not currently applied to these API routes**.

## Local setup

### 1. Create the database

Start MySQL from the XAMPP Control Panel. Create a database named `internship_monitor` with the `utf8mb4_unicode_ci` collation. For example, in phpMyAdmin or a MySQL client:

```sql
CREATE DATABASE internship_monitor
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

### 2. Configure and run the Laravel API

In PowerShell:

```powershell
cd backend
Copy-Item .env.example .env
```

Edit `backend/.env` and set at least:

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

Use the database credentials configured for your XAMPP installation. Then install dependencies, create the application key, and run migrations:

```powershell
composer install
php artisan key:generate
php artisan migrate
```

Start the local API:

```powershell
php artisan serve --host=127.0.0.1 --port=8000
```

Verify that it responds:

```powershell
Invoke-RestMethod http://localhost:8000/api/health
```

The expected response is `{"status":"ok"}`. Keep the API process running in this terminal.

### 3. Run the Flutter Web client

Open a second PowerShell terminal:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-port=5000
```

The client uses `http://localhost:8000/api` by default. If the API runs at a different origin, provide the full API base URL:

```powershell
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8000/api
```

The browser origin must be permitted by the backend CORS configuration. Configure `CORS_ALLOWED_ORIGINS` to match the actual frontend origin.

### 4. Start scheduled automation (optional)

For local development, open a third terminal:

```powershell
cd backend
php artisan schedule:work
```

This keeps Laravel's scheduler running. See [Automation and scheduling](#automation-and-scheduling) for job times and manual commands.

## Configuration

| Setting | Default | Description |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000/api` | Flutter API origin and base path; can be overridden with `--dart-define`. |
| `DB_CONNECTION` | `mysql` | Laravel database driver. |
| `DB_HOST` | `127.0.0.1` | MySQL host. |
| `DB_PORT` | `3306` | MySQL port. |
| `DB_DATABASE` | `internship_monitor` | Database name used by this setup. |
| `AUTOMATION_STALLED_AFTER_DAYS` | `14` | Inactivity threshold for stalled in-progress applications. |
| `CORS_ALLOWED_ORIGINS` | Local port 5000 origins | Comma-separated frontend origins allowed by the local API configuration. |

Do not commit `.env` files, credentials, or production secrets.

## API overview

Local base URL: `http://localhost:8000/api`

All endpoints return JSON. List endpoints return arrays, including `[]` when there are no results.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | API health check. |
| `GET` | `/applications` | List up to 100 recently updated applications. |
| `PATCH` | `/applications/{id}/workflow` | Advance one workflow stage or update interview status. |
| `GET` | `/automation/reminders` | List incomplete milestones due within 14 days or overdue. |
| `GET` | `/automation/incomplete-records` | List unresolved incomplete-record alerts. |
| `GET` | `/automation/escalations` | List open or in-progress stalled-application escalations. |
| `GET` | `/automation/weekly-summary` | List up to four recent weekly summaries. |
| `PATCH` | `/milestones/{id}/complete` | Mark a requirement milestone complete. |
| `PATCH` | `/incomplete-records/{id}/resolve` | Resolve an incomplete-record alert. |

Example workflow transition:

```http
PATCH /api/applications/31/workflow
Content-Type: application/json
```

```json
{
  "stage": "endorsement"
}
```

Interview outcome updates use the `interview` stage:

```json
{
  "stage": "interview",
  "interview_status": "offer_received"
}
```

Common response codes:

| Status | Meaning |
|---|---|
| `200` | Request succeeded. Empty list responses are valid. |
| `404` | The requested application, milestone, or record was not found. |
| `422` | Payload validation or workflow/business rule failed; do not retry automatically. |
| `429` | Rate limit reached; the client may retry eligible GET requests with bounded backoff. |
| `5xx` | Server error; the client may retry eligible GET requests with bounded backoff. |

For response schemas, field definitions, and complete request examples, see the [API contract](docs/week13/API_CONTRACT.md).

## Automation and scheduling

- **Milestone reminders:** API query returns incomplete milestones that are overdue or due within 14 days.
- **Incomplete-record alerts:** API query returns unresolved alerts for coordinator review.
- **Stalled applications:** The daily job creates an escalation for an in-progress application with no activity past `AUTOMATION_STALLED_AFTER_DAYS` (14 days by default). A workflow update resolves an open escalation.
- **Weekly placement summary:** The weekly job snapshots the previous complete Monday-Sunday period. A unique week-start key makes rerunning a week safe.

The Laravel scheduler is configured for a daily stalled-application check at 08:00 and a weekly summary at Monday 01:00. Run `schedule:work` in a local terminal, or configure the host scheduler in a deployed environment. To invoke either job immediately:

```powershell
cd backend
php artisan automation:escalate-stalled-applications
php artisan automation:generate-weekly-summary
```

Inspect registered schedules with:

```powershell
php artisan schedule:list
```

## Validation and tests

Run the Flutter static analyzer and tests:

```powershell
cd frontend
flutter analyze
flutter test
```

Inspect Laravel API routes and scheduled tasks:

```powershell
cd backend
php artisan route:list --path=api
php artisan schedule:list
```

After running the migrations, review database migration state:

```powershell
php artisan migrate:status
```

The Flutter tests cover transient GET retry recovery, no retry for permanent HTTP errors, and the dashboard/workflow UI. MySQL-backed endpoint integration should be verified against a locally configured database.

## Project structure

```text
internship_monitor/
├── backend/
│   ├── app/Http/Controllers/Api/  # Workflow and automation endpoints
│   ├── app/Console/Commands/      # Scheduled summary and escalation jobs
│   ├── config/                   # API, CORS, and automation configuration
│   ├── database/migrations/      # MySQL schema
│   └── routes/api.php            # API route declarations
├── docs/
│   └── week13/                   # API, boundaries, logs, maintainability
├── frontend/
│   ├── lib/models/               # API response models
│   ├── lib/providers/            # UI state management
│   ├── lib/screens/              # Dashboard and workflow screens
│   ├── lib/services/             # HTTP API service
│   └── test/                     # Flutter tests
└── README.md
```

## Known limitations and production readiness

- **Authentication and authorization are not enabled.** Sanctum is present as a dependency, but the current API routes are unauthenticated. Add authentication, role-based permissions, and authorization tests before exposing the service or entering real student data.
- **Use synthetic records locally.** Keep the application bound to a trusted development environment until security controls are implemented.
- **Initial workflow data is not provided through an intake UI/API.** Applications, milestones, and incomplete-record alerts need to be created or loaded through an upstream or manual process.
- **No external notifications are sent.** Reminders and escalations are represented in persisted records and surfaced through the UI; email, SMS, and ticketing integrations are out of scope.
- **Scheduler availability matters.** Scheduled jobs do not run unless Laravel's scheduler is active or invoked by the host.
- **Database integration is environment-dependent.** Configure XAMPP MySQL and run migrations before exercising data-backed endpoint behavior.
- **Production hardening remains.** Add audit history, data-retention controls, pagination, queued notification delivery, and centralized telemetry as appropriate for the deployment.

## Documentation

- [API contract](docs/week13/API_CONTRACT.md) — request/response shapes, endpoints, and status codes.
- [Workflow boundary map](docs/week13/WORKFLOW_BOUNDARY_MAP.md) — trust boundaries, system ownership, and external dependencies.
- [Structured log examples](docs/week13/STRUCTURED_LOGS.md) — representative transient recovery and human-review failure events.
- [Maintainability note](docs/week13/MAINTAINABILITY_NOTE.md) — design seams, operational considerations, and follow-up improvements.
