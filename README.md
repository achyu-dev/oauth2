# PESU OAuth2

A comprehensive OAuth2 provider built with Next.js, integrating with PESU Academy authentication system, fully compliant with [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749) standards.

## Overview

This OAuth2 server allows applications to authenticate PESU students and access their profile information through standardized OAuth2 flows as defined in [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749). It acts as a bridge between the PESU authentication system and third-party applications.

## Technical Stack

-   **Framework**: Next.js 15.4.6 with TypeScript and App Router
-   **Database**: MongoDB with Prisma ORM
-   **Authentication**: Integration with PESU Auth API
-   **Tokens**: nanoid-based tokens (shorter than JWT)
-   **Security**: jose, bcryptjs, helmet
-   **Package Manager**: pnpm

## Dependencies

```json
{
    "dependencies": {
        "@prisma/client": "latest",
        "prisma": "latest",
        "jose": "latest", // For PESU credential encryption
        "bcryptjs": "latest", // For client secret hashing
        "nanoid": "latest", // For OAuth2 and admin session tokens
        "zod": "latest", // For request validation
        "helmet": "latest" // For security headers
    }
}
```

## Environment Variables

```env
# Database
MONGODB_URL=mongodb://localhost:27017/pesu-oauth2

# Encryption key for user credentials (AES-256, exactly 32 characters)
ENCRYPTION_KEY=your-32-character-encryption-key-here
ENCRYPTION_KEY_VERSION=1

# PESU Auth Integration
PESU_AUTH_URL=https://pesu-auth.onrender.com/authenticate

# Your OAuth2 server base URL
OAUTH_BASE_URL=https://your-domain.com
```

## Database Schema

### Collections

#### OAuth2Applications

```prisma
model OAuth2Application {
  id            String   @id @default(auto()) @map("_id") @db.ObjectId
  clientId      String   @unique
  clientSecret  String
  name          String
  description   String?
  redirectUris  String[]
  scopes        String[]
  autoApprove   Boolean  @default(false)
  ownerId       String?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}
```

#### Users

```prisma
model User {
  id                    String   @id @default(auto()) @map("_id") @db.ObjectId
  pesuprn               String   @unique
  srn                   String?
  profileData           Json
  encryptedCredentials  String?  // For fetch_live
  lastFetchLive         DateTime?
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
}
```

#### AuthorizationCodes

```prisma
model AuthorizationCode {
  id          String   @id @default(auto()) @map("_id") @db.ObjectId
  code        String   @unique
  clientId    String
  userId      String
  scopes      String[]
  redirectUri String
  expiresAt   DateTime
  createdAt   DateTime @default(now())
}
```

#### AccessTokens

```prisma
model AccessToken {
  id        String   @id @default(auto()) @map("_id") @db.ObjectId
  tokenId   String   @unique
  userId    String
  clientId  String
  scopes    String[]
  expiresAt DateTime
  createdAt DateTime @default(now())
}
```

#### RefreshTokens

```prisma
model RefreshToken {
  id        String   @id @default(auto()) @map("_id") @db.ObjectId
  tokenId   String   @unique
  userId    String
  clientId  String
  expiresAt DateTime
  createdAt DateTime @default(now())
}
```

#### Admins

```prisma
model Admin {
  id          String   @id @default(auto()) @map("_id") @db.ObjectId
  email       String   @unique
  pesuprn     String   @unique
  permissions String[] // ['clients', 'users', 'analytics']
  createdAt   DateTime @default(now())
  createdBy   String?
  active      Boolean  @default(true)
}
```

#### AdminSessions

```prisma
model AdminSession {
  id        String   @id @default(auto()) @map("_id") @db.ObjectId
  sessionId String   @unique
  adminId   String
  expiresAt DateTime
  createdAt DateTime @default(now())
}
```

## API Endpoints

### OAuth2 Endpoints

In accordance with [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749), the OAuth2 endpoint URLs will only accept a content type of `application/x-www-form-urlencoded`. JSON content is not permitted and will return an error.

#### `POST /api/oauth2/authorize`

Authorization endpoint for OAuth2 flow.

**Parameters:**

-   `client_id` (required): Client application identifier
-   `redirect_uri` (required): Callback URL
-   `scope` (required): Requested scopes (space-separated)
-   `response_type` (required): Must be "code"
-   `state` (optional): CSRF protection

**Response:**

-   Redirects to PESU authentication
-   After auth, redirects to `redirect_uri` with authorization code
-   Authorization code expires in 10 minutes

#### `POST /api/oauth2/token`

Token exchange endpoint.

**Parameters:**

