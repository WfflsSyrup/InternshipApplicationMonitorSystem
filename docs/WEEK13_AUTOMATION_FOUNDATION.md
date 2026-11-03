# Week 13 automation foundation

The automation foundation connects the Flutter Web client to a Laravel API backed by MySQL. The application progresses through application, requirement verification, adviser endorsement, partner submission, interview status, and placement confirmation.

Automation includes:

- Due and overdue milestone reminders with coordinator completion actions.
- Incomplete-record alerts with coordinator resolution actions.
- Daily escalation of applications inactive for the configurable threshold (14 days by default).
- A weekly snapshot for the previous complete Monday-Sunday period.
- Explicit loading, success, empty, transient-failure, and business-rule-failure UI states.

See the [API contract](./week13/API_CONTRACT.md), [workflow boundary map](./week13/WORKFLOW_BOUNDARY_MAP.md), [mock structured logs](./week13/STRUCTURED_LOGS.md), [maintainability note](./week13/MAINTAINABILITY_NOTE.md), and [setup instructions](../SETUP_AND_RUN.md).
