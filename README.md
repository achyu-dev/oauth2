# PESU OAuth2

A comprehensive OAuth2 provider built with Next.js, integrating with PESU Academy authentication system, fully compliant with [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749) standards.

## Overview

This OAuth2 server allows applications to authenticate PESU students and access their profile information through standardized OAuth2 flows as defined in [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749). It acts as a bridge between the PESU authentication system and third-party applications.

## Technical Stack

- **Framework**: Next.js 15.4.6 with TypeScript and App Router
- **Database**: MongoDB with Prisma ORM
- **Authentication**: Integration with PESU Auth API
- **Tokens**: nanoid-based tokens (shorter than JWT)
- **Security**: jose, bcryptjs, helmet
- **Package Manager**: pnpm

## Security

For comprehensive security information including data protection, encryption, rate limiting, and vulnerability disclosure, see [SECURITY.md](.github/SECURITY.md).

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

### OAuth2 Architecture Overview

The OAuth2 implementation separates user-facing web interfaces from backend API endpoints:

- **Web Interfaces** (`/oauth2/*`): User-facing pages for authorization flow
- **API Endpoints** (`/api/oauth2/*`): Backend processing and token management

### OAuth2 Web Interfaces

#### `GET /oauth2/login`

User authentication page for the OAuth2 server.

**Purpose:**

- Authenticates users with PESU credentials
- Creates user session for OAuth2 server
- Redirects back to authorization flow after successful login

**Query Parameters:**

- `redirect_uri` (automatic): URL to redirect back to after login
- Preserves original authorization parameters for seamless flow continuation

#### `GET /oauth2/authorize`

User-facing authorization webpage where the OAuth2 flow begins.

**Query Parameters:**

- `client_id` (required): Client application identifier
- `redirect_uri` (required): Callback URL
- `scope` (required): Requested scopes (space-separated)
- `response_type` (required): Must be "code"
- `state` (optional): CSRF protection

**Detailed Flow:**

1. **Initial Redirect**: Client redirects user to this webpage with query parameters
2. **Session Check**: Check if user has an active session on our OAuth server
3. **Login Required**: If no session exists, redirect to login page (`/oauth2/login`)
4. **Post-Login Redirect**: After successful login, redirect back to `/oauth2/authorize` with original parameters
5. **Parameter Validation**: Before page loads, validate query parameters using `POST /api/oauth2/authorize`
6. **Consent Screen**: If validation passes, display consent screen showing:
   - Client application requesting access
   - Specific permissions/scopes being requested
   - Redirect destination after authorization
7. **User Decision**: User clicks "Continue" (approve) or "Deny"
8. **Code Generation**: On approval, generate temporary authorization code
9. **Final Redirect**: Redirect to client's `redirect_uri` with code and state (if provided)
10. **Code Expiration**: Authorization code expires in 10 minutes

#### `GET /oauth2/register`

Client registration webpage for developers to register new OAuth2 applications.

**Eligibility Requirements:**

- Must be a PESU student with a verified email address
- Must authenticate with PESU credentials before accessing registration form
- Email verification status is checked against PESU records

**Purpose:**

- Provides a secure web form for OAuth2 client registration
- Handles input validation and error display
- Generates and securely displays client credentials
- Implements rate limiting for registration attempts

**Form Fields:**

- `name` (required): Application name for user recognition
- `description` (optional): Brief description of the application
- `redirect_uris` (required): List of valid callback URLs for OAuth2 flow
- `scopes` (required): Checkbox selection of requested permission scopes

**Security Features:**

- CSRF protection with form tokens
- Input validation and sanitization
- Rate limiting (10 registrations/hour per IP)
- Client secret displayed only once for security
- Secure random generation of client credentials

**Terms Compliance:**

- All registered applications must comply with PESU OAuth2 Terms of Service
- Violations may result in immediate client credential suspension
- Suspended credentials cannot be used for OAuth2 flows

**Post-Registration Flow:**

1. **Form Submission**: User submits completed registration form
2. **Validation**: Server validates all input fields and checks rate limits
3. **Credential Generation**: Generate secure client_id and client_secret
4. **Database Storage**: Store hashed client_secret and application details
5. **Display Credentials**: Show generated credentials with security warning
6. **One-time Display**: Client secret cannot be retrieved again after page refresh

### OAuth2 API Endpoints

In accordance with [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749), the OAuth2 API endpoints will only accept a content type of `application/x-www-form-urlencoded`. JSON content is not permitted and will return an error.

#### `POST /api/oauth2/authorize`

Internal API endpoint for validating authorization request parameters.

**Purpose:**

- Validates query parameters from `/oauth2/authorize` before displaying consent screen
- Verifies client_id, redirect_uri, scope validity
- Called internally before consent page loads

**Parameters:**

- `client_id` (required): Client application identifier
- `redirect_uri` (required): Must match registered redirect URI
- `scope` (required): Requested scopes (space-separated)
- `response_type` (required): Must be "code"
- `state` (optional): CSRF protection parameter

