# Week 14 cryptography justification

## Protection objectives

- **Password storage:** `User::$casts['password'] = 'hashed'` delegates password storage to Laravel's configured hasher, and login verifies with `Hash::check`. With this repository's Laravel 10 defaults the hasher falls back to bcrypt. This is a one-way password verifier intended to make database disclosure insufficient to recover plaintext passwords directly. It is not encryption and there is no password-decryption path. Provision accounts with `Hash::make` or the hashed model cast; do not import plaintext credentials.
- **API bearer tokens:** Sanctum returns the random plaintext token only at login and stores its SHA-256 digest in `personal_access_tokens`. The digest supports verification without retaining a replayable bearer credential in the database. Tokens expire after eight hours and logout revokes the current token.
- **Configuration secrets:** database credentials and `APP_KEY` are read from the ignored backend `.env` file. `.env.example` contains placeholders only. The MySQL application account should have only the required schema privileges.

## What this does not protect

These controls do not encrypt application records, database files, backups, logs, or network traffic. Local XAMPP development may use HTTP; any deployment carrying credentials, bearer tokens, or student data must terminate TLS with HTTPS. Protect MySQL storage/backups and restrict database and filesystem access separately. Keep `APP_DEBUG=false` outside isolated development.