-   `grant_type` (required): "authorization_code" or "refresh_token"
-   `code` (required for auth code): Authorization code
-   `refresh_token` (required for refresh): Refresh token
-   `client_id` (required): Client identifier
-   `client_secret` (required): Client secret
-   `redirect_uri` (required for auth code): Must match authorize request

**Response:**

```json
{
    "access_token": "abc123xyz",
    "refresh_token": "def456uvw",
    "token_type": "Bearer",
    "expires_in": 604800,
    "scope": "profile:name:read profile:email:read"
}
```

#### `POST /api/oauth2/introspect`

Token introspection endpoint ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662)).

**Parameters:**

-   `token` (required): Token to introspect
-   `client_id` (required): Client identifier
-   `client_secret` (required): Client secret

**Response:**

```json
{
    "active": true,
    "scope": "profile:name:read profile:email:read",
    "client_id": "original_client",
    "username": "PES1201800001",
    "exp": 1723456789
}
```

#### `POST /api/oauth2/revoke`

Token revocation endpoint.

**Parameters:**

-   `token` (required): Token to revoke
-   `client_id` (required): Client identifier
-   `client_secret` (required): Client secret

### User Data API

#### `GET /api/v1/user`

Get user profile information.

**Headers:**

-   `Authorization: Bearer {access_token}`

**Query Parameters:**

-   `fetch_live` (optional): Set to "true" for live data fetch from PESU auth

**Response:**

```json
{
    "name": "Johnny Blaze",
    "prn": "PES1201800001",
    "srn": "PES1201800001",
    "program": "Bachelor of Technology",
    "branch": "Computer Science and Engineering",
    "semester": "NA",
    "section": "NA",
    "email": "johnnyblaze@gmail.com",
    "phone": "1234567890",
    "campus_code": 1,
    "campus": "RR"
}
```

_Note: Response includes only fields within granted scopes_

### Client Management

#### `POST /api/oauth2/clients/register`

Register a new OAuth2 client (open registration).

**Parameters:**

-   `name` (required): Application name
-   `description` (optional): Application description
-   `redirect_uris` (required): Array of callback URLs
-   `scopes` (required): Array of requested scopes

**Response:**

```json
{
    "client_id": "generated_client_id",
    "client_secret": "generated_client_secret",
    "name": "My App",
    "redirect_uris": ["https://myapp.com/callback"],
    "scopes": ["profile:name:read", "profile:email:read"]
}
```

### Admin Endpoints

#### `GET /api/admin/clients`

List all OAuth2 clients (admin only).

#### `GET /api/admin/tokens`

Monitor active tokens (admin only).

#### `GET /api/admin/stats`

Usage analytics (admin only).

## Error Responses

All OAuth2 endpoints return standardized error responses following [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2) specifications.

### OAuth2 Error Response Format

```json
{
    "error": "invalid_request",
    "error_description": "The request is missing a required parameter",
    "error_uri": "https://your-domain.com/docs/errors#invalid_request"
}
```

### Common Error Codes

#### Authorization Endpoint Errors

-   **`invalid_request`** - Missing or malformed parameters
-   **`unauthorized_client`** - Client not authorized for this grant type
-   **`access_denied`** - User denied the authorization request
-   **`unsupported_response_type`** - Response type not supported
-   **`invalid_scope`** - Requested scope is invalid or unknown
-   **`server_error`** - Internal server error occurred
-   **`temporarily_unavailable`** - Service temporarily overloaded

#### Token Endpoint Errors

-   **`invalid_request`** - Missing or malformed parameters
-   **`invalid_client`** - Client authentication failed
-   **`invalid_grant`** - Authorization code/refresh token invalid
-   **`unauthorized_client`** - Client not authorized for this grant
-   **`unsupported_grant_type`** - Grant type not supported
-   **`invalid_scope`** - Requested scope exceeds granted scope

#### User API Errors

-   **`invalid_token`** - Access token expired or invalid
-   **`insufficient_scope`** - Token lacks required scope for resource
-   **`rate_limit_exceeded`** - Too many requests (includes retry-after header)

### HTTP Status Codes

-   **400 Bad Request** - Invalid request parameters
-   **401 Unauthorized** - Authentication required or failed
-   **403 Forbidden** - Insufficient permissions
-   **404 Not Found** - Resource not found
-   **429 Too Many Requests** - Rate limit exceeded
-   **500 Internal Server Error** - Server error
-   **503 Service Unavailable** - PESU Auth temporarily unavailable

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
-   Encryption key rotation failures

## Available Scopes

Scopes follow a hierarchical structure: `{category}:{field}:{permission}`

