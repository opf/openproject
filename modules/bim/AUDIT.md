# BIM Audit Logging & Data Provenance System

## Overview

The BIM Audit Logging system provides comprehensive traceability of all model-related actions, workflows, and data changes. It implements detailed audit logs, versioned snapshots, and metadata provenance for regulatory compliance and accountability.

**Key Features**:
- ✅ Immutable audit trail with SHA256 checksums
- ✅ Before/after snapshots for all entity changes
- ✅ Entity versioning with complete history
- ✅ Automatic event capture via domain events
- ✅ Reversible actions with rollback capability
- ✅ Export to JSON, CSV for compliance
- ✅ Integrity verification
- ✅ Advanced filtering and querying

## Architecture

### Core Components

```
┌─────────────────────────────┐
│   Domain Events             │
│  (OpenProject::Notifications)│
└──────────┬──────────────────┘
           │
           ↓
┌──────────────────────────────┐
│  BimAuditTrailService        │
│  - Event subscribers         │
│  - Snapshot capture          │
│  - Automatic logging         │
└──────────┬───────────────────┘
           │
           ↓
┌──────────────────────────────┐
│     BimAuditLog Model        │
│  - Action logging            │
│  - Version tracking          │
│  - Change detection          │
│  - Checksum verification     │
└──────────┬───────────────────┘
           │
           ↓
┌──────────────────────────────┐
│   Audit Log API              │
│  - Query & filter            │
│  - Export (CSV/JSON)         │
│  - Verify integrity          │
│  - Entity history            │
└──────────────────────────────┘
```

## Data Model

### Audit Log Schema

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | User who performed action |
| project_id | bigint | Associated project |
| action_type | integer | Enum: model_upload, workflow_transitioned, etc. |
| entity_type | string | Polymorphic entity type (e.g., "Bim::Clash") |
| entity_id | bigint | Polymorphic entity ID |
| entity_version | integer | Auto-incremented version number |
| previous_version | integer | Link to previous version |
| details | jsonb | Action-specific details |
| changes | jsonb | Changed attributes: `{field: [old, new]}` |
| snapshot_before | jsonb | Entity state before change |
| snapshot_after | jsonb | Entity state after change |
| checksum | string(64) | SHA256 hash for integrity |
| severity | integer | info=0, low=1, medium=2, high=3, critical=4 |
| reversible | boolean | Can this action be reversed? |
| reversed_by_id | bigint | User who reversed this action |
| reversed_at | datetime | When action was reversed |
| tags | string[] | Tags for categorization |
| ip_address | inet | IP address of request |
| user_agent | string | User agent string |
| request_id | string | Request correlation ID |
| created_at | datetime | Timestamp |

### Action Types

**Model Operations (0-9)**:
- `model_upload` - IFC model uploaded
- `model_delete` - Model deleted
- `model_update` - Model updated
- `model_conversion_started` - Conversion started
- `model_conversion_completed` - Conversion completed
- `model_conversion_failed` - Conversion failed

**Clash Operations (10-19)**:
- `clash_detection_run` - Clash detection executed
- `clash_resolved` - Clash marked as resolved
- `clash_approved` - Clash approved as acceptable
- `clash_assigned` - Clash assigned to user

**Workflow Operations (60-69)**:
- `workflow_initialized` - Workflow applied to entity
- `workflow_transitioned` - State transition executed
- `workflow_completed` - Workflow reached final state
- `workflow_reset` - Workflow reset to initial state

**Element Operations (70-79)**:
- `element_linked` - Element linked to work package
- `element_unlinked` - Element unlinked
- `element_updated` - Element properties updated
- `element_properties_refreshed` - Properties synced from IFC

**Security Operations (80-89)**:
- `permission_changed` - Permissions modified
- `api_key_created` - API token created
- `api_key_revoked` - API token revoked

**Data Operations (90-99)**:
- `export_data` - Data exported
- `import_data` - Data imported
- `bulk_operation` - Bulk operation executed

## Automatic Event Capture

The `BimAuditTrailService` automatically subscribes to domain events and creates audit log entries.

### Subscribed Events

**Model Events**:
- `ifc_model_uploaded`
- `ifc_model_deleted`
- `ifc_conversion_started`
- `ifc_conversion_completed`
- `ifc_conversion_failed`

