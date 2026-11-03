# Week 14 adverse-request evidence

The backend feature suite exercises the API with an in-memory SQLite database and no XAMPP service. Run it from `backend/` with:

```powershell
composer dump-autoload
php vendor\bin\phpunit
```

| Adverse request | Expected evidence |
|---|---|
| Empty/invalid login payload | HTTP 422 field validation; no exception trace |
| Valid account with altered password | HTTP 401; no exception trace |
| Altered bearer token | HTTP 401; no exception trace |
| Expired bearer token | HTTP 401; no exception trace |
| Partner reviewer requesting coordinator automation | HTTP 403; no exception trace |
| Student requesting workflow mutation | HTTP 403; no exception trace |
| Student listing applications | Only own record returned, with student name/ID omitted |

The Flutter API service separately maps 400/422, 401, and 403 to fixed user-safe messages. It never uses server response bodies as UI text; a 401 clears the in-memory session.

## Latest run

`php vendor\bin\phpunit` from `backend/`: **passed, 10 tests and 36 assertions**. Flutter tests also pass, including the login-to-dashboard route and the 400/401/403/422 safe-message checks.
