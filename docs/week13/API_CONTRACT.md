# Week 13 API contract

Base URL for local development: `http://localhost:8000/api`

All responses use JSON. List endpoints return a JSON array, including when there are no records (`[]`). IDs are integers. Dates use `YYYY-MM-DD`; timestamps use ISO 8601.

## Automation and workflow endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Local API health check |
| GET | `/automation/reminders` | Up to 100 incomplete milestones due within 14 days or overdue |
| GET | `/automation/incomplete-records` | Up to 100 unresolved record alerts |
| GET | `/automation/escalations` | Up to 100 open/in-progress stalled-application escalations |
| GET | `/automation/weekly-summary` | Up to four most recent weekly placement summaries |
| GET | `/applications` | Up to 100 most recently updated application workflow records |
| PATCH | `/applications/{id}/workflow` | Advance one workflow stage or update interview status |
| PATCH | `/milestones/{id}/complete` | Mark a requirement milestone complete |
| PATCH | `/incomplete-records/{id}/resolve` | Resolve an incomplete-record alert |

### Automation response examples

`GET /automation/reminders`:

```json
[
  {
    "id": 18,
    "student_name": "Avery Chen",
    "student_id": "STU-24018",
    "reminder_type": "requirement",
    "message": "Endorsement letter: Upload the signed adviser letter.",
    "due_date": "2026-11-06",
    "is_completed": false,
    "priority": "high"
  }
]
```

`GET /automation/incomplete-records`:

```json
[
  {
    "id": 7,
    "student_name": "Avery Chen",
    "student_id": "STU-24018",
    "missing_field": "endorsement_letter",
    "record_type": "application",
    "severity": "high",
    "days_incomplete": 3,
    "last_updated": "2026-11-01"
  }
]
```

`GET /automation/escalations`:

```json
[
  {
    "id": 4,
    "student_name": "Jordan Lee",
    "student_id": "STU-24027",
    "application_id": 31,
    "escalation_reason": "No workflow activity for 14 days.",
    "escalation_level": "medium",
    "status": "open",
    "assigned_to": "Unassigned",
    "days_stalled": 14,
    "escalated_at": "2026-11-03"
  }
]
```

`GET /automation/weekly-summary`:

```json
[
  {
    "id": 2,
    "week_label": "Week 44, 2026",
    "week_start": "2026-10-26",
    "week_end": "2026-11-01",
    "total_applications": 45,
    "applications_submitted": 38,
    "applications_reviewed": 35,
    "interviews_scheduled": 22,
    "offers_received": 15,
    "placements_confirmed": 12,
    "rejected": 8,
    "pending_review": 10,
    "placement_rate": 26.67
  }
]
```

`GET /applications` returns `id`, `application_number`, `student_name`, `student_id`, `company_name`, `position`, `stage`, `workflow_state`, `interview_status`, and `updated_at`.

### Workflow updates

Request:

```json
{
  "stage": "endorsement"
}
```

Allowed stages, in order: `application`, `verification`, `endorsement`, `partner_submission`, `interview`, `placement_confirmation`.

At the `interview` stage, update the outcome without advancing:

```json
{
  "stage": "interview",
  "interview_status": "offer_received"
}
```

Interview statuses are `not_scheduled`, `scheduled`, `completed`, `offer_received`, and `declined`. Stages can advance only one step at a time. Moving from verification to endorsement requires all linked requirement milestones completed and incomplete-record alerts resolved. Placement confirmation requires `offer_received`. A declined interview marks the application rejected. Successful updates return HTTP 200 with a `data` object containing the current `stage`, `workflow_state`, and `interview_status`.

The workflow update returns:

```json
{
  "data": {
    "id": 31,
    "stage": "endorsement",
    "workflow_state": "in_progress",
    "interview_status": "not_scheduled",
    "updated_at": "2026-11-03T09:12:33+00:00"
  },
  "message": "Application workflow updated."
}
```

`PATCH /milestones/{id}/complete` and `PATCH /incomplete-records/{id}/resolve` accept an empty JSON object and return HTTP 200 with the record `id`, its updated boolean (`is_completed` or `resolved`), its corresponding timestamp, and a message. Repeating either request is safe and preserves the original completion timestamp.

### Status codes and error shape

| Status | Meaning | Client behavior |
|---|---|---|
| 200 | Request completed; empty lists are valid | Render returned data |
| 404 | Application, milestone, or record does not exist | Show a permanent record/access failure |
| 422 | Invalid payload or workflow/business rule violation | Do not retry; direct the user to coordinator review |
| 429 | Rate limit reached | Retry with bounded backoff |
| 500-599 | Temporary server failure | Retry with bounded backoff, then offer manual retry |

Laravel validation errors use:

```json
{
  "message": "Resolve all missing records and required documents before endorsement.",
  "errors": {
    "stage": [
      "Resolve all missing records and required documents before endorsement."
    ]
  }
}
```

All API routes are currently intended for a local Week 13 development environment and are not authenticated. Do not expose this API or real student data outside that environment until authentication and role-based authorization are added.