**Workflow Events**:
- `bim_workflow_transitioned`
- `bim_workflow_initialized`

**Issue Events**:
- `bim_issue_created`
- `bim_issue_updated`
- `bim_comment_created`

**Element Events**:
- `bim_element_linked`
- `bim_element_unlinked`
- `bim_element_properties_refreshed`

**Clash Events**:
- `bim_clash_detected`
- `bim_clash_resolved`
- `bim_clash_approved`

### Emitting Events for Audit

```ruby
# Emit event that will be automatically logged
OpenProject::Notifications.send('ifc_model_uploaded', {
  model: ifc_model,
  user: current_user,
  ip_address: request.remote_ip,
  request_id: request.uuid
})
```

## API Reference

### List Audit Logs

```http
GET /api/v3/projects/:project_id/bim/audit_logs
```

Query Parameters:
- `action_type` - Filter by action (e.g., "model_upload")
- `user_id` - Filter by user
- `entity_type` - Filter by entity type
- `entity_id` - Filter by entity ID
- `severity` - Filter by severity (info, low, medium, high, critical)
- `since` - Filter by date (ISO 8601)
- `before` - Filter before date
- `with_changes` - Only logs with changes (true/false)
- `security_sensitive` - Only security-sensitive actions (true/false)
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 200)

Response:
```json
{
  "_type": "Collection",
  "total": 150,
  "count": 25,
  "page": 1,
  "per_page": 25,
  "_embedded": {
    "elements": [
      {
        "_type": "AuditLog",
        "id": 123,
        "timestamp": "2025-11-10T10:30:00Z",
        "user": { "id": 5, "name": "John Doe" },
        "project": { "id": 1, "name": "Building A" },
        "entity": "Bim::Clash#45",
        "entity_version": 3,
        "action": "clash_resolved",
        "action_description": "Resolved clash ID: 45",
        "severity": "info",
        "details": { "resolution_type": "redesign" },
        "tags": ["clash", "resolved"],
        "reversible": false,
        "checksum": "a1b2c3d4..."
      }
    ]
  }
}
```

### Get Single Audit Log

```http
GET /api/v3/bim/audit_logs/:id
```

Includes full details with snapshots and changes.

### Verify Integrity

```http
GET /api/v3/bim/audit_logs/:id/verify
```

Response:
```json
{
  "_type": "AuditLogVerification",
  "id": 123,
  "valid": true,
  "checksum": "a1b2c3d4...",
  "message": "Audit log integrity verified"
}
```

### Entity History

```http
GET /api/v3/bim/audit_logs/entity/:entity_type/:entity_id/history
```

Example:
```http
GET /api/v3/bim/audit_logs/entity/Bim::Clash/45/history
```

Returns complete change timeline for the entity.

### Entity Versions

```http
GET /api/v3/bim/audit_logs/entity/:entity_type/:entity_id/versions
```

Returns all versions with metadata:
```json
{
  "_type": "EntityVersions",
  "entity_type": "Bim::Clash",
  "entity_id": 45,
  "total_versions": 5,
  "current_version": 5,
  "_embedded": {
    "versions": [
      {
        "version": 1,
        "previous_version": null,
        "timestamp": "2025-11-10T09:00:00Z",
        "user": "Admin",
        "action": "clash_detection_run",
        "changes_count": 0,
        "has_snapshot": true
      }
    ]
  }
}
```

### Export Audit Logs

```http
GET /api/v3/projects/:project_id/bim/audit_logs/export?format=csv
GET /api/v3/projects/:project_id/bim/audit_logs/export?format=json
```

**CSV Export**:
```csv
ID,Timestamp,User,Project,Entity,Action,Severity,IP Address,Changes
123,2025-11-10T10:30:00Z,John Doe,Building A,Bim::Clash#45,clash_resolved,info,192.168.1.1,"{...}"
```

**JSON Export**:
```json
{
  "exported_at": "2025-11-10T11:00:00Z",
  "count": 150,
  "logs": [
    { "id": 123, "timestamp": "...", ... }
  ]
}
```

### Audit Report

```http
GET /api/v3/projects/:project_id/bim/audit_logs/report?since=2025-11-01
```

