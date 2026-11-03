# Week 13 automation foundation deliverables

## Application

- Flutter Web dashboard and responsive navigation for workflow and automation views.
- Laravel JSON API for applications, milestones, incomplete records, escalations, and weekly summaries.
- Server-side ordered stage transitions with requirement and offer checks.
- Scheduled escalation and weekly-summary commands; scheduler instructions are in [SETUP_AND_RUN.md](../SETUP_AND_RUN.md).
- Flutter service retries transient GET failures a bounded number of times and never retries permanent business-rule responses.

## Evidence and contracts

- [Workflow boundaries and trust inputs](./week13/WORKFLOW_BOUNDARY_MAP.md)
- [API schemas and status codes](./week13/API_CONTRACT.md)
- [Mock recovery and human-handoff logs](./week13/STRUCTURED_LOGS.md)
- [Maintainability assessment](./week13/MAINTAINABILITY_NOTE.md)

## Verification

Flutter checks: `flutter analyze` and `flutter test` from `frontend/`.
Laravel checks: `php artisan route:list --path=api` and `php artisan schedule:list` from `backend/`.

The local API currently has no authentication or role authorization. It is a development foundation, not a publicly deployable service.
