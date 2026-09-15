# Federated Models Feature

## Overview

The Federated Models feature enables combining multiple IFC models (Architectural, Structural, MEP) into a coordinated federation with spatial alignment, discipline-based organization, and unified multi-model visualization.

## Key Features

### 1. Federation Management
- **Multi-Model Coordination**: Group multiple IFC models into a single federated view
- **Discipline Organization**: Classify models by discipline (Arch, Structural, MEP, etc.)
- **Project-Level Coordination**: Manage multiple federations per project
- **Version Control**: Track which model versions are included in each federation

### 2. Spatial Alignment
- **Coordinate System Management**: Define global origin and coordinate systems
- **Transformation Matrices**: Translation, rotation, and scale for each model
- **Auto-Alignment**: Automatic alignment based on shared grids or survey points
- **Manual Adjustment**: Fine-tune alignment with manual transformations

### 3. Unified Visualization
- **Multi-Model Loading**: Load all federated models in a single 3D viewer
- **Discipline Filtering**: Show/hide models by discipline
- **Visual Distinction**: Color-code models by discipline
- **Opacity Controls**: Adjust transparency per discipline or model

### 4. Cross-Model Queries
- **Element Search**: Find elements across all models in federation
- **Spatial Queries**: Query elements within a 3D zone from any model
- **Property Aggregation**: Aggregate properties across all models
- **Type Distribution**: Count element types across the federation

## Database Schema

### Tables

#### `bim_model_federations`
Stores federation definitions.

```sql
CREATE TABLE bim_model_federations (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  base_point JSONB NOT NULL DEFAULT '{"x": 0, "y": 0, "z": 0}'::jsonb,
  rotation JSONB NOT NULL DEFAULT '{"x": 0, "y": 0, "z": 0}'::jsonb,
  units VARCHAR(20) DEFAULT 'meters',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_federations_project ON bim_model_federations(project_id);
CREATE INDEX idx_federations_name ON bim_model_federations(name);
```

#### `bim_federation_models`
Stores individual models within a federation.

```sql
CREATE TABLE bim_federation_models (
  id BIGSERIAL PRIMARY KEY,
  model_federation_id BIGINT NOT NULL REFERENCES bim_model_federations(id) ON DELETE CASCADE,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  discipline INTEGER DEFAULT 99 NOT NULL,  -- 0=arch, 1=struct, 2=mech, etc.
  transform JSONB NOT NULL DEFAULT '{"translation": [0,0,0], "rotation": [0,0,0], "scale": [1,1,1]}'::jsonb,
  display_order INTEGER DEFAULT 0 NOT NULL,
  visible BOOLEAN DEFAULT true NOT NULL,
  color VARCHAR(7),
  opacity DECIMAL(3, 2) DEFAULT 1.0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_federation_model UNIQUE (model_federation_id, ifc_model_id),
  CONSTRAINT check_opacity_range CHECK (opacity >= 0.0 AND opacity <= 1.0)
);

CREATE INDEX idx_federation_models_federation ON bim_federation_models(model_federation_id);
CREATE INDEX idx_federation_models_discipline ON bim_federation_models(discipline);
```

### Disciplines Enum

| Value | Name         | Color   | Description                    |
|-------|--------------|---------|--------------------------------|
| 0     | Architectural| #3498DB | Building architecture          |
| 1     | Structural   | #E74C3C | Structural elements            |
| 2     | Mechanical   | #2ECC71 | HVAC and mechanical systems    |
| 3     | Electrical   | #F39C12 | Electrical systems             |
| 4     | Plumbing     | #9B59B6 | Plumbing and fire protection   |
| 5     | Civil        | #95A5A6 | Civil engineering              |
| 6     | Landscape    | #1ABC9C | Landscape architecture         |
| 99    | Other        | #34495E | Other disciplines              |

## API Reference

### List Federations

```http
GET /api/v3/projects/:project_id/bim/federations
```

**Response:**
```json
{
  "_type": "Collection",
  "total": 2,
  "count": 2,
  "_embedded": {
    "elements": [
      {
        "_type": "ModelFederation",
        "id": 1,
        "name": "Building A - Full Coordination",
        "description": "Complete building coordination",
        "base_point": { "x": 0, "y": 0, "z": 0 },
        "rotation": { "x": 0, "y": 0, "z": 0 },
        "units": "meters",
        "statistics": {
          "model_count": 5,
          "disciplines": { "architectural": 1, "structural": 1, "mechanical": 1 },
          "total_elements": 15000,
          "visible_models": 5
        }
      }
    ]
  }
}
```

### Create Federation