Response:
```json
{
  "_type": "SecurityReport",
  "generated_at": "2025-11-10T11:00:00Z",
  "project": "Building A",
  "period_start": "2025-11-01T00:00:00Z",
  "period_end": "2025-11-10T11:00:00Z",
  "summary": {
    "total_events": 250,
    "unique_users": 15,
    "security_events": 12,
    "data_changes": 180,
    "reversible_actions": 45
  },
  "breakdown": {
    "by_action": { "model_upload": 50, "workflow_transitioned": 120, ... },
    "by_severity": { "info": 200, "medium": 40, "high": 10 }
  },
  "top_users": [
    { "user_id": 5, "action_count": 45 }
  ]
}
```

### Timeline View

```http
GET /api/v3/projects/:project_id/bim/audit_logs/timeline
```

Returns events grouped by day for visualization.

## Ruby API

### Manual Logging

```ruby
# Basic logging
Bim::AuditLog.log(
  user: current_user,
  project: project,
  action: :model_upload,
  details: {
    model_id: model.id,
    file_name: 'building.ifc',
    file_size: 52428800
  }
)

# Enhanced logging with snapshots
Bim::AuditLog.log_with_snapshot(
  user: current_user,
  project: project,
  action: :clash_resolved,
  entity: clash,
  changes: {
    status: ['active', 'resolved'],
    resolution_type: [nil, 'redesign']
  },
  snapshot_before: { status: 'active', ... },
  snapshot_after: { status: 'resolved', ... },
  severity: :info,
  reversible: true,
  tags: ['clash', 'resolution']
)
```

### Querying Logs

```ruby
# Get all logs for a project
logs = Bim::AuditLog.for_project(project.id)

# Filter by action
logs = Bim::AuditLog.for_action(:workflow_transitioned)

# Filter by entity
logs = Bim::AuditLog.for_entity('Bim::Clash', 45)

# Get entity history
history = Bim::AuditLog.entity_history('Bim::Clash', 45)

# Get entity versions
versions = Bim::AuditLog.entity_versions('Bim::Clash', 45)

# Security-sensitive actions only
sensitive = Bim::AuditLog.security_sensitive

# Logs with changes
with_changes = Bim::AuditLog.with_changes

# Recent activity
recent = Bim::AuditLog.since(7.days.ago).recent
```

### Verify Integrity

```ruby
log = Bim::AuditLog.find(123)
if log.verify_checksum
  puts "✓ Integrity verified"
else
  puts "✗ Checksum mismatch!"
end

# Batch verification
logs = Bim::AuditLog.where(project_id: 1).limit(100)
results = Bim::AuditLog.verify_integrity(logs)
# => [{ id: 1, valid: true, checksum: "..." }, ...]
```

### Reverse Actions

```ruby
log = Bim::AuditLog.find(123)

if log.reversible? && !log.reversed?
  reverse_log = log.reverse!(
    user: current_user,
    comment: "Reverting incorrect resolution"
  )

  puts "Action reversed: #{reverse_log.id}"
end
```

## Rake Tasks

### Statistics

```bash
rake bim:audit:stats
```

Output:
```
=== BIM Audit Log Statistics ===

Total audit log entries: 1500

Actions by type:
  workflow_transitioned        :    450 (30.0%)
  model_upload                 :    300 (20.0%)
  ...

Severity distribution:
  Info      :   1200 (80.0%)
  Medium    :    250 (16.67%)
  ...

Recent activity (last 7 days): 85 events
Security-sensitive actions: 15
Data integrity:
  Logs with checksums: 1500
  Versioned entity changes: 950
```

### Cleanup Old Logs

```bash
# Default: cleanup logs older than 2 years
rake bim:audit:cleanup

# Custom retention period
rake bim:audit:cleanup OLDER_THAN="2024-01-01"
```

### Verify Integrity

```bash
# Verify random sample (1000 logs)
rake bim:audit:verify

# Verify specific logs
rake bim:audit:verify LOG_IDS="1,2,3,4,5"

# Verify all logs for a project
rake bim:audit:verify PROJECT_ID=1

# Custom limit
rake bim:audit:verify LIMIT=5000
```

### Export Logs

