# Week 13 workflow boundary map

## System boundary

```text
Student / coordinator / adviser / partner reviewer
            |
            v
Flutter Web UI (untrusted client, local development)
            |
     HTTP + JSON
            v
Laravel API (validation, stage rules, automation queries)
            |
        Eloquent
            v
MySQL (XAMPP; persistent system of record)
```

The application workflow is bounded to:

1. Application submission
2. Requirement verification
3. Adviser endorsement
4. Partner submission
5. Interview status and offer outcome
6. Placement confirmation

Flutter displays and submits changes, but Laravel is authoritative for stage order, required-document checks, and offer-before-placement rules. MySQL foreign keys and enum constraints provide additional integrity. A workflow validation failure is returned as HTTP 422 and requires a person to correct or review the record.

## Trusted and untrusted inputs

| Input | Trust | Boundary handling |
|---|---|---|
| Flutter JSON payloads | Untrusted | Laravel validates stages, interview outcomes, IDs, and business rules |
| URL path IDs | Untrusted | Eloquent route binding returns 404 for missing records |
| MySQL application and milestone rows | Trusted after server validation | Eloquent relations and database constraints |
| Scheduler invocation | Internal | Laravel command calculates escalation/summary records from persisted state |
| API response data | Untrusted by the browser | Flutter parses expected JSON models and exposes errors as explicit UI states |

## Automation ownership

- **Milestone reminders:** Laravel selects incomplete milestones due within 14 days or overdue; the coordinator can mark a milestone complete.
- **Incomplete-record alerts:** Laravel returns unresolved records; the coordinator can resolve an alert after correcting the source record.
- **Stalled applications:** A daily Laravel command opens an escalation when an in-progress application has had no update for the configured threshold (14 days by default). A successful workflow update resolves its open escalation.
- **Weekly placement summary:** A scheduled command snapshots the previous complete Monday-Sunday week. A unique week-start key makes reruns safe.
- **Human handoff:** A 422 response is not retried. Flutter displays the returned business-rule message and coordinator review steps. No email, SMS, or external ticket service is connected.

## External dependencies and limits

- Flutter Web, Provider, and Dart `http`.
- Laravel 10 / PHP 8.1+ and MySQL through XAMPP.
- Laravel scheduler must be running (or invoked by the host scheduler) for unattended escalation and weekly-summary jobs.
- Local CORS origins are configured in `backend/config/cors.php`; set `CORS_ALLOWED_ORIGINS` for the actual frontend origin.
- API authentication/role authorization is not implemented in this Week 13 local foundation. Keep it on a trusted development host and use synthetic data until that boundary is secured.
