# IFC Upload Enhancement

## Overview

The IFC Upload Enhancement feature provides comprehensive validation, progress tracking, and metadata extraction for IFC (Industry Foundation Classes) model uploads. This enhancement transforms the basic IFC upload process into a robust, transparent, and informative workflow.

## Key Features

### 1. Pre-Upload Validation
- **IFC Version Detection**: Automatic detection of IFC schema version (IFC2x3, IFC4, IFC4x3)
- **Schema Validation**: STEP file format validation with detailed error reporting
- **Complexity Analysis**: Entity and geometry count analysis with complexity scoring
- **Duplicate Detection**: SHA256 checksum-based deduplication
- **Conversion Time Estimation**: Intelligent estimation based on model complexity

### 2. Multi-Stage Progress Tracking
- **6-Stage Pipeline Visualization**:
  1. Validation
  2. IFC → DAE conversion
  3. DAE → glTF conversion
  4. glTF → XKT conversion
  5. Enhanced metadata extraction
  6. Optimization

- **Real-Time Progress Updates**: Live progress percentage and stage indicators
- **Detailed Conversion Logs**: Per-stage logging with timestamps and details
- **Turbo Streams Integration**: WebSocket-based real-time UI updates

### 3. Enhanced Metadata Extraction
- **Spatial Structure**: Complete building hierarchy (Project → Site → Building → Storey → Space)
- **Property Sets (Psets)**: All IFC property sets with searchable interface
- **Quantities (QTO)**: Areas, volumes, and element counts
- **Classifications**: Uniclass, OmniClass, and other classification systems
- **Materials**: Material definitions with properties and layers
- **Types/Families**: Element types with usage counts
- **Performance Metrics**: Conversion time tracking and efficiency calculations

### 4. API Enhancements
- **Model Details Endpoint**: `/api/v3/bim/ifc_models/:id` with metadata summary
- **Conversion Logs Endpoint**: `/api/v3/bim/ifc_models/:id/conversion_logs`
- **Metadata Endpoint**: `/api/v3/bim/ifc_models/:id/metadata`
- **Metadata Refresh**: `/api/v3/bim/ifc_models/:id/refresh_metadata` (POST)

### 5. Frontend Components
- **Upload Progress Component**: Real-time conversion progress with stage indicators
- **Metadata Viewer**: Tabbed interface for exploring model metadata
- **Validation Warnings Display**: Clear presentation of warnings and errors
- **Duplicate Detection UI**: Visual indicators for duplicate models

---

## Database Schema

### New Table: `bim_ifc_model_metadata`

```sql
CREATE TABLE bim_ifc_model_metadata (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL UNIQUE,

  -- IFC File Information
  ifc_version VARCHAR(20),          -- 'IFC2x3', 'IFC4', 'IFC4x3'
  file_schema VARCHAR(50),          -- 'IFC4_ADD2', etc.
  file_checksum VARCHAR(64),        -- SHA256 for deduplication
  entity_count INTEGER,
  geometry_count INTEGER,

  -- JSONB Metadata
  spatial_structure JSONB NOT NULL DEFAULT '{}',
  property_sets JSONB NOT NULL DEFAULT '{}',
  quantities JSONB NOT NULL DEFAULT '{}',
  classifications JSONB NOT NULL DEFAULT '{}',
  materials JSONB NOT NULL DEFAULT '{}',
  types JSONB NOT NULL DEFAULT '{}',
  validation_result JSONB NOT NULL DEFAULT '{}',

  -- Performance Metrics
  estimated_conversion_time INTEGER,
  actual_conversion_time INTEGER,

  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (ifc_model_id) REFERENCES bim_ifc_models(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_ifc_metadata_version ON bim_ifc_model_metadata(ifc_version);
CREATE INDEX idx_ifc_metadata_checksum ON bim_ifc_model_metadata(file_checksum);
CREATE INDEX idx_ifc_metadata_entity_count ON bim_ifc_model_metadata(entity_count);

-- GIN indexes for JSONB queries
CREATE INDEX idx_ifc_metadata_spatial_gin ON bim_ifc_model_metadata USING GIN(spatial_structure);
CREATE INDEX idx_ifc_metadata_psets_gin ON bim_ifc_model_metadata USING GIN(property_sets);
CREATE INDEX idx_ifc_metadata_quantities_gin ON bim_ifc_model_metadata USING GIN(quantities);
CREATE INDEX idx_ifc_metadata_classifications_gin ON bim_ifc_model_metadata USING GIN(classifications);
CREATE INDEX idx_ifc_metadata_materials_gin ON bim_ifc_model_metadata USING GIN(materials);
CREATE INDEX idx_ifc_metadata_types_gin ON bim_ifc_model_metadata USING GIN(types);
```

### Enhanced Columns on `bim_ifc_models`

