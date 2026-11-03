# Week 14 security residual risks

## Covered threats

- Missing, altered, expired, and revoked bearer credentials are rejected by Sanctum authentication. Login attempts are rate-limited.
- Role middleware restricts routes, while record queries scope application data and related mutations to coordinator scope or the user's assigned student/adviser/partner relationship.
- Student and partner-reviewer application responses omit student names and student IDs. Login responses expose only token plus user ID, display name, and role.
- Laravel request validation restricts login/workflow inputs. Flutter validates login inputs and presents fixed status-specific error messages instead of server JSON or exception text.
- `.env` is ignored; the sample environment uses placeholders, disables debug output, and requires explicit CORS origins.

## Remaining risks and required deployment controls

- **Transport security:** local XAMPP/Flutter can use HTTP. HTTPS is mandatory before exposing the API beyond a trusted local machine.
- **Token handling in browsers:** the Flutter Web session keeps the bearer token in memory and requires a new sign-in after reload. Cross-site scripting could still access a live in-memory token; apply a restrictive Content Security Policy, avoid unsafe HTML, and review dependencies.
- **No encryption at rest:** personal/application data and token digests rely on MySQL host, volume, and backup protections. Enable encrypted storage/backups where required.
- **Account lifecycle:** provisioning, password reset, MFA, lockout policy, account disablement, and audit review are not implemented here. Create accounts through trusted administrative processes and disable compromised accounts promptly.
- **CORS is not authorization:** deployments must set the exact frontend origin(s); browsers enforce CORS but non-browser clients do not.
- **Role assignment is a trust boundary:** role values and application assignment foreign keys must be changed only by trusted administrators. The current schema uses the existing four-value `users.role` enum rather than a separate permission-management system.
- **Operational monitoring:** application logs do not yet provide a complete security audit trail, alerting, or retention policy. Configure protected central logging without passwords, bearer tokens, or unnecessary student data.
- **Business workflow policy:** role/stage permissions reflect the stated Week 14 boundaries. Confirm operational owners before production because additional approval or separation-of-duty requirements may apply.
