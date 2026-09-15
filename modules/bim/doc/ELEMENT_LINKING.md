# BIM Element Linking Feature

## Overview

The Element Linking feature enables direct many-to-many relationships between OpenProject work packages and BIM elements within IFC models. This provides powerful integration between project management and 3D BIM data, allowing teams to track work, defects, and changes at the element level.

## Table of Contents

1. [Key Features](#key-features)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [API Reference](#api-reference)
5. [Frontend Components](#frontend-components)
6. [Usage Examples](#usage-examples)
7. [Best Practices](#best-practices)
8. [Performance Considerations](#performance-considerations)

## Key Features

### 1. Many-to-Many Element Links
- Link multiple BIM elements to a single work package
- Link a single element to multiple work packages
- Track different types of relationships (affected_by, responsible_for, etc.)

### 2. Relationship Types
- **affected_by**: Element is impacted by the work package (e.g., defects)
- **responsible_for**: Work package tracks work on this element
- **depends_on**: Work package depends on element state
- **observes**: Monitoring element status
- **related_to**: General relationship

### 3. Template System
- Create reusable link templates with element filters
- Filter by IFC type, location, classification, properties, tags
- Apply templates to quickly link matching elements
- Preview matching elements before creating links (dry-run mode)

### 4. Bulk Operations
- Create multiple links at once
- Update link status in bulk (active → completed → archived)
- Delete multiple links (soft or hard delete)
- Refresh element properties to detect changes

### 5. Change Detection
- Capture element properties at link creation time
- Detect geometry and property changes
- Track element modifications over time

### 6. Visual Integration
- 3D viewer integration with xeokit
- Color-coded element highlighting by relationship type
- Interactive element selection
- Camera navigation to linked elements

### 7. Work Package Generation
- Create work packages from element selections
- Group elements by type, location, or create individually
- Template-based work package creation with placeholders

## Architecture

### Backend (Ruby/Rails)

```
┌─────────────────────────────────────────────────────────┐
│                    API Controllers                       │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │ ElementLinks     │  │ BulkOperations   │Templates  │ │
│  │ Controller       │  │ Controller       │Controller │ │
│  └────────┬─────────┘  └────────┬─────────┴───────────┘ │
└───────────┼──────────────────────┼───────────────────────┘
            │                      │
┌───────────┼──────────────────────┼───────────────────────┐
│           ▼                      ▼                        │
│     Service Layer                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │      BulkLinkOperationsService                   │   │
│  │  - Bulk creation/update/delete                   │   │
│  │  - Template application                          │   │
│  │  - Work package generation                       │   │
│  │  - Property refresh                              │   │
│  └───────────────────┬──────────────────────────────┘   │
└────────────────────────┼─────────────────────────────────┘
                         │
┌────────────────────────┼─────────────────────────────────┐
│                        ▼                                  │
│     Model Layer                                           │
│  ┌──────────────────┐    ┌──────────────────────────┐   │
│  │  ElementLink     │    │  LinkTemplate            │   │
│  │  - Validations   │    │  - Element filtering     │   │
│  │  - Relationships │    │  - Matching algorithm    │   │
│  │  - Change detect │    │  - Statistics            │   │
│  └──────────────────┘    └──────────────────────────┘   │
└───────────────────────────────────────────────────────────┘
```

### Frontend (Angular/TypeScript)

```
┌─────────────────────────────────────────────────────────┐
│              UI Components                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │        LinkManagementPanel                       │   │
│  │  - Tabs (Links, Templates, Statistics)          │   │
│  │  - Selection mode                                │   │
│  │  - Filtering and search                          │   │
│  │  - Bulk actions                                  │   │
│  └───────────────────┬──────────────────────────────┘   │
└────────────────────────┼─────────────────────────────────┘
                         │
┌────────────────────────┼─────────────────────────────────┐
│                        ▼                                  │
│     Service Layer                                         │
│  ┌──────────────────┐    ┌──────────────────────────┐   │
│  │ ElementLink      │    │ BulkLinkOperations       │   │
│  │ Manager          │    │ Service                  │   │
│  │ - CRUD ops       │    │ - API calls              │   │
│  │ - Visualization  │    │ - Template mgmt          │   │
│  │ - Selection      │    │ - Bulk operations        │   │
│  └────────┬─────────┘    └──────────────────────────┘   │
└───────────┼──────────────────────────────────────────────┘
            │
┌───────────┼──────────────────────────────────────────────┐
│           ▼                                               │
│    Viewer Integration                                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │    ElementLinkViewerIntegration                  │   │
│  │  - xeokit integration                            │   │
│  │  - Element highlighting                          │   │
│  │  - Camera navigation                             │   │
│  │  - Event handling                                │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────┘
```

## Database Schema

### `bim_element_links`

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| work_package_id | integer | Reference to work package (FK) |
| ifc_model_id | integer | Reference to IFC model (FK) |
| element_id | string(50) | IFC element GUID |
| relationship_type | integer | Enum: 0-4 (relationship type) |
| status | integer | Enum: 0-2 (active, completed, archived) |
| element_properties | jsonb | Snapshot of element data |
| template_id | integer | Reference to template (FK, nullable) |
| user_id | integer | User who created link (FK, nullable) |
| created_at | timestamp | Creation time |
| updated_at | timestamp | Last update time |

**Indexes:**
- Unique: (work_package_id, element_id)
- Standard: ifc_model_id, relationship_type, status, template_id
- GIN: element_properties

### `bim_link_templates`

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| name | string | Template name |
| description | text | Template description |
| relationship_type | integer | Default relationship type |
| work_package_type | string | Work package type (nullable) |
| element_filters | jsonb | Filter criteria |
| template_data | jsonb | Additional config |
| auto_apply | boolean | Auto-apply on model load |
| public | boolean | Available to all projects |
| project_id | integer | Project scope (FK, nullable) |
| author_id | integer | Template creator (FK) |
| created_at | timestamp | Creation time |
| updated_at | timestamp | Last update time |

**Indexes:**
- Standard: project_id, relationship_type, public, name
- GIN: element_filters, template_data
- Unique: (project_id, name) WHERE project_id IS NOT NULL

## API Reference

### Element Links

#### List Links
```
GET /api/v3/bim/element_links
```

**Query Parameters:**
- `work_package_id`: Filter by work package
- `ifc_model_id`: Filter by IFC model
- `element_id`: Filter by element
- `relationship_type`: Filter by type
- `status`: Filter by status
- `template_id`: Filter by template
- `page`: Page number (default: 1)
- `per_page`: Items per page (max: 100)

**Response:**
```json
{
  "_type": "Collection",
  "total": 10,
  "count": 10,
  "_embedded": {
    "elements": [
      {
        "_type": "ElementLink",
        "id": 123,
        "element_id": "wall-101",
        "relationship_type": "affected_by",
        "status": "active",
        "element_properties": {...},
        "created_at": "2025-01-15T10:00:00Z",
        "_links": {
          "self": {"href": "/api/v3/bim/element_links/123"},
          "work_package": {"href": "/api/v3/work_packages/456"},
          "ifc_model": {"href": "/api/v3/bim/ifc_models/789"}
        }
      }
    ]
  }
}
```

#### Create Link
```
POST /api/v3/bim/element_links
```

**Request Body:**
```json
{
  "element_link": {
    "work_package_id": 456,
    "ifc_model_id": 789,
    "element_id": "wall-101",
    "relationship_type": "affected_by"
  }
}
```

### Bulk Operations

#### Bulk Create
```
POST /api/v3/bim/element_links/bulk_create
```

**Request Body:**
```json
{
  "work_package_id": 456,
  "ifc_model_id": 789,
  "element_ids": ["wall-101", "wall-102", "wall-103"],
  "relationship_type": "affected_by"
}
```

**Response:**
```json
{
  "_type": "BulkOperationResult",
  "success_count": 3,
  "failure_count": 0,
  "created": [...],
  "failed": []
}
```

#### Apply Template
```
POST /api/v3/bim/element_links/apply_template
```

**Request Body:**
```json
{
  "work_package_id": 456,
  "ifc_model_id": 789,
  "template_id": 123,
  "dry_run": true
}
```

**Dry-Run Response:**
```json
{
  "matching_elements": ["wall-101", "wall-102"],
  "count": 2
}
```

### Templates

#### Create Template
```
POST /api/v3/bim/link_templates
```

**Request Body:**
```json
{
  "link_template": {
    "name": "Structural Walls",
    "description": "All load-bearing walls",
    "relationship_type": "responsible_for",
    "element_filters": {
      "types": ["IfcWall"],
      "properties": {
        "LoadBearing": "True"
      },
      "tags": ["structural"]
    },
    "project_id": 1
  }
}
```

#### Clone Template
```
POST /api/v3/bim/link_templates/123/clone
```

**Request Body:**
```json
{
  "new_name": "Structural Walls - Observes",
  "modifications": {
    "relationship_type": "observes"
  }
}
```

## Frontend Components

### LinkManagementPanel

Main UI component for link management.

**Usage:**
```html
<op-link-management-panel
  [workPackageId]="123"
  [ifcModelId]="456"
  [viewer]="xeokitViewer"
  (linkCreated)="onLinkCreated($event)"
  (linkDeleted)="onLinkDeleted($event)"
  (selectionModeChanged)="onSelectionModeChanged($event)">
</op-link-management-panel>
```

**Features:**
- Tabbed interface (Links, Templates, Statistics)
- Selection mode for interactive element picking
- Filtering and search
- Bulk operations
- Template application
- Visual link highlighting

### ElementLinkViewerIntegration

xeokit viewer integration class.

**Usage:**
```typescript
import { createViewerIntegration } from './element-link-viewer-integration';

const integration = createViewerIntegration(
  xeokitViewer,
  elementLinkManager,
  {
    onElementSelected: (elementId) => console.log('Selected:', elementId),
    onLinkVisualized: (links) => console.log('Visualized:', links)
  }
);

// Visualize links with color coding
integration.visualizeLinks(links);

// Navigate to element
integration.flyToElement('wall-101');

// Clean up
integration.destroy();
```

## Usage Examples

### Example 1: Manual Link Creation

```typescript
// Enter selection mode
linkManager.startLinkingMode(workPackageId, 'affected_by');

// User clicks elements in viewer...
// Elements are highlighted as they're selected

// Create links from selection
linkManager.createLinksFromSelection(workPackageId, 'affected_by')
  .subscribe(links => {
    console.log('Created', links.length, 'links');

    // Visualize the new links
    viewerIntegration.visualizeLinks(links);
  });
```

### Example 2: Template-Based Linking

```typescript
// Preview template matching
bulkOps.applyTemplate({
  work_package_id: 123,
  ifc_model_id: 456,
  template_id: 789,
  dry_run: true
}).subscribe(result => {
  console.log(result.count, 'elements will be linked');

  if (confirm(`Create ${result.count} links?`)) {
    // Apply template for real
    bulkOps.applyTemplate({
      work_package_id: 123,
      ifc_model_id: 456,
      template_id: 789,
      dry_run: false
    }).subscribe(result => {
      console.log('Created', result.success_count, 'links');
    });
  }
});
```

### Example 3: Bulk Status Change

```typescript
// Complete all active links for a work package
bulkOps.bulkStatusChange({
  link_ids: activeLinkIds,
  new_status: 'completed'
}).subscribe(result => {
  console.log('Completed', result.updated_count, 'links');
});
```

### Example 4: Work Package Generation

```typescript
// Create work packages from selected elements
bulkOps.createWorkPackagesFromElements({
  ifc_model_id: 456,
  element_ids: selectedElementIds,
  work_package_template: {
    project_id: 1,
    type_id: 5,
    subject: 'Work on {group} ({count} elements)',
    description: 'Maintenance work'
  },
  relationship_type: 'responsible_for',
  grouping_strategy: 'by_type'
}).subscribe(result => {
  console.log('Created', result.work_package_count, 'work packages');
  console.log('Created', result.link_count, 'links');
});
```

## Best Practices

### 1. Template Design

**DO:**
- Use descriptive template names
- Document filter criteria in description
- Test templates with dry-run before applying
- Use specific filters to avoid over-matching

**DON'T:**
- Create overly broad templates
- Forget to set appropriate relationship type
- Make templates public without team review

### 2. Relationship Types

**Use Guidelines:**
- **affected_by**: Defects, issues, problems with elements
- **responsible_for**: Work/tasks being performed on elements
- **depends_on**: Dependencies between WP and element state
- **observes**: Monitoring, inspection, tracking
- **related_to**: General association without specific semantics

### 3. Bulk Operations

**Best Practices:**
- Use bulk operations for >10 links
- Check rate limits (10 requests/minute)
- Handle partial successes gracefully
- Provide user feedback during bulk operations

### 4. Change Detection

**Recommendations:**
- Refresh properties periodically (weekly/monthly)
- Act on geometry_changed? notifications
- Document element state at link creation
- Archive links for deleted elements

## Performance Considerations

### Database

- **Indexes**: GIN indexes on JSONB for fast filtering
- **Pagination**: Always paginate large result sets
- **Batch Loading**: Use includes() for associations
- **Query Optimization**: Filter at database level, not in memory

### Frontend

- **Lazy Loading**: Load links on-demand, not upfront
- **Virtual Scrolling**: For large link lists (>100)
- **Debouncing**: Search inputs should debounce (300ms)
- **Memoization**: Cache expensive computations

### Viewer

- **Color Restoration**: Store original colors for cleanup
- **Selective Highlighting**: Highlight only visible elements
- **Camera Animations**: Use appropriate duration (1-2s)
- **Cleanup**: Always call destroy() on unmount

### API

- **Rate Limiting**: Respect 10 req/min limit for bulk ops
- **Batch Requests**: Use bulk endpoints instead of loops
- **Pagination**: Request only needed page size
- **Caching**: Cache template lists (low change frequency)

## Troubleshooting

### Links Not Appearing in Viewer

**Possible Causes:**
1. Element ID mismatch (check exact IFC GUID)
2. Element not loaded in viewer yet
3. Visualization not called after link creation

**Solutions:**
```typescript
// Verify element exists in viewer
const entity = viewer.scene.objects[elementId];
if (!entity) {
  console.error('Element not found:', elementId);
}

// Refresh visualization
viewerIntegration.visualizeLinks(links);
```

### Template Not Matching Expected Elements

**Debugging:**
```typescript
// Test template locally
const template = getTemplate(templateId);
const elements = ifcModel.metadata.elements;
Object.entries(elements).forEach(([id, data]) => {
  const matches = template.element_matches_filters?(data);
  if (!matches) {
    console.log('No match:', id, data);
  }
});
```

### Rate Limit Errors

**Solution:**
```typescript
// Implement exponential backoff
async function createLinksWithRetry(params, retries = 3) {
  try {
    return await bulkOps.createBulkLinks(params).toPromise();
  } catch (error) {
    if (error.status === 429 && retries > 0) {
      await delay(Math.pow(2, 3 - retries) * 1000);
      return createLinksWithRetry(params, retries - 1);
    }
    throw error;
  }
}
```

## Support

For issues, questions, or feature requests:
- GitHub Issues: https://github.com/opf/openproject/issues
- Community Forum: https://community.openproject.org
- Documentation: https://docs.openproject.org

## License

Copyright (C) OpenProject GmbH

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3.