**Response:**

- Success: Proceeds to show consent screen
- Error: Returns validation error preventing consent screen display

#### `POST /api/oauth2/token`

Token exchange endpoint.

**Parameters:**

- `grant_type` (required): "authorization_code" or "refresh_token"
- `code` (required for auth code): Authorization code
- `refresh_token` (required for refresh): Refresh token
- `client_id` (required): Client identifier
- `client_secret` (required): Client secret
- `redirect_uri` (required for auth code): Must match authorize request

**Response:**

```json
{
  "access_token": "abc123xyz",
  "refresh_token": "def456uvw",
  "token_type": "Bearer",
  "expires_in": 604800,
  "scope": "profile:basic:read profile:contact:read"
}
```

#### `POST /api/oauth2/introspect`

Token introspection endpoint ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662)).

**Parameters:**

- `token` (required): Token to introspect
- `client_id` (required): Client identifier
- `client_secret` (required): Client secret

**Response:**

```json
{
  "active": true,
  "scope": "profile:basic:read profile:contact:read",
  "client_id": "original_client",
  "username": "PES1201800001",
  "exp": 1723456789
}
```

#### `POST /api/oauth2/revoke`

Token revocation endpoint.

**Parameters:**

- `token` (required): Token to revoke
- `client_id` (required): Client identifier
- `client_secret` (required): Client secret

### User Data API

#### `GET /api/v1/user`

Get user profile information.

**Headers:**

- `Authorization: Bearer {access_token}`

**Query Parameters:**

- `fetch_live` (optional): Set to "true" for live data fetch from PESU auth

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

#### `GET /oauth2/register`

Client registration webpage for developers to register new OAuth2 applications.

**Features:**

- Web form for application registration
- Input validation and error handling
- Secure client secret generation and display
- One-time display of client credentials (for security)

**Form Fields:**

- `name` (required): Application name
- `description` (optional): Application description
- `redirect_uris` (required): List of callback URLs
- `scopes` (required): Selected requested scopes

**Post-Registration:**

After successful registration, the page displays the generated credentials:

```
Client ID: generated_client_id
Client Secret: generated_client_secret (shown only once)
Application Name: My App
Redirect URIs: https://myapp.com/callback
Scopes: profile:basic:read, profile:contact:read
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

- **`invalid_request`** - Missing or malformed parameters
- **`unauthorized_client`** - Client not authorized for this grant type
- **`access_denied`** - User denied the authorization request
- **`unsupported_response_type`** - Response type not supported
- **`invalid_scope`** - Requested scope is invalid or unknown
- **`server_error`** - Internal server error occurred
- **`temporarily_unavailable`** - Service temporarily overloaded

#### Token Endpoint Errors

- **`invalid_request`** - Missing or malformed parameters
- **`invalid_client`** - Client authentication failed
- **`invalid_grant`** - Authorization code/refresh token invalid
- **`unauthorized_client`** - Client not authorized for this grant
- **`unsupported_grant_type`** - Grant type not supported
- **`invalid_scope`** - Requested scope exceeds granted scope

#### User API Errors

- **`invalid_token`** - Access token expired or invalid
- **`insufficient_scope`** - Token lacks required scope for resource
- **`rate_limit_exceeded`** - Too many requests (includes retry-after header)

### HTTP Status Codes

- **400 Bad Request** - Invalid request parameters
- **401 Unauthorized** - Authentication required or failed
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - Resource not found
- **429 Too Many Requests** - Rate limit exceeded
- **500 Internal Server Error** - Server error
- **503 Service Unavailable** - PESU Auth temporarily unavailable

## Available Scopes

The OAuth2 server provides consolidated scopes for accessing different categories of user information.

### Scope Categories

#### `profile:basic:read`

Access to basic user identity information:

- User's full name
- PRN (PESU Registration Number)
- SRN (Student Registration Number)

#### `profile:academic:read`

Access to academic information:

- Academic program
- Branch/department
- Current semester
- Class section
- Campus information

#### `profile:contact:read`

Access to contact information:

- Email address
- Phone number

### Scope Usage Examples

```
# Request only basic identity
scope=profile:basic:read

# Request academic information
scope=profile:academic:read

# Request contact information
scope=profile:contact:read

# Request multiple categories
scope=profile:basic:read profile:academic:read

# Request all profile information
scope=profile:basic:read profile:academic:read profile:contact:read

