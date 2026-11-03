# Week 13 structured log examples

The examples below are representative JSON records, not captured production telemetry. Laravel command events use structured context in the application log. Client-side retry events are mock evidence for the desired observability format; the Flutter client does not yet ship logs to a remote collector.

## Recovered transient failure

```json
{
  "timestamp": "2026-11-03T08:39:45.123Z",
  "level": "info",
  "component": "flutter_api_service",
  "event": "request_recovered_after_retry",
  "correlation_id": "req_4f79c9e8",
  "context": {
    "method": "GET",
    "endpoint": "/api/automation/reminders",
    "attempt": 2,
    "max_retries": 3,
    "previous_status": 503,
    "backoff_ms": 417,
    "outcome": "success",
    "records_returned": 8
  },
  "duration_ms": 691
}
```

The client retries 503 responses with a bounded exponential delay and jitter. It records no student details in this event.

## Permanent business-rule failure routed to a person

```json
{
  "timestamp": "2026-11-03T09:12:33.456Z",
  "level": "warning",
  "component": "laravel_api",
  "event": "workflow.transition_rejected",
  "correlation_id": "req_1ad80d32",
  "context": {
    "method": "PATCH",
    "endpoint": "/api/applications/31/workflow",
    "status_code": 422,
    "error_code": "workflow_requirements_incomplete",
    "requested_stage": "endorsement",
    "human_action_required": true,
    "routing_target": "coordinator_review",
    "retryable": false
  },
  "outcome": "shown_in_coordinator_workflow_ui"
}
```

The example represents a rejected transition because required records remain incomplete. The API response is shown in a permanent failure state with coordinator review steps. No external notification is implied.