### Current Scope Categories

#### Profile Scopes

Access to user identity and personal information:

-   `profile:name:read` - User's full name
-   `profile:prn:read` - PRN (PESU Registration Number)
-   `profile:srn:read` - SRN (Student Registration Number)
-   `profile:program:read` - Academic program
-   `profile:branch:read` - Academic branch/department
-   `profile:semester:read` - Current semester
-   `profile:section:read` - Class section
-   `profile:email:read` - Email address
-   `profile:phone:read` - Phone number
-   `profile:campus_code:read` - Campus code (1=RR, 2=EC)
-   `profile:campus:read` - Campus abbreviation

### Future Scope Categories

#### Classes Scopes (Planned)

Access to academic class information:

-   `classes:enrolled:read` - List of enrolled classes
-   `classes:schedule:read` - Class schedules and timings
-   `classes:faculty:read` - Faculty information for classes

#### Attendance Scopes (Planned)

Access to attendance records:

-   `attendance:summary:read` - Overall attendance percentage
-   `attendance:detailed:read` - Detailed attendance records

### Scope Permission Levels

-   `:read` - Read-only access to the specified data
-   `:write` - Write access (future implementation for user-updatable fields)

### Scope Usage Examples

```
# Request only basic identity
scope=profile:name:read profile:srn:read

# Request contact information
scope=profile:email:read profile:phone:read

# Request full profile access
scope=profile:name:read profile:prn:read profile:srn:read profile:program:read profile:branch:read profile:semester:read profile:section:read profile:email:read profile:phone:read profile:campus_code:read profile:campus:read

# Future: Mixed category access
scope=profile:name:read classes:enrolled:read attendance:summary:read
```

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

Token metadata stored in database with nanoid as lookup key.

## Rate Limiting

-   **OAuth endpoints**: 1000 requests/hour per client
-   **User API (cached)**: 100 requests/hour per access token
-   **User API (fetch live)**: 12 requests/hour per user (1 per 5 min)
-   **Admin endpoints**: 500 requests/hour per admin
-   **Client registration**: 10 registrations/hour per IP

## Security Features

### Data Protection

-   User credentials encrypted with AES-256-GCM (via jose)
-   Client secrets hashed with bcryptjs before storage
-   Secure token generation with nanoid
-   PKCE support for public clients (future)
-   State parameter validation

### Client Secret Security

-   Client secrets are hashed using bcryptjs with salt rounds
-   Plain text secrets are only shown once during registration
-   Secret verification during token exchange uses bcryptjs.compare()
-   No way to retrieve original secret after hashing

### Encryption Key Rotation

-   Automated key rotation via GitHub Actions every 3 months
-   Manual rotation trigger available for immediate updates
-   Zero-downtime migration of existing encrypted credentials
-   Versioned encryption keys for seamless transitions

### Headers & Middleware

-   Helmet for security headers
-   CORS configuration
-   Request validation with Zod
-   Rate limiting middleware

## PESU Auth Integration

### Caching Strategy

-   Cache user profiles in MongoDB
-   Reduce PESU auth API calls
-   Fetch live option for real-time data

### Fetch Live Flow

1. Client requests with `?fetch_live=true`
2. Decrypt stored user credentials
3. Re-authenticate with PESU auth
4. Update cached profile data
5. Return fresh data

### Rate Limits

-   Standard cache hits: No additional limits
-   Fetch live: Stricter limits (1 per 5 minutes)

## Client Consent Flow

Following Discord OAuth2 model:

### Consent Options

-   **Auto-approve**: For trusted clients (admin-configured)
-   **Skip consent**: Same client + user + same/subset scopes
-   **Force consent**: Always show consent screen (default)

### Consent Screen

-   Clear scope descriptions
-   Application information
-   Allow/Deny options
-   Remember choice option

## API Versioning

### Strategy

-   **Base URL**: `/api/` automatically points to the latest version
-   **Versioned URLs**: `/api/v{version}/` for specific versions (e.g., `/api/v1/`, `/api/v2/`)
-   **Graceful deprecation**: 12 months support for older versions
-   **Clear migration documentation** for version transitions

### URL Structure Example

```
# Latest version (automatically updated)
https://your-domain.com/api/user

# Explicit version specification
https://your-domain.com/api/v1/user
https://your-domain.com/api/v2/user

# Base URL redirects to latest
https://your-domain.com/api/user → https://your-domain.com/api/v1/user
```

### Deprecation Headers

```http
API-Version: v1
Sunset: 2026-08-11
Link: </api/v2/user>; rel="successor-version"
```

### Future Versions