```sql
ALTER TABLE bim_ifc_models
  ADD COLUMN conversion_stage VARCHAR(50),
  ADD COLUMN conversion_progress INTEGER DEFAULT 0 CHECK (conversion_progress >= 0 AND conversion_progress <= 100),
  ADD COLUMN conversion_logs JSONB DEFAULT '[]',
  ADD COLUMN conversion_started_at TIMESTAMP,
  ADD COLUMN conversion_completed_at TIMESTAMP;

CREATE INDEX idx_ifc_models_conversion_state ON bim_ifc_models(conversion_status, conversion_stage);
CREATE INDEX idx_ifc_models_progress ON bim_ifc_models(conversion_progress);
CREATE INDEX idx_ifc_models_conversion_logs_gin ON bim_ifc_models USING GIN(conversion_logs);
```

---

## Usage

### Backend

#### Validating an IFC File

```ruby
validator = Bim::IfcModels::ValidatorService.new('/path/to/model.ifc')
result = validator.call

if result[:valid]
  puts "IFC Version: #{result[:ifc_version]}"
  puts "Entity Count: #{result[:entity_count]}"
  puts "Estimated Conversion Time: #{result[:estimated_conversion_time]}s"
  puts "File Checksum: #{result[:file_checksum]}"

  # Check for warnings
  if result[:warnings].any?
    puts "Warnings:"
    result[:warnings].each { |w| puts "  - #{w}" }
  end
else
  puts "Validation failed:"
  puts result[:schema_errors].join("\n")
end
```

#### Extracting Metadata

```ruby
ifc_model = Bim::IfcModels::IfcModel.find(123)
extractor = Bim::IfcModels::MetadataExtractorService.new(ifc_model)
result = extractor.call

if result.success?
  metadata = result.result

  # Access metadata
  puts "IFC Version: #{metadata.ifc_version}"
  puts "Total Area: #{metadata.total_area} m²"
  puts "Total Volume: #{metadata.total_volume} m³"
  puts "Building Storeys: #{metadata.building_storeys.size}"
  puts "Complexity Score: #{metadata.complexity_score}"

  # Check for duplicates
  if metadata.duplicate?
    puts "Duplicate model detected!"
    puts "Duplicates: #{metadata.duplicates.count}"
  end
else
  puts "Metadata extraction failed: #{result.errors.join(', ')}"
end
```

#### Querying Metadata

```ruby
# Find all IFC4 models
ifc4_models = Bim::IfcModels::IfcModelMetadata.by_version('IFC4')

# Find complex models
complex_models = Bim::IfcModels::IfcModelMetadata.where(
  "validation_result->>'complexity_score' > ?", '0.7'
)

# Find models with specific property set
models_with_pset = Bim::IfcModels::IfcModelMetadata.where(
  "property_sets ? :pset_name", pset_name: 'Pset_WallCommon'
)

# Find large models
large_models = Bim::IfcModels::IfcModelMetadata.with_entities_count_above(100_000)
```

### API

#### Get Model with Metadata

```bash
GET /api/v3/bim/ifc_models/123

Response:
{
  "_type": "IfcModel",
  "id": 123,
  "title": "Office Building",
  "conversion_status": "completed",
  "conversion_stage": null,
  "conversion_progress": 100,
  "metadata_summary": {
    "ifc_version": "IFC4",
    "entity_count": 45000,
    "geometry_count": 22000,
    "complexity_score": 0.5,
    "validation_passed": true,
    "has_duplicates": false
  },
  "_links": {
    "self": { "href": "/api/v3/bim/ifc_models/123" },
    "conversionLogs": { "href": "/api/v3/bim/ifc_models/123/conversion_logs" },
    "metadata": { "href": "/api/v3/bim/ifc_models/123/metadata" }
  }
}
```

#### Get Conversion Logs

```bash
GET /api/v3/bim/ifc_models/123/conversion_logs

Response:
{
  "_type": "IfcModelConversionLogs",
  "ifc_model_id": 123,
  "conversion_status": "completed",
  "conversion_stage": null,
  "conversion_progress": 100,
  "conversion_started_at": "2025-01-15T10:00:00Z",
  "conversion_completed_at": "2025-01-15T10:05:30Z",
  "logs": [
    {
      "timestamp": "2025-01-15T10:00:00Z",
      "stage": "validation",
      "level": "info",
      "message": "Starting Validation",
      "details": {}
    },
    {
      "timestamp": "2025-01-15T10:00:15Z",
      "stage": "validation",
      "level": "info",
      "message": "Completed Validation",
      "details": {}
    },
    ...
  ]
}
```

#### Get Full Metadata

```bash
GET /api/v3/bim/ifc_models/123/metadata

Response:
{
  "_type": "IfcModelMetadata",
  "ifc_model_id": 123,
  "ifc_version": "IFC4",
  "entity_count": 45000,
  "geometry_count": 22000,
  "spatial_structure": { ... },
  "property_sets": { ... },
  "quantities": {
    "total_area": 5000.0,
    "total_volume": 15000.0,
    "by_type": { ... }
  },
  "classifications": { ... },
  "materials": { ... },
  "validation_result": {
    "warnings": [],
    "errors": [],
    "complexity_score": 0.5
  },
  "summary": {
    "ifc_version": "IFC4",
    "entity_count": 45000,
    "total_area": 5000.0,
    "complexity": 0.5,
    "duplicate": false,
    "validation_passed": true
  }
}
```