```http
POST /api/v3/projects/:project_id/bim/federations
Content-Type: application/json

{
  "name": "Building A - Full Coordination",
  "description": "Complete building with all disciplines",
  "model_ids": [123, 456, 789],
  "units": "meters",
  "auto_align": true
}
```

**Response:** `201 Created` with federation object

### Get Federation

```http
GET /api/v3/projects/:project_id/bim/federations/:id
```

### Update Federation

```http
PUT /api/v3/projects/:project_id/bim/federations/:id
Content-Type: application/json

{
  "name": "Updated Federation Name",
  "base_point": { "x": 100, "y": 200, "z": 0 }
}
```

### Delete Federation

```http
DELETE /api/v3/projects/:project_id/bim/federations/:id
```

**Response:** `204 No Content`

### Auto-Align Models

```http
POST /api/v3/projects/:project_id/bim/federations/:id/align
```

Automatically aligns all models in the federation using shared grids or survey points.

**Response:**
```json
{
  "message": "Models aligned successfully",
  "transformations": {
    "1": { "translation": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1] },
    "2": { "translation": [10, 5, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1] }
  }
}
```

### Get Viewer Configuration

```http
GET /api/v3/projects/:project_id/bim/federations/:id/viewer_config
```

Returns configuration for loading all models in the 3D viewer.

**Response:**
```json
{
  "_type": "FederationViewerConfig",
  "federation_id": 1,
  "name": "Building A - Full Coordination",
  "base_point": { "x": 0, "y": 0, "z": 0 },
  "rotation": { "x": 0, "y": 0, "z": 0 },
  "units": "meters",
  "models": [
    {
      "id": 10,
      "ifc_model_id": 123,
      "model_name": "Architecture Model",
      "discipline": "architectural",
      "transform": {
        "translation": [0, 0, 0],
        "rotation": [0, 0, 0],
        "scale": [1, 1, 1]
      },
      "visible": true,
      "color": "#3498DB",
      "opacity": 1.0,
      "display_order": 0
    }
  ]
}
```

## Backend Usage

### Creating a Federation

```ruby
# Using the service
service = Bim::Federations::CreateService.new(
  user: current_user,
  project: project
)

result = service.call(params: {
  name: 'Building A - Coordination',
  description: 'Full building coordination',
  model_ids: [123, 456, 789],
  units: 'meters',
  auto_align: true
})

if result.success?
  federation = result.result
  puts "Federation created: #{federation.name}"
  puts "Models: #{federation.statistics[:model_count]}"
else
  puts "Error: #{result.errors}"
end
```

### Manual Alignment

```ruby
federation = Bim::ModelFederation.find(1)
alignment_service = Bim::Federations::AlignmentService.new(federation)
result = alignment_service.call

if result.success?
  puts "Models aligned successfully"
  puts result.result # Transformation data
end
```

### Cross-Model Queries

```ruby
federation = Bim::ModelFederation.find(1)
query_service = Bim::Federations::QueryService.new(federation)

# Search for elements
results = query_service.search_elements('IfcWall', type_filter: 'IfcWall')
puts "Found #{results.size} walls across all models"

# Spatial query
zone = { min: [0, 0, 0], max: [50, 50, 20] }
elements = query_service.spatial_query(zone, discipline_filter: :mechanical)
puts "Found #{elements.size} mechanical elements in zone"

# Aggregate property
stats = query_service.aggregate_property('Area')
puts "Total area: #{stats[:sum]} (avg: #{stats[:average]})"

# Element type distribution
distribution = query_service.element_type_distribution
distribution.each do |type, count|
  puts "#{type}: #{count}"
end
```

## Frontend Usage

### FederationService

```typescript
import { FederationService } from './federation.service';

constructor(private federationService: FederationService) {}

// List federations
this.federationService.list(projectId).subscribe(federations => {
  console.log(`Found ${federations.length} federations`);
});

// Create federation
this.federationService.create(projectId, {
  name: 'Building A - Coordination',
  model_ids: [123, 456, 789],
  auto_align: true
}).subscribe(federation => {
  console.log('Federation created:', federation.name);
});

// Get viewer config
this.federationService.getViewerConfig(projectId, federationId)
  .subscribe(config => {
    console.log(`Loading ${config.models.length} models`);
  });
```

### FederatedViewerComponent

```html
<op-federated-viewer
  [projectId]="123"
  [federationId]="456"
  [viewer]="xeokitViewer"
  (loaded)="onFederationLoaded($event)"
  (modelVisibilityChanged)="onVisibilityChanged($event)">
</op-federated-viewer>
```

