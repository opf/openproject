# BIM Module - Security & Authentication

## Overview

The BIM module implements enterprise-grade security features including comprehensive audit logging, API token authentication, and pluggable authentication adapters. This document describes the security architecture, authentication methods, and best practices.

## Table of Contents

1. [Authentication](#authentication)
2. [API Tokens](#api-tokens)
3. [Audit Logging](#audit-logging)
4. [Security Reports](#security-reports)
5. [Authorization](#authorization)
6. [Best Practices](#best-practices)
7. [Compliance](#compliance)
8. [API Reference](#api-reference)

---

## Authentication

### Architecture

The BIM module uses a **pluggable authentication architecture** based on the Adapter pattern. Multiple authentication methods can coexist and are tried in priority order.

### Authentication Adapters

#### Available Adapters

| Adapter | Priority | Status | Description |
|---------|----------|--------|-------------|
| **API Token** | 5 (highest) | Always enabled | Token-based authentication for external integrations |
| **Database** | 10 | Always enabled | Standard username/password authentication |
| **SSO** | 15 | Optional | SAML/OAuth2 single sign-on |
| **LDAP** | 20 | Optional | LDAP directory authentication |
| **Two-Factor** | 40 | Optional | TOTP-based 2FA verification |

#### Enabling Optional Adapters

Optional adapters can be enabled via environment variables:

```bash
# Enable SSO authentication
export BIM_SSO_ENABLED=true

# Enable LDAP authentication
export BIM_LDAP_ENABLED=true

# Enable Two-Factor Authentication
export BIM_2FA_ENABLED=true
```

#### Authentication Flow

```ruby
# Authentication tries each adapter in priority order
user = Bim::Authentication::Manager.authenticate(
  username: 'alice',
  password: 'secret123'
)

# Or with API token
user = Bim::Authentication::Manager.authenticate(
  api_token: 'abc123...',
  ip_address: '192.168.1.100'
)
```

#### Creating Custom Adapters

You can create custom authentication adapters:

```ruby
class MyCustomAdapter < Bim::Authentication::Adapter
  def authenticate(credentials)
    # Your custom authentication logic
    # Return User object if successful, nil otherwise
  end

  def priority
    7 # Lower number = higher priority
  end

  def enabled?
    ENV['MY_CUSTOM_AUTH_ENABLED'] == 'true'
  end
end

# Register the adapter
Bim::Authentication::Manager.register_adapter(MyCustomAdapter)
```

---

## API Tokens

### Overview

API tokens enable secure, token-based authentication for external integrations such as:
- Revit plugin automated uploads
- CI/CD pipeline integration
- External dashboard applications
- Third-party BIM tools

### Token Features

- **SHA256 hashing**: Tokens are hashed before storage
- **Scoped permissions**: Fine-grained access control
- **Expiration**: Tokens can have expiration dates
- **Usage tracking**: Track when and where tokens are used
- **Revocation**: Tokens can be revoked instantly

### Available Scopes

API tokens support the following scopes:

| Scope | Description |
|-------|-------------|
| `read:models` | Read IFC models and metadata |
| `write:models` | Upload and update IFC models |
| `delete:models` | Delete IFC models |
| `read:clashes` | View clash detection results |
| `run:clashes` | Execute clash detection |
| `read:baselines` | View progress baselines |
| `write:baselines` | Create and update baselines |
| `read:federations` | View federated models |
| `write:federations` | Create and update federations |
| `read:dashboards` | View BIM dashboards |
| `write:dashboards` | Create and update dashboards |
| `admin:all` | Full administrative access |

### Creating API Tokens

#### Via API

```bash
# Create a new API token
curl -X POST https://example.com/api/v3/bim/api_tokens \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Revit Plugin",
    "description": "Token for automated model uploads",
    "scopes": ["read:models", "write:models"],
    "expires_in_days": 90
  }'

# Response includes the plain token (ONLY TIME IT'S VISIBLE!)
{
  "token": "abc123def456...",
  "message": "Save this token - it will not be shown again!",
  "token_data": {
    "id": 1,
    "name": "Revit Plugin",
    "token_prefix": "abc123de",
    "scopes": ["read:models", "write:models"],
    "expires_at": "2025-05-08T12:00:00Z"
  }
}
```

#### Via Ruby

```ruby
# Generate an API token
token, plain_token = Bim::ApiToken.generate(
  user: current_user,
  name: 'Revit Integration',
  description: 'Token for automated uploads',
  scopes: ['read:models', 'write:models'],
  expires_in: 90.days,
  project: @project # Optional - nil for global token
)

# Save the plain_token immediately - it won't be accessible again!
puts "Your API token: #{plain_token}"
```

### Using API Tokens

#### In HTTP Requests

```bash
# Using Bearer format
curl https://example.com/api/v3/bim/ifc_models \
  -H "Authorization: Bearer YOUR_API_TOKEN"

# Using Token format
curl https://example.com/api/v3/bim/ifc_models \
  -H "Authorization: Token YOUR_API_TOKEN"
```

#### Token Validation

Tokens are automatically validated for:
- **Existence**: Token must exist in database
- **Active status**: Token must not be revoked
- **Expiration**: Token must not be expired
- **Scopes**: Token must have required scope for the operation

### Managing Tokens

```ruby
# List user's tokens
tokens = Bim::ApiToken.for_user(current_user.id).active

# Check token scopes
if token.has_scope?('write:models')
  # User can upload models
end

# Or use the can? helper
if token.can?(:write, :models)
  # User can write to models
end

# Revoke a token
token.revoke!

# Check token status
token.status  # => 'active', 'expired', or 'revoked'
token.expired?  # => true/false
token.valid_token?  # => true/false
```

### Security Considerations

1. **Store tokens securely**: Never commit tokens to version control
2. **Use HTTPS only**: Tokens should only be transmitted over HTTPS
3. **Rotate regularly**: Set expiration dates and rotate tokens periodically
4. **Minimal scopes**: Only grant the minimum required scopes
5. **Monitor usage**: Check the `last_used_at` and `usage_count` fields
6. **Revoke immediately**: Revoke tokens if compromised

---

## Audit Logging

### Overview

All security-sensitive operations are logged for compliance, security monitoring, and forensics.

### Logged Actions

| Action Type | Category | Security Sensitive |
|-------------|----------|-------------------|
| `model_upload` | Operations | No |
| `clash_detection_run` | Operations | No |
| `baseline_created` | Operations | No |
| `comparison_created` | Operations | No |
| `federation_created` | Operations | No |
| `dashboard_created` | Operations | No |
| `api_token_created` | Security | **Yes** |
| `api_token_revoked` | Security | **Yes** |
| `permission_changed` | Security | **Yes** |
| `data_exported` | Security | **Yes** |
| `security_review` | Security | **Yes** |

### Creating Audit Logs

#### Automatic Logging

Most operations are logged automatically through the `Bim::Security::AuditService`:

```ruby
# Initialize audit service
audit_service = Bim::Security::AuditService.new(
  user: current_user,
  project: @project
)

# Log an action (IP, user agent, request ID captured automatically)
audit_service.log_action(
  action: :model_upload,
  details: {
    model_id: @model.id,
    file_name: 'architecture.ifc',
    file_size: 10_485_760
  }
)
```

#### Manual Logging

```ruby
# Direct logging
Bim::AuditLog.log(
  user: current_user,
  project: @project,
  action: :permission_changed,
  details: {
    target_user_id: user.id,
    old_role: 'member',
    new_role: 'admin'
  },
  ip_address: '192.168.1.100',
  user_agent: request.user_agent,
  request_id: request.uuid
)
```

### Querying Audit Logs

```ruby
# Get recent logs for a project
logs = Bim::AuditLog.for_project(project.id).recent.limit(50)

# Filter by action type
uploads = Bim::AuditLog.for_project(project.id)
                       .for_action(:model_upload)

# Filter by user
user_logs = Bim::AuditLog.for_user(user.id)

# Filter by time period
recent_logs = Bim::AuditLog.for_project(project.id)
                          .since(7.days.ago)

# Get security sensitive actions only
sensitive = Bim::AuditLog.for_project(project.id)
                        .select(&:security_sensitive?)

# Activity summary
summary = Bim::AuditLog.activity_summary(project.id, since: 30.days.ago)
# => { 'model_upload' => 15, 'clash_detection_run' => 8, ... }

# Top users by activity
top_users = Bim::AuditLog.top_users(project.id, limit: 10)
```

### Exporting Audit Logs

#### CSV Export

```ruby
# Via service
audit_service = Bim::Security::AuditService.new(
  user: current_user,
  project: @project
)

csv = audit_service.export_to_csv(since: 30.days.ago)

# Via model
logs = Bim::AuditLog.for_project(project.id).recent
csv = Bim::AuditLog.to_csv(logs)
```

#### API Export

```bash
# Export audit logs as CSV
curl https://example.com/api/v3/projects/1/bim/audit_logs/export \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: text/csv" \
  -o audit_logs.csv
```

---

## Security Reports

### Overview

Security reports provide aggregated insights into security-related activities.

### Generating Reports

```ruby
audit_service = Bim::Security::AuditService.new(
  user: current_user,
  project: @project
)

report = audit_service.generate_security_report(since: 30.days.ago)
```

### Report Contents

```ruby
{
  project_id: 1,
  project_name: "Office Building",
  report_period: {
    start: "2025-01-08T00:00:00Z",
    end: "2025-02-08T12:00:00Z"
  },
  activity_summary: {
    "model_upload" => 15,
    "clash_detection_run" => 8,
    "api_token_created" => 2,
    "permission_changed" => 1
  },
  top_users: [
    { user_id: 5, name: "Alice Architect", count: 12 },
    { user_id: 7, name: "Bob Engineer", count: 8 }
  ],
  security_sensitive_actions: [
    {
      id: 42,
      action_type: "api_token_created",
      user: { id: 1, name: "Admin User" },
      details: { token_name: "Revit Plugin" },
      created_at: "2025-02-01T10:00:00Z"
    }
  ],
  total_actions: 26
}
```

### API Access

```bash
# Get security report
curl https://example.com/api/v3/projects/1/bim/audit_logs/report \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## Authorization

### Permission Checks

The BIM module integrates with OpenProject's permission system:

```ruby
# Check if user can manage IFC models
if current_user.allowed_to?(:manage_ifc_models, @project)
  # User can create/update/delete models
end

# Required permissions for different operations
:view_ifc_models       # View models and data
:manage_ifc_models     # Full CRUD on models
:run_clash_detection   # Execute clash detection
:manage_baselines      # Create/update progress baselines
```

### API Token Authorization

API tokens are scoped and checked on each request:

```ruby
# In controllers using BimApiTokenAuthentication concern
include BimApiTokenAuthentication

# Check scope before action
before_action -> { verify_api_token_scope('write:models') }, only: [:create, :update]
```

---

## Best Practices

### For Administrators

1. **Regular Security Reviews**
   - Review audit logs weekly
   - Check for unusual patterns
   - Monitor failed authentication attempts
   - Review active API tokens monthly

2. **Token Management**
   - Enforce token expiration policies
   - Audit token scopes regularly
   - Revoke unused tokens
   - Use project-scoped tokens when possible

3. **Access Control**
   - Apply principle of least privilege
   - Regular permission audits
   - Document permission changes
   - Use security reports for oversight

### For Developers

1. **Always Log Security Actions**
   ```ruby
   # Log permission changes
   audit_service.log_action(
     action: :permission_changed,
     details: { ... }
   )
   ```

2. **Use Appropriate Scopes**
   ```ruby
   # Minimal scopes only
   token = Bim::ApiToken.generate(
     user: user,
     name: 'Read-only Dashboard',
     scopes: ['read:models', 'read:dashboards']
   )
   ```

3. **Validate Token Scopes**
   ```ruby
   # Before performing sensitive operations
   unless current_token.has_scope?('delete:models')
     render_forbidden
     return
   end
   ```

### For Integrations

1. **Store Tokens Securely**
   - Use environment variables or secure vaults
   - Never commit to version control
   - Rotate tokens regularly

2. **Handle Token Expiration**
   ```python
   # Check for 401 responses
   response = requests.get(url, headers={'Authorization': f'Bearer {token}'})
   if response.status_code == 401:
       # Token expired or invalid - refresh token
   ```

3. **Use HTTPS Only**
   - Never send tokens over HTTP
   - Validate SSL certificates

---

## Compliance

### GDPR Compliance

The audit logging system supports GDPR compliance:

- **Data Subject Access**: Export user's audit logs via CSV
- **Right to Erasure**: User anonymization supported (user_id set to null)
- **Audit Trail**: Complete record of who accessed what data
- **Retention**: Configurable log retention periods

### SOC 2 Compliance

The security features support SOC 2 requirements:

- **Access Control** (CC6.1): Token-based authentication with scopes
- **Audit Logging** (CC7.2): Comprehensive activity logging
- **Change Management** (CC8.1): All changes logged with details
- **Monitoring** (CC7.3): Security reports and activity summaries

### HIPAA Compliance

For healthcare projects using BIM data:

- **Access Logs** (45 CFR 164.312(b)): All access logged
- **Authentication** (45 CFR 164.312(d)): Multi-factor support via adapters
- **Audit Controls** (45 CFR 164.312(b)): Comprehensive audit trail

---

## API Reference

### Audit Logs API

#### List Audit Logs
```
GET /api/v3/projects/:project_id/bim/audit_logs
```

**Query Parameters:**
- `action_type` (optional): Filter by action type
- `user_id` (optional): Filter by user
- `since` (optional): ISO8601 timestamp, e.g., "2025-01-01T00:00:00Z"
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Results per page (default: 50, max: 100)

**Response:**
```json
{
  "logs": [
    {
      "id": 1,
      "user": { "id": 5, "name": "Alice", "login": "alice" },
      "project": { "id": 1, "name": "Office Building" },
      "action_type": "model_upload",
      "details": { "file_name": "arch.ifc" },
      "ip_address": "192.168.1.100",
      "created_at": "2025-02-08T12:00:00Z"
    }
  ],
  "total": 150,
  "page": 1,
  "per_page": 50
}
```

#### Export Audit Logs (CSV)
```
GET /api/v3/projects/:project_id/bim/audit_logs/export
```

**Query Parameters:**
- `since` (optional): ISO8601 timestamp

**Response:** CSV file download

#### Security Report
```
GET /api/v3/projects/:project_id/bim/audit_logs/report
```

**Query Parameters:**
- `since` (optional): ISO8601 timestamp (default: 30 days ago)

**Response:** Security report JSON (see [Security Reports](#security-reports))

### API Tokens API

#### List Tokens
```
GET /api/v3/bim/api_tokens
```

**Query Parameters:**
- `active` (optional): Filter by active status (true/false)

#### Create Token
```
POST /api/v3/bim/api_tokens
```

**Request Body:**
```json
{
  "name": "Revit Plugin",
  "description": "Token for automated uploads",
  "scopes": ["read:models", "write:models"],
  "expires_in_days": 90
}
```

**Response:** Token object with plain token (only shown once!)

#### Show Token
```
GET /api/v3/bim/api_tokens/:id
```

#### Update Token
```
PATCH /api/v3/bim/api_tokens/:id
```

**Request Body:**
```json
{
  "name": "Updated Name",
  "scopes": ["read:models", "write:models", "delete:models"]
}
```

#### Revoke Token
```
POST /api/v3/bim/api_tokens/:id/revoke
```

#### Delete Token
```
DELETE /api/v3/bim/api_tokens/:id
```

---

## Maintenance

### Cleanup Old Audit Logs

```ruby
# Delete audit logs older than 1 year
Bim::AuditLog.where('created_at < ?', 1.year.ago).delete_all

# Or via scheduled job
# In config/schedule.rb (whenever gem)
every 1.week do
  rake "bim:audit_logs:cleanup"
end
```

### Cleanup Expired Tokens

```ruby
# Delete expired tokens older than 30 days
Bim::ApiToken.cleanup_expired(older_than: 30.days.ago)

# Or via scheduled job
every 1.day do
  rake "bim:api_tokens:cleanup_expired"
end
```

---

## Support and Issues

For security vulnerabilities, please contact: security@openproject.com

For general questions and support, see the [main documentation](./README.md).

---

## Changelog

### Version 1.0.0 (2025-02-08)
- Initial security implementation
- API token authentication
- Comprehensive audit logging
- Pluggable authentication adapters
- Security reporting and CSV export
- 11 logged action types
- 12 token scopes
- GDPR, SOC 2, and HIPAA compliance features
