# Week 13 full-stack foundation

The workspace is split into `frontend/` (Flutter Web) and `backend/` (Laravel API). The Flutter dashboard connects to Laravel over JSON HTTP; Laravel uses Eloquent and MySQL migrations for the workflow and automation records.

## Delivered

- Responsive dashboard with workflow, reminders, incomplete records, escalations, and weekly summary screens.
- Ordered server-validated workflow progression, interview outcomes, milestone completion, and incomplete-record resolution.
- Bounded retry for transient GET failures; permanent HTTP business failures are surfaced for coordinator review.
- Laravel migrations, read APIs, workflow endpoints, stalled-application escalation job, and weekly-summary job.
- Local development setup and automation scheduler instructions in [SETUP_AND_RUN.md](../SETUP_AND_RUN.md).

## Detailed documentation

- [API contract](./week13/API_CONTRACT.md)
- [Workflow boundary map](./week13/WORKFLOW_BOUNDARY_MAP.md)
- [Structured log examples](./week13/STRUCTURED_LOGS.md)
- [Maintainability note](./week13/MAINTAINABILITY_NOTE.md)

The API is unauthenticated in this local Week 13 foundation. Do not expose it or use real student data until authentication and role-based authorization are added.