```typescript
onFederationLoaded(config: FederationViewerConfig): void {
  console.log(`Loaded federation: ${config.name}`);
  console.log(`Models: ${config.models.length}`);
}

onVisibilityChanged(event: { discipline: string; visible: boolean }): void {
  console.log(`${event.discipline} visibility: ${event.visible}`);
}
```

## Demo Data

Generate demo federations:

```bash
rails runner modules/bim/db/seeds/federation_demo_data.rb
```

This creates:
- 1 demo project
- 5 IFC models (Arch, Struct, Mech, Elec, Plumb)
- 4 federations:
  - **Full Coordination**: All 5 models
  - **Arch + Structure**: 2 models
  - **MEP Only**: 3 models (Mech, Elec, Plumb)
  - **Clash Coordination**: 3 models with transforms

## Testing

### Run Model Tests

```bash
bundle exec rspec modules/bim/spec/models/bim/model_federation_spec.rb
bundle exec rspec modules/bim/spec/models/bim/federation_model_spec.rb
```

### Using Factories

```ruby
# Create federation with models
federation = create(:bim_model_federation, :with_models, model_count: 3)

# Create multi-discipline federation
federation = create(:bim_model_federation, :multi_discipline)

# Create specific discipline models
arch_model = create(:bim_federation_model, :architectural)
struct_model = create(:bim_federation_model, :structural, :with_transform)
mech_model = create(:bim_federation_model, :mechanical, :semi_transparent)
```

## Best Practices

### 1. Federation Organization
- **Meaningful Names**: Use descriptive federation names (e.g., "Floor 3 - MEP Coordination")
- **Discipline Classification**: Accurately classify models by discipline
- **Model Versions**: Document which model versions are in each federation

### 2. Spatial Alignment
- **Grid-Based Alignment**: Use shared grids for consistent alignment
- **Survey Points**: Leverage real-world coordinates when available
- **Manual Verification**: Always verify auto-alignment results
- **Document Transforms**: Keep records of transformation values

### 3. Visualization
- **Logical Ordering**: Set display_order to control model loading sequence
- **Color Coding**: Use consistent discipline colors across projects
- **Opacity Management**: Make background models semi-transparent for clarity
- **Performance**: Limit federations to 10-15 models for optimal performance

### 4. Queries
- **Discipline Filtering**: Use discipline filters to narrow search scope
- **Type Filtering**: Combine with IFC type filters for precision
- **Spatial Zones**: Define reasonable zone sizes for spatial queries

## Performance Considerations

### Database
- Federations are indexed by project_id and name
- Federation models indexed by discipline and display_order
- JSONB transform field is efficient for read/write operations

### API
- Viewer config endpoint pre-calculates all transformations
- Statistics cached in response
- Use `visible_only` parameter to filter hidden models

### Frontend
- Load models sequentially with stagger to avoid browser freeze
- Apply transformations during model loading
- Use opacity slider debouncing for smooth updates
- Lazy-load discipline panels for large federations

## Troubleshooting

### Models Not Aligning

**Problem**: Auto-alignment doesn't align models correctly

**Solutions**:
1. Check if models have shared grids with matching names
2. Verify models have IfcSite with geographic coordinates
3. Use manual transformation as fallback
4. Check model metadata for spatial extent

### Slow Multi-Model Loading

**Problem**: Loading many models is slow

**Solutions**:
1. Enable model caching in xeokit
2. Reduce number of models in federation
3. Use model LOD (Level of Detail) if available
4. Stagger model loading with delays

### Discipline Colors Not Applying

**Problem**: Models don't show discipline colors

**Solutions**:
1. Check color format is valid hex (#RRGGBB)
2. Wait for model to fully load before applying color
3. Verify xeokit scene has model objects
4. Use setTimeout to delay color application

## Future Enhancements

- **Clash Detection Integration**: Run clash detection across federated models
- **4D Scheduling**: Integrate construction scheduling with federations
- **Real-Time Collaboration**: Multi-user federation editing
- **Cloud Alignment**: Server-side model alignment processing
- **Federation Templates**: Reusable federation configurations
- **Export Formats**: Export federated views to BCF, Navisworks, etc.

## Related Features

- **IFC Upload** (Slice 1): Uploads models for federation
- **3D Viewer** (Slice 2): Displays federated models
- **Element Linking** (Slice 3): Link work packages to federated elements
- **Clash Detection** (Slice 4): Detect clashes between federated models
- **Progress Tracking** (Slice 6): Track progress across federated models

## Support

For issues or questions:
- GitHub Issues: https://github.com/opf/openproject/issues
- Documentation: https://www.openproject.org/docs/bim/
- Community Forums: https://community.openproject.org/
