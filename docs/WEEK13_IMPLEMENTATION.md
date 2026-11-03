# Week 13 implementation

The current interface uses a light, minimalist Material 3 design with responsive dashboard cards, workflow overview, reminder and incomplete-record actions, stalled escalation review, and weekly placement metrics.

The client uses Provider for view state and a typed API service for JSON transport. GET requests retry only transient network and server failures with bounded exponential backoff and jitter. HTTP business-rule failures are not retried and are presented with coordinator intervention steps.

The Laravel API validates ordered workflow transitions, enforces requirement/offer prerequisites, and exposes read and completion routes. Scheduled commands create stalled-application escalations and weekly placement snapshots.

For local setup, route contracts, trust boundaries, example logs, and known limitations, see [SETUP_AND_RUN.md](../SETUP_AND_RUN.md) and the [Week 13 documentation](./week13/WORKFLOW_BOUNDARY_MAP.md).
