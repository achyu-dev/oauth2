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
        "jose": "latest",
        "bcryptjs": "latest",
        "nanoid": "latest",
        "zod": "latest",
        "helmet": "latest"
    }
}
```

## Environment Variables

```env
MONGODB_URL=mongodb://localhost:27017/pesu-oauth2
JWT_SECRET=your-super-secret-key
ENCRYPTION_KEY=your-encryption-key-for-credentials
PESU_AUTH_URL=https://pesu-auth.onrender.com/authenticate
OAUTH_BASE_URL=https://your-domain.com
NEXTAUTH_SECRET=your-nextauth-secret
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
  pesusrn               String   @unique
  prn                   String?
  profileData           Json
  encryptedCredentials  String?  // For fetch-live
  lastliveFetch         DateTime?
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
  pesusrn     String   @unique
  permissions String[] // ['clients', 'users', 'analytics']
  createdAt   DateTime @default(now())
  createdBy   String?
  active      Boolean  @default(true)
}
```

## API Endpoints

### OAuth2 Endpoints

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

### Token Format

Using `nanoid` instead of JWT for shorter tokens:

-   Access token: `nanoid(32)` → ~21 characters
-   Refresh token: `nanoid(48)` → ~32 characters

Token metadata stored in database with nanoid as lookup key.

## Rate Limiting

-   **OAuth endpoints**: 1000 requests/hour per client
-   **User API (cached)**: 100 requests/hour per access token
-   **User API (fetch live)**: 12 requests/hour per user (1 per 5 min)
-   **Admin endpoints**: 500 requests/hour per admin
-   **Client registration**: 10 registrations/hour per IP

## Security Features

### Data Protection

-   User credentials encrypted with AES-256-GCM
-   Secure token generation with nanoid
-   PKCE support for public clients (future)
-   State parameter validation

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

-   URL-based versioning: `/api/v1/`, `/api/v2/`
-   Graceful deprecation (12 months support)
-   Clear migration documentation

### Deprecation Headers

```http
API-Version: v1
Sunset: 2026-08-11
Link: </api/v2/user>; rel="successor-version"
```

### Future Versions

```
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