```
/api/v1/              # Current version
├── user              # User profile endpoint
└── (current scopes)

/api/v2/              # Future enhanced version
├── user              # Enhanced user endpoint
└── academic/         # New scope categories
    ├── grades        # Academic performance
    ├── attendance    # Attendance records
    └── schedule      # Class schedules
```

## Development Phases

### Phase 1: Core Infrastructure

-   [ ] Prisma setup with MongoDB
-   [ ] Database schema implementation
-   [ ] PESU auth integration service
-   [ ] Basic token management
-   [ ] User profile caching

### Phase 2: OAuth2 Endpoints

-   [ ] Authorization endpoint (`/oauth2/authorize`)
-   [ ] Token endpoint (`/oauth2/token`)
-   [ ] User info endpoint (`/v1/user`)
-   [ ] Token introspection (`/oauth2/introspect`)
-   [ ] Token revocation (`/oauth2/revoke`)

### Phase 3: Client Management

-   [ ] Client registration system
-   [ ] Client authentication
-   [ ] Redirect URI validation
-   [ ] Scope validation

### Phase 4: Security & Middleware

-   [ ] Rate limiting implementation
-   [ ] Request validation middleware
-   [ ] Security headers setup
-   [ ] Encryption service for credentials

### Phase 5: Admin & Monitoring

-   [ ] Admin authentication system
-   [ ] Client management interface
-   [ ] Token monitoring dashboard
-   [ ] Usage analytics

### Phase 6: Frontend & Documentation

-   [ ] OAuth consent screen
-   [ ] Client registration form
-   [ ] Admin dashboard
-   [ ] Developer documentation
-   [ ] API examples and SDKs

## Encryption Key Rotation

### Overview

The system supports automated encryption key rotation to enhance security. User credentials are encrypted with versioned keys, allowing seamless transitions during rotation.

### GitHub Actions Setup

#### Required Repository Secrets

```
MONGODB_URL                    # Database connection string
ENCRYPTION_KEY                # Current encryption key (32 characters)
ENCRYPTION_KEY_VERSION        # Current version number (e.g., "1")
GH_ADMIN_TOKEN                # GitHub Personal Access Token (repo scope)
NETLIFY_ACCESS_TOKEN          # Netlify API token
NETLIFY_SITE_ID               # Netlify site identifier
```

#### Implementation Files

The key rotation system requires two files:

1. **`.github/workflows/key-rotation.yml`** - GitHub Actions workflow

    - Manual trigger via `workflow_dispatch`
    - Automatic quarterly rotation via cron schedule
    - Generates new encryption keys securely
    - Updates GitHub secrets and Netlify environment variables
    - Masks sensitive values in action logs

2. **`scripts/rotate-keys.js`** - Database migration script

    - Finds users with outdated encryption key versions
    - Decrypts credentials with current key
    - Re-encrypts with new key version
    - Updates user records with new encryption version
    - Provides migration progress logging

### Usage

#### Manual Rotation

Trigger rotation immediately through GitHub Actions interface or via GitHub CLI.

#### Automatic Schedule

-   Runs every 3 months automatically
-   Updates all platforms simultaneously
-   Zero downtime for users

### Security Benefits

-   **Periodic rotation** limits exposure time of compromised keys
-   **Versioned keys** allow gradual migration without service interruption
-   **Automated process** eliminates manual key management errors
-   **Cross-platform sync** ensures consistency across GitHub and Netlify

## Usage Examples

### Authorization Flow

```
1. Redirect user to authorization endpoint
GET /api/oauth2/authorize?client_id=abc&redirect_uri=https://app.com/callback&scope=profile%3Aname%3Aread%20profile%3Aemail%3Aread&response_type=code&state=xyz

2. User authenticates with PESU credentials

3. User grants/denies consent

4. Redirect back with authorization code
https://app.com/callback?code=auth_code&state=xyz

5. Exchange code for tokens
POST /api/oauth2/token
{
  "grant_type": "authorization_code",
  "code": "auth_code",
  "client_id": "abc",
  "client_secret": "secret",
  "redirect_uri": "https://app.com/callback"
}

6. Use access token to fetch user data
GET /api/v1/user
Authorization: Bearer access_token
```

### Client Registration

```javascript
const response = await fetch("/api/oauth2/clients/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
        name: "My PESU App",
        description: "An app for PESU students",
        redirect_uris: ["https://myapp.com/callback"],
        scopes: [
            "profile:name:read",
            "profile:email:read",
            "profile:branch:read",
        ],
    }),
});

const { client_id, client_secret } = await response.json();
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email [your-email] or create an issue in this repository.
