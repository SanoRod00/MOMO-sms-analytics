# Authentication Reflection — Basic Auth, JWT, and OAuth2

## What Basic Authentication Does

Basic Authentication works by encoding the username and password in Base64 and sending them in the `Authorization` header on every HTTP request. The server decodes the header, checks the credentials, and either allows or rejects the request with a 401 Unauthorized response.

## Why Basic Auth Is Weak

Basic Auth has several serious limitations that make it unsuitable for production systems:

**Base64 is not encryption.** The credentials are only encoded, not encrypted. Anyone who intercepts the request can decode the header instantly and read the username and password in plain text. This makes Basic Auth dangerous over plain HTTP and only marginally safer over HTTPS.

**Credentials travel on every request.** Because there is no session or token, the username and password must be attached to every single API call. This increases the attack surface — the more requests sent, the more opportunities for the credentials to be intercepted or leaked in logs.

**No expiry.** Basic Auth credentials do not expire. If they are compromised, the attacker has permanent access until the password is manually changed.

**No scopes or roles.** Basic Auth is binary — the user either has access or they do not. There is no way to grant limited permissions, such as read-only access for one client and full access for another.

## How JWT Addresses These Weaknesses

JSON Web Tokens (JWT) replace credentials with a signed token issued at login. The token contains claims (user ID, roles, expiry time) and is cryptographically signed so the server can verify it without storing session state. Tokens expire automatically, and if one is compromised, it becomes useless after the expiry time without requiring a password change.

## How OAuth2 Goes Further

OAuth2 is an authorization framework that separates authentication from resource access. It introduces scopes, allowing clients to request only the permissions they need. It also supports token refresh flows, third-party login, and delegated access — making it the industry standard for securing modern APIs.