#### Refresh Metadata

```bash
POST /api/v3/bim/ifc_models/123/refresh_metadata

Response:
{
  "_type": "IfcModelMetadata",
  "message": "Metadata extraction triggered successfully",
  "ifc_model_id": 123
}
```

### Frontend

#### Upload Progress Component

```typescript
<op-ifc-upload-progress
  [modelId]="123"
  (conversionCompleted)="onCompleted($event)"
  (conversionError)="onError($event)">
</op-ifc-upload-progress>
```

Features:
- Real-time progress bar (0-100%)
- 6-stage pipeline visualization
- Validation warnings display
- Error message display
- Conversion logs viewer
- Metadata summary on completion

#### Metadata Viewer Component

```typescript
<op-ifc-metadata-viewer
  [modelId]="123"
  (elementSelected)="onElementSelected($event)">
</op-ifc-metadata-viewer>
```

Features:
- Tabbed interface: Overview, Spatial Structure, Properties, Quantities, Materials, Validation
- Searchable property sets
- Spatial hierarchy tree view
- Material list with properties
- Validation results with complexity score
- Refresh metadata button

---

## Demo Data

Generate demo data with sample IFC models and comprehensive metadata:

```bash
rails runner modules/bim/db/seeds/ifc_upload_demo_data.rb
```

This creates:
- 5 IFC models with various scenarios:
  - Simple IFC4 model (completed)
  - Complex IFC2X3 model with warnings
  - Model currently converting (65% progress)
  - Model with conversion error
  - Duplicate model

Each model includes:
- Comprehensive metadata (spatial structure, property sets, quantities, etc.)
- Conversion logs
- Validation results
- Performance metrics

---

## Testing

### Model Tests

```bash
bundle exec rspec modules/bim/spec/models/bim/ifc_models/ifc_model_metadata_spec.rb
```

### Service Tests

```bash
bundle exec rspec modules/bim/spec/services/bim/ifc_models/validator_service_spec.rb
bundle exec rspec modules/bim/spec/services/bim/ifc_models/metadata_extractor_service_spec.rb
```

### API Tests

```bash
bundle exec rspec modules/bim/spec/controllers/api/v3/bim/ifc_models_controller_spec.rb
```

---

## Performance Considerations

### Database Optimization
- **GIN Indexes**: All JSONB columns have GIN indexes for fast queries
- **Selective Loading**: Use `.includes(:ifc_model_metadata)` to avoid N+1 queries
- **Partial Indexes**: Checksum index only on non-null values

### Caching
- Metadata extraction is expensive; results are cached in the database
- Use `refresh_metadata` endpoint sparingly
- Consider background jobs for re-extraction

### Conversion Pipeline
- Stages execute sequentially; progress updates happen after each stage
- Large models (>100k entities) may take 5-10 minutes
- Progress estimation uses heuristics based on entity count

---

## Troubleshooting

**Validation fails with "Unable to detect IFC version":**
- Ensure file is valid STEP format (starts with `ISO-10303-21`)
- Check that FILE_SCHEMA header contains IFC version

**Metadata extraction returns empty results:**
- Verify IFC file is not corrupted
- Check that Python/IfcOpenShell is available
- Review extraction script logs in `lib/bim/python/extract_metadata.py`

**Conversion stuck at specific stage:**
- Check conversion logs for detailed error messages
- Large models may appear stuck but are still processing
- Monitor system resources (CPU, memory)

**Duplicate detection not working:**
- Ensure file_checksum is being calculated
- Check that SHA256 digests are stored correctly
- Verify uniqueness constraint on checksums

**Progress updates not appearing in real-time:**
- Check Turbo Streams/WebSocket connection
- Verify background job queue is running
- Ensure frontend is subscribing to correct channel

---

## Future Enhancements

- **Advanced Validation**: Integration with buildingSMART validation service
- **LOD Generation**: Automatic Level of Detail generation for large models
- **CDN Integration**: Cached conversion artifacts for common models
- **Metadata Search**: Full-text search across property sets and quantities
- **Conversion Retry**: Automatic retry with different parameters on failure
- **Model Comparison**: Side-by-side metadata comparison for different versions
- **Export Formats**: Export metadata to Excel, JSON, or XML

---

## Related Features

- **Model Comparison (Slice 5)**: Version control and change detection
- **Clash Detection (Slice 6)**: Geometry conflict identification
- **Progress Tracking (Slice 9)**: Element-level construction progress
- **BIM Dashboards (Slice 8)**: Metrics and KPIs visualization
- **BCF Integration**: Issue tracking with IFC elements

---

## References

- [IFC Specification](https://www.buildingsmart.org/standards/bsi-standards/industry-foundation-classes/)
- [IfcOpenShell Documentation](http://ifcopenshell.org/)
- [xeokit Documentation](https://xeokit.io/)
- [OpenProject BIM Edition](https://www.openproject.org/bim-project-management/)