```bash
# Export to CSV
rake bim:audit:export PROJECT_ID=1 FORMAT=csv OUTPUT=audit.csv

# Export to JSON
rake bim:audit:export PROJECT_ID=1 FORMAT=json OUTPUT=audit.json

# With filters
rake bim:audit:export PROJECT_ID=1 SINCE="2025-11-01" ACTION=model_upload
```

### Generate Report

```bash
rake bim:audit:report PROJECT_ID=1

# Custom date range
rake bim:audit:report PROJECT_ID=1 SINCE="2025-11-01"
```

### Entity History

```bash
rake bim:audit:entity_history ENTITY_TYPE="Bim::Clash" ENTITY_ID=45
```

Output:
```
=== Change History for Bim::Clash#45 ===

2025-11-10 10:00:00 UTC - John Doe
  Action: Ran clash detection
  Severity: medium

2025-11-10 10:30:00 UTC - Jane Smith
  Action: Resolved clash ID: 45
  Severity: info
  Changes:
    status: "active" → "resolved"
    resolution_type: nil → "redesign"

Total changes: 2
Current version: 2
```

### Entity Versions

```bash
rake bim:audit:entity_versions ENTITY_TYPE="Bim::Clash" ENTITY_ID=45
```

## Data Integrity & Checksums

### Automatic Checksum Generation

All audit log entries automatically generate SHA256 checksums:

```ruby
# Calculated from:
data = {
  user_id: user_id,
  project_id: project_id,
  action_type: action_type,
  entity_type: entity_type,
  entity_id: entity_id,
  details: details,
  changes: changes,
  created_at: created_at
}.to_json

checksum = Digest::SHA256.hexdigest(data)
```

### Verification

```ruby
log = Bim::AuditLog.find(123)
log.verify_checksum  # => true/false
```

Integrity verification detects:
- Tampering with audit log data
- Database corruption
- Manual data modifications

## Versioning

### Automatic Version Tracking

Entity versions are automatically tracked:

```ruby
# First log for entity
log1 = Bim::AuditLog.create!(
  entity_type: 'Bim::Clash',
  entity_id: 45,
  ...
)
log1.entity_version  # => 1
log1.previous_version  # => nil

# Second log for same entity
log2 = Bim::AuditLog.create!(
  entity_type: 'Bim::Clash',
  entity_id: 45,
  ...
)
log2.entity_version  # => 2
log2.previous_version  # => 1
```

### Version Diff

```ruby
diff = Bim::AuditLog.diff_versions('Bim::Clash', 45, from_version: 1, to_version: 3)
# => {
#   entity_type: 'Bim::Clash',
#   entity_id: 45,
#   from_version: 1,
#   to_version: 3,
#   changes: { status: ['new', 'resolved'], ... },
#   log_count: 2
# }
```

## Snapshots

### Before/After Snapshots

Snapshots capture complete entity state:

```ruby
Bim::AuditLog.log_with_snapshot(
  ...
  snapshot_before: {
    status: 'active',
    assigned_to_id: 5,
    severity: 'major'
  },
  snapshot_after: {
    status: 'resolved',
    assigned_to_id: 5,
    severity: 'major',
    resolution_type: 'redesign'
  }
)
```

### Snapshot Diff

```ruby
log = Bim::AuditLog.find(123)
diff = log.snapshot_diff
# => {
#   status: { before: 'active', after: 'resolved', changed: true },
#   resolution_type: { before: nil, after: 'redesign', changed: true }
# }
```

## Security & Compliance

### Security-Sensitive Actions

Automatically tracked:
- Permission changes
- API key creation/revocation
- Data exports
- Model deletions
- Federation deletions

```ruby
Bim::AuditLog.security_sensitive.count  # => 15
```

### Retention Policy

Default retention: **2 years**

Configure in `Bim::AuditLog::DEFAULT_RETENTION_PERIOD`

### Immutability

Audit logs are append-only:
- No UPDATE operations allowed
- DELETE only for retention cleanup
- Checksums detect tampering

### Access Control

- **View**: Project members
- **Export**: Project managers
- **Admin functions**: Administrators only

## Performance Optimization

### Indexes

