# Security Policy

## Overview

This document outlines the security practices and features implemented in the PESU OAuth2 server. Our OAuth2 implementation is fully compliant with [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749) standards and incorporates multiple layers of security to protect user data and ensure secure authentication flows.

## Security Features

### Data Protection

-   **User credentials encrypted** with AES-256-GCM (via jose)
-   **Client secrets hashed** with bcryptjs before storage
-   **Secure token generation** with nanoid
-   **PKCE support** for public clients (future implementation)
-   **State parameter validation** for CSRF protection

### Client Secret Security

-   Client secrets are hashed using bcryptjs with salt rounds
-   Plain text secrets are only shown once during registration
-   Secret verification during token exchange uses bcryptjs.compare()
-   No way to retrieve original secret after hashing

### Headers & Middleware

-   **Helmet** for security headers
-   **CORS configuration** properly configured
-   **Request validation** with Zod schemas
-   **Rate limiting middleware** for DDoS protection

## Rate Limiting

To prevent abuse and ensure service availability, the following rate limits are enforced:

-   **OAuth endpoints**: 1000 requests/hour per client
-   **User API (cached)**: 100 requests/hour per access token
-   **User API (fetch live)**: 12 requests/hour per user (1 per 5 minutes)
-   **Admin endpoints**: 500 requests/hour per admin
-   **Client registration**: 10 registrations/hour per IP

## Client Registration Security

### Eligibility Requirements

To maintain security and ensure proper use of the OAuth2 system, client registration is restricted to:

-   **PESU students only**: Must have valid PESU credentials
-   **Verified email required**: Email address must be verified in PESU records
-   **Authentication required**: Must authenticate with PESU credentials before registration

### Terms Compliance and Enforcement

-   **Terms of Service**: All registered applications must comply with PESU OAuth2 Terms of Service
-   **Monitoring**: Client applications are subject to compliance monitoring
-   **Violation consequences**: Any violations of terms will result in:
    -   Immediate suspension of client credentials
    -   Inability to use suspended credentials for OAuth2 flows
    -   Potential permanent revocation for severe violations
-   **Appeal process**: Suspended clients may appeal through designated channels

### Registration Process Security

-   **Email verification check**: System validates email verification status with PESU records
-   **CSRF protection**: Form submissions protected against cross-site request forgery
-   **Rate limiting**: Maximum 10 registrations per hour per IP address
-   **Audit logging**: All registration attempts are logged for security monitoring

## Token Strategy

### Token Types & Expiration

-   **Access Tokens**: 7 days (nanoid, 32 chars)
-   **Refresh Tokens**: 30 days (nanoid, 48 chars)
-   **Authorization Codes**: 10 minutes (nanoid, 24 chars)
-   **Admin Sessions**: 8 hours (nanoid, 32 chars)

### Token Format

Using `nanoid` instead of JWT for shorter tokens:

-   Access token: `nanoid(32)` → ~21 characters
-   Refresh token: `nanoid(48)` → ~32 characters
-   Admin session: `nanoid(32)` → ~21 characters

Token metadata is stored in the database with nanoid as the lookup key, providing better security than self-contained tokens.

## Monitoring & Logging _(Future Scope)_

### Audit Logging

-   Token generation and revocation events
-   Failed authentication attempts
-   Admin actions and permission changes
-   Client registration and modifications

### Security Monitoring

-   Rate limiting bypass attempts
-   Suspicious authorization patterns
-   Token usage anomalies
-   Geographic access patterns

### Performance Metrics

-   Response times for OAuth2 endpoints
-   PESU Auth API latency and success rates
-   Database query performance
-   Token validation performance

### Alerting

-   Failed authentication rate thresholds
-   PESU Auth service downtime
-   Database connection issues

## Environment Variables Security

Ensure these environment variables are properly secured:

```env
# Database
MONGODB_URL=mongodb://localhost:27017/pesu-oauth2

# Encryption key for user credentials (AES-256, exactly 32 characters)
ENCRYPTION_KEY=your-32-character-encryption-key-here

# PESU Auth Integration
PESU_AUTH_URL=https://pesu-auth.onrender.com/authenticate

# Your OAuth2 server base URL
OAUTH_BASE_URL=https://your-domain.com
```

### Security Requirements

-   **ENCRYPTION_KEY**: Must be exactly 32 characters for AES-256
-   **MONGODB_URL**: Should use authentication in production
-   **Environment isolation**: Use different keys for dev/staging/production

## Supported Vulnerability Disclosure

### Reporting Security Issues

If you discover a security vulnerability, please follow these guidelines to report it responsibly:

-   **Do NOT** open a public issue to report security problems.
-   Instead, send a confidential message to the maintainers via the PESU Developer Group channel (`#pesu-dev`) on [PESU Discord](https://discord.gg/eZ3uFs2), or email the maintainers directly.
-   Include as much detail as possible:
    -   Steps to reproduce the issue
    -   Impact of the vulnerability
    -   Any suggested mitigations or fixes

### Response Timeline

-   **Initial Response**: Within 24 hours
-   **Vulnerability Assessment**: Within 72 hours
-   **Patch Development**: Timeline depends on severity
-   **Public Disclosure**: After patch is deployed (coordinated disclosure)

## Security Best Practices for Developers

### For Client Applications

1. **Store client secrets securely** - Never expose in client-side code
2. **Validate state parameters** - Prevent CSRF attacks
3. **Use HTTPS only** - All OAuth2 flows must use secure connections
4. **Implement proper token storage** - Use secure storage mechanisms
5. **Handle token expiration** - Implement refresh token flows
6. **Comply with Terms of Service** - Adhere to PESU OAuth2 usage policies
7. **Respect user privacy** - Only request necessary scopes and handle data responsibly
8. **Monitor for suspension** - Check for credential validity and handle suspension gracefully

### For OAuth2 Server Deployment

1. **Use environment variables** for all secrets
2. **Enable rate limiting** in production
3. **Monitor logs** for suspicious activities
4. **Keep dependencies updated** - Regular security updates
5. **Use HTTPS certificates** - Valid SSL/TLS configuration

## Compliance

### Standards Compliance

-   **RFC 6749** - OAuth 2.0 Authorization Framework
-   **RFC 7662** - OAuth 2.0 Token Introspection
-   **RFC 6750** - Bearer Token Usage

### Security Headers

The application implements the following security headers via Helmet:

-   Content Security Policy (CSP)
-   X-Frame-Options
-   X-Content-Type-Options
-   Referrer-Policy
-   Permissions-Policy

## Contact

For security-related questions or concerns:

-   **PESU Discord**: `#pesu-dev` on [PESU Discord](https://discord.gg/eZ3uFs2)
-   **General Support**: Create an issue in this repository
-   **Documentation**: See main [README.md](../README.md) for usage information