# Future: Write access to contact info
scope=profile:contact:read profile:contact:write
```

## Token Strategy

### Token Types & Expiration

- **Access Tokens**: 7 days (nanoid, 32 chars)
- **Refresh Tokens**: 30 days (nanoid, 48 chars)
- **Authorization Codes**: 10 minutes (nanoid, 24 chars)
- **Admin Sessions**: 8 hours (nanoid, 32 chars)

### Token Format

Using `nanoid` instead of JWT for shorter tokens:

- Access token: `nanoid(32)` → ~21 characters
- Refresh token: `nanoid(48)` → ~32 characters
- Admin session: `nanoid(32)` → ~21 characters

Token metadata stored in database with nanoid as lookup key.

## PESU Auth Integration

### Caching Strategy

- Cache user profiles in MongoDB
- Reduce PESU auth API calls
- Fetch live option for real-time data

### Fetch Live Flow

1. Client requests with `?fetch_live=true`
2. Decrypt stored user credentials
3. Re-authenticate with PESU auth
4. Update cached profile data
5. Return fresh data

### Rate Limits

- Standard cache hits: No additional limits
- Fetch live: Stricter limits (1 per 5 minutes)

## Client Consent Flow

Following Discord OAuth2 model:

### Consent Options

- **Auto-approve**: For trusted clients (admin-configured)
- **Skip consent**: Same client + user + same/subset scopes
- **Force consent**: Always show consent screen (default)

### Consent Screen

- Clear scope descriptions
- Application information
- Allow/Deny options
- Remember choice option

## API Versioning

### Strategy

- **Base URL**: `/api/` automatically points to the latest version
- **Versioned URLs**: `/api/v{version}/` for specific versions (e.g., `/api/v1/`, `/api/v2/`)
- **Graceful deprecation**: 12 months support for older versions
- **Clear migration documentation** for version transitions

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

- [ ] Prisma setup with MongoDB
- [ ] Database schema implementation
- [ ] PESU auth integration service
- [ ] Basic token management
- [ ] User profile caching

### Phase 2: OAuth2 Endpoints

- [ ] Authorization endpoint (`/oauth2/authorize`)
- [ ] Token endpoint (`/oauth2/token`)
- [ ] User info endpoint (`/v1/user`)
- [ ] Token introspection (`/oauth2/introspect`)
- [ ] Token revocation (`/oauth2/revoke`)

### Phase 3: Client Management

- [ ] Client registration webpage (`/oauth2/register`)
- [ ] Client authentication
- [ ] Redirect URI validation
- [ ] Scope validation

### Phase 4: Security & Middleware

- [ ] Rate limiting implementation
- [ ] Request validation middleware
- [ ] Security headers setup
- [ ] Encryption service for credentials

### Phase 5: Admin & Monitoring

- [ ] Admin authentication system
- [ ] Client management interface
- [ ] Token monitoring dashboard
- [ ] Usage analytics

### Phase 6: Frontend & Documentation

- [ ] OAuth consent screen
- [ ] Client registration form
- [ ] Admin dashboard
- [ ] Developer documentation
- [ ] API examples and SDKs

## Usage Examples

### Authorization Flow

```
1. Client redirects user to authorization webpage (GET request)
GET /oauth2/authorize?client_id=abc&redirect_uri=https://app.com/callback&scope=profile%3Abasic%3Aread%20profile%3Acontact%3Aread&response_type=code&state=xyz

2. OAuth server checks for existing user session
   - If no session: Redirect to /oauth2/login
   - User authenticates with PESU credentials
   - Redirect back to /oauth2/authorize with original parameters

3. Server validates request parameters via internal API
POST /api/oauth2/authorize (internal validation)

4. If validation passes, display consent screen to user
   - Shows client app requesting specific permissions
   - User sees "Continue" or "Deny" options

5. User clicks "Continue" - consent granted

6. Server generates authorization code and redirects back to client
https://app.com/callback?code=auth_code&state=xyz

7. Client exchanges code for tokens
POST /api/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=auth_code&client_id=abc&client_secret=secret&redirect_uri=https://app.com/callback

8. Use access token to fetch user data
GET /api/v1/user
Authorization: Bearer access_token
```

### Client Registration

To register a new OAuth2 client application:

**Prerequisites:**

- Must be a PESU student with a verified email address
- PESU credentials required for authentication

**Registration Process:**

1. **Authenticate**: Login with your PESU credentials
2. **Email Verification Check**: System verifies your email status with PESU records
3. **Visit the registration page**: Navigate to `/oauth2/register`
4. **Fill out the form**:
   - Application name: "My PESU App"
   - Description: "An app for PESU students" (optional)
   - Redirect URIs: Add your callback URLs (e.g., `https://myapp.com/callback`)
   - Scopes: Select required permissions:
     - `profile:basic:read`
     - `profile:contact:read`
     - `profile:academic:read`
5. **Accept Terms**: Agree to PESU OAuth2 Terms of Service
6. **Submit the form**: Click "Register Application"
7. **Save your credentials**: The page will display your client credentials **only once**:
   ```
   Client ID: abc123xyz
   Client Secret: def456uvw (copy this immediately - it won't be shown again)
   ```
8. **Implement OAuth2 flow** in your application using these credentials

**Important Notes:**

- The client secret is displayed only once for security reasons
- Copy and store credentials securely before leaving the page
- Violations of terms may result in immediate credential suspension
- Suspended credentials cannot be used for OAuth2 authentication flows

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