Optimized indexes for common queries:
```sql
CREATE INDEX idx_audit_logs_project ON bim_audit_logs(project_id);
CREATE INDEX idx_audit_logs_user ON bim_audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON bim_audit_logs(action_type);
CREATE INDEX idx_audit_logs_entity ON bim_audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created ON bim_audit_logs(created_at);
CREATE INDEX idx_audit_logs_tags ON bim_audit_logs USING GIN(tags);
CREATE INDEX idx_audit_logs_changes ON bim_audit_logs USING GIN(changes);
```

### Partitioning

For large datasets, consider partitioning by date:

```sql
-- Example monthly partitioning
CREATE TABLE bim_audit_logs_2025_11 PARTITION OF bim_audit_logs
  FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
```

### Cleanup Strategy

```ruby
# Scheduled job (daily)
Bim::AuditLog.cleanup_old_logs(older_than: 2.years.ago)

# Archive to cold storage before deletion
old_logs = Bim::AuditLog.where('created_at < ?', 2.years.ago)
archive_to_s3(old_logs.to_json_export)
old_logs.delete_all
```

## Best Practices

### 1. Emit Events for Audit

Always emit domain events for significant actions:

```ruby
def update_clash_status
  old_status = clash.status

  clash.update!(status: 'resolved')

  OpenProject::Notifications.send('bim_clash_resolved', {
    clash: clash,
    user: current_user,
    previous_status: old_status
  })
end
```

### 2. Include Context

Provide detailed context in event payloads:

```ruby
OpenProject::Notifications.send('ifc_model_uploaded', {
  model: ifc_model,
  user: current_user,
  file_size: ifc_model.ifc_attachment.filesize,
  file_name: ifc_model.title,
  ip_address: request.remote_ip,
  request_id: request.uuid
})
```

### 3. Use Tags

Tag logs for easy filtering:

```ruby
tags: ['security', 'permission', 'critical']
tags: ['workflow', 'approval', 'automated']
```

### 4. Set Appropriate Severity

- `info` - Normal operations
- `low` - Minor changes
- `medium` - Significant changes
- `high` - Security-sensitive actions
- `critical` - System-level changes

### 5. Mark Reversible Actions

```ruby
reversible: true  # For actions that can be undone
```

### 6. Regular Verification

Schedule integrity checks:

```ruby
# Weekly verification job
Bim::AuditLog.where('created_at > ?', 7.days.ago).each do |log|
  unless log.verify_checksum
    alert_security_team(log)
  end
end
```

## Troubleshooting

### Issue: Missing Audit Logs

**Cause**: Event not emitted or service not subscribed

**Solution**:
1. Check if event is being emitted
2. Verify `AuditTrailService` is initialized in `config/initializers/audit_trail.rb`
3. Check Rails logs for errors

### Issue: Checksum Verification Fails

**Cause**: Data modified after creation

**Investigation**:
```ruby
log = Bim::AuditLog.find(123)
puts log.checksum
puts log.send(:calculate_checksum_value)
# Compare outputs
```

**Action**: Investigate who/when/how the data was modified

### Issue: Performance Degradation

**Cause**: Large number of logs

**Solutions**:
1. Add indexes for your query patterns
2. Implement partitioning
3. Archive old logs
4. Use pagination in queries

## Regulatory Compliance

### GDPR

- **Right to Access**: Export user's audit trail
- **Right to Erasure**: Anonymize user_id (set to NULL)
- **Data Portability**: JSON export format

### SOX/ISO 27001

- **Audit Trail**: Complete, immutable log
- **Integrity**: SHA256 checksums
- **Retention**: 2-year default (configurable)
- **Access Control**: Role-based permissions

### Example Compliance Report

```bash
# Generate compliance report
rake bim:audit:report PROJECT_ID=1 SINCE="2025-01-01" > compliance_report.txt

# Export full audit trail
rake bim:audit:export PROJECT_ID=1 FORMAT=json OUTPUT=audit_trail_2025.json

# Verify integrity
rake bim:audit:verify PROJECT_ID=1 > integrity_verification.txt
```

---

**Version**: 9.3
**Last Updated**: 2025-11-10
**Author**: Claude AI Assistant
**Related**: WORKFLOW.md, PERFORMANCE.md, README.md
