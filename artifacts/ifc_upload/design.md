# Slice 1: IFC Upload Enhancement - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 1 (Foundation for all other slices)
**Dependencies:** None (foundational)

---

## Current State Analysis

### Existing Capabilities (Community Edition)
- Basic IFC file upload via `IFCModelsController`
- 4-stage conversion pipeline: IFC → DAE → glTF → XKT
- Async processing via `IFCConversionJob` (GoodJob queue)
- S3/cloud storage support via DirectUpload
- Conversion status tracking (pending/processing/completed/error)
- 512MB default file size limit

### Current Architecture
```
User Upload
    ↓
IFCModelsController#create
    ↓
Attachment Created (description: "ifc")
    ↓
IFCConversionJob (async)
    ↓
ViewConverterService
    ├─→ IfcConvert (IFC → DAE)
    ├─→ COLLADA2GLTF (DAE → glTF)
    ├─→ xeokit-metadata (extract)
    └─→ gltf2xkt (glTF → XKT)
    ↓
Attachment Created (description: "xkt")
```

### Limitations to Address
1. **No schema validation** before conversion starts
2. **No chunk/resumable uploads** for very large files (>1GB)
3. **Limited metadata extraction** (only what xeokit-metadata provides)
4. **No IFC version detection** (IFC2x3 vs IFC4)
5. **No preprocessing** to optimize problematic models
6. **Error messages lack detail** for debugging conversion failures
7. **No progress reporting** during conversion stages
8. **No deduplication** of identical models

---

## Enterprise Enhancement Goals

### 1. Advanced Validation (Pre-Conversion)
- **IFC Schema Validation**: Validate against IFC2x3/IFC4 schemas before conversion
- **File Integrity Checks**: Checksums, corruption detection
- **Version Detection**: Automatic IFC version identification
- **Structural Analysis**: Detect problematic geometries early
- **Size/Complexity Metrics**: Estimate conversion time

### 2. Async Handling Improvements
- **Multi-Stage Progress Reporting**: Real-time updates for each conversion stage
- **Chunked Upload Support**: For files >1GB using Uppy or similar
- **Resumable Conversions**: Restart from failed stage, not beginning
- **Priority Queue**: Differentiate urgent vs background conversions
- **Parallel Processing**: Multiple conversion stages simultaneously

### 3. Enhanced Metadata Extraction
- **IFC Property Sets**: Extract custom property sets (Psets)
- **Spatial Structure**: Building → Storey → Space hierarchy
- **Quantity Takeoffs**: Areas, volumes, counts
- **Classification Systems**: Uniclass, OmniClass, etc.
- **Material Definitions**: Material layers, thermal properties

### 4. Error Handling & Recovery
- **Detailed Error Logs**: Per-stage logs with diagnostic info
- **Automatic Retry**: With exponential backoff for transient failures
- **Fallback Strategies**: Alternative conversion paths
- **Partial Success**: Display simplified model if full conversion fails
- **User Notifications**: Email/in-app alerts with actionable guidance

### 5. Optimization & Performance
- **Model Simplification**: LOD (Level of Detail) generation
- **Deduplication**: Hash-based detection of identical models
- **Caching**: Conversion artifacts for common models
- **Compression**: Optimize XKT file size
- **CDN Integration**: Fast delivery of converted models

---

## Proposed Architecture

### Layer 1: Upload & Validation

```ruby
# New Service: modules/bim/app/services/bim/ifc_models/validator_service.rb
class Bim::IFCModels::ValidatorService
  def call(ifc_file_path)
    {
      valid: true/false,
      ifc_version: "IFC4",
      schema_errors: [],
      warnings: [],
      file_size: 1024000,
      entity_count: 50000,
      estimated_conversion_time: 120 # seconds
    }
  end

  private

  def detect_ifc_version(file)
    # Parse header: FILE_SCHEMA(('IFC4'));
  end

  def validate_schema(file, version)
    # Use IfcOpenShell Python bindings or custom parser
  end

  def analyze_complexity(file)
    # Count entities, detect large geometries
  end
end
```

### Layer 2: Enhanced Conversion Pipeline

```ruby
# Enhanced: modules/bim/app/services/bim/ifc_models/view_converter_service.rb
class Bim::IFCModels::ViewConverterService
  STAGES = %i[
    validation
    ifc_to_dae
    dae_to_gltf
    metadata_extraction
    gltf_to_xkt
    optimization
  ].freeze

  def call
    STAGES.each_with_index do |stage, index|
      update_progress(stage, index, STAGES.size)
      send("stage_#{stage}")
    rescue => e
      handle_stage_failure(stage, e)
    end
  end

  private

  def update_progress(stage, current, total)
    ifc_model.update!(
      conversion_stage: stage,
      conversion_progress: (current.to_f / total * 100).round
    )
    broadcast_progress_event # WebSocket/Turbo Streams
  end

  def stage_validation
    result = ValidatorService.new(ifc_file_path).call
    raise ValidationError unless result[:valid]
    ifc_model.update!(metadata: result)
  end

  def stage_optimization
    # Simplify XKT, generate LODs
    OptimizationService.new(xkt_path).call
  end
end
```

### Layer 3: Metadata Extraction

```ruby
# New Service: modules/bim/app/services/bim/ifc_models/metadata_extractor_service.rb
class Bim::IFCModels::MetadataExtractorService
  def call(ifc_file_path)
    {
      spatial_structure: extract_spatial_structure,
      property_sets: extract_property_sets,
      quantities: extract_quantities,
      classifications: extract_classifications,
      materials: extract_materials,
      types: extract_types
    }
  end

  private

  def extract_spatial_structure
    # Use IfcOpenShell to traverse:
    # IfcProject → IfcSite → IfcBuilding → IfcBuildingStorey → IfcSpace
  end

  def extract_property_sets
    # Extract all Pset_* properties
  end
end
```

### Layer 4: Database Schema Updates

```ruby
# New Migration: add_enhanced_metadata_to_ifc_models
create_table :ifc_model_metadata do |t|
  t.references :ifc_model, foreign_key: true, index: true
  t.string :ifc_version # "IFC2x3", "IFC4", "IFC4x3"
  t.integer :entity_count
  t.integer :geometry_count
  t.jsonb :spatial_structure # Building → Storey → Space tree
  t.jsonb :property_sets # All extracted Psets
  t.jsonb :quantities # Areas, volumes, etc.
  t.jsonb :classifications # Uniclass, OmniClass
  t.jsonb :materials
  t.string :file_checksum # SHA256 for deduplication
  t.timestamps
end

add_column :ifc_models, :conversion_stage, :string # Current stage name
add_column :ifc_models, :conversion_progress, :integer, default: 0 # 0-100
add_column :ifc_models, :conversion_logs, :jsonb, default: {} # Per-stage logs
```

### Layer 5: API Enhancements

```ruby
# Enhanced API Response
module API::Bim::V1
  class IFCModelRepresenter < Roar::Decorator
    property :id
    property :title
    property :conversion_status
    property :conversion_stage
    property :conversion_progress
    property :metadata, getter: ->(*) {
      ifc_model_metadata&.as_json(only: [
        :ifc_version, :entity_count, :spatial_structure
      ])
    }

    link :conversion_logs do
      api_v1_ifc_model_logs_path(represented.id)
    end
  end
end
```

### Layer 6: Frontend Progress UI

```typescript
// New Component: ifc-upload-progress.component.ts
@Component({
  selector: 'op-ifc-upload-progress',
  template: `
    <div class="ifc-upload-progress">
      <div class="stage-indicator" *ngFor="let stage of stages">
        <span [class.active]="stage === currentStage"
              [class.complete]="isStageComplete(stage)">
          {{ stage | i18n }}
        </span>
      </div>
      <progress [value]="progress" max="100"></progress>
      <span>{{ progress }}%</span>

      <div *ngIf="validationWarnings.length" class="warnings">
        <h4>Validation Warnings:</h4>
        <ul>
          <li *ngFor="let warning of validationWarnings">{{ warning }}</li>
        </ul>
      </div>
    </div>
  `
})
export class IFCUploadProgressComponent implements OnInit {
  stages = ['validation', 'ifc_to_dae', 'dae_to_gltf',
            'metadata_extraction', 'gltf_to_xkt', 'optimization'];
  currentStage = '';
  progress = 0;
  validationWarnings:string[] = [];

  ngOnInit() {
    // Subscribe to Turbo Streams or WebSocket for real-time updates
    this.turboStreamService.subscribe(`ifc_model_${this.modelId}`, (data) => {
      this.currentStage = data.stage;
      this.progress = data.progress;
    });
  }
}
```

---

## Technology Stack

### Backend Dependencies
- **Existing:**
  - IfcOpenShell (IfcConvert)
  - COLLADA2GLTF
  - xeokit-gltf-to-xkt
  - xeokit-metadata

- **New:**
  - `ifcopenshell-python` (>= 0.7.0) - Advanced IFC parsing/validation
  - `python-occ-core` - Optional for geometry analysis
  - Ruby gems:
    - `digest/sha2` - File checksums (already in stdlib)
    - No new gems required - use existing GoodJob, CarrierWave

### Frontend Dependencies
- **New:**
  - `@uppy/core`, `@uppy/xhr-upload` - Chunked uploads (optional)
  - Use existing Turbo Streams for progress updates

---

## API Contracts

### POST /api/bim/v1/projects/:project_id/ifc_models
**Enhanced Request:**
```json
{
  "title": "Building A - Rev 3",
  "attachment": {
    "file": "<multipart>",
    "checksum": "sha256-ABC123..." // Client-computed for deduplication
  },
  "options": {
    "validate_schema": true,
    "extract_metadata": true,
    "generate_lod": ["high", "medium", "low"],
    "priority": "normal" // "high", "normal", "low"
  }
}
```

**Enhanced Response:**
```json
{
  "id": 123,
  "title": "Building A - Rev 3",
  "conversion_status": "processing",
  "conversion_stage": "metadata_extraction",
  "conversion_progress": 65,
  "metadata": {
    "ifc_version": "IFC4",
    "entity_count": 45000,
    "geometry_count": 12000,
    "estimated_completion": "2025-11-07T14:30:00Z",
    "validation_warnings": [
      "Large geometry detected in element #12345 - may impact performance"
    ]
  },
  "_links": {
    "self": "/api/bim/v1/ifc_models/123",
    "logs": "/api/bim/v1/ifc_models/123/logs",
    "progress_stream": "wss://example.com/cable?channel=IFCModelChannel&id=123"
  }
}
```

### GET /api/bim/v1/ifc_models/:id/logs
**Response:**
```json
{
  "logs": [
    {
      "stage": "validation",
      "timestamp": "2025-11-07T14:00:00Z",
      "level": "info",
      "message": "IFC version detected: IFC4",
      "details": { "schema": "IFC4_ADD2" }
    },
    {
      "stage": "ifc_to_dae",
      "timestamp": "2025-11-07T14:05:00Z",
      "level": "warning",
      "message": "Simplified 3 complex geometries",
      "details": { "elements": ["#12345", "#12346", "#12347"] }
    }
  ]
}
```

---

## Database Schema (DDL)

```sql
-- New table for enhanced metadata
CREATE TABLE ifc_model_metadata (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  ifc_version VARCHAR(20), -- 'IFC2x3', 'IFC4', 'IFC4x3'
  entity_count INTEGER,
  geometry_count INTEGER,
  spatial_structure JSONB, -- Hierarchical building structure
  property_sets JSONB, -- All Psets
  quantities JSONB, -- QTO (Quantity Take-Off)
  classifications JSONB, -- Uniclass, OmniClass, etc.
  materials JSONB,
  file_checksum VARCHAR(64), -- SHA256
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_ifc_model_metadata UNIQUE (ifc_model_id)
);

CREATE INDEX idx_ifc_metadata_checksum ON ifc_model_metadata(file_checksum);
CREATE INDEX idx_ifc_metadata_version ON ifc_model_metadata(ifc_version);

-- Add columns to existing ifc_models table
ALTER TABLE ifc_models
  ADD COLUMN conversion_stage VARCHAR(50),
  ADD COLUMN conversion_progress INTEGER DEFAULT 0 CHECK (conversion_progress >= 0 AND conversion_progress <= 100),
  ADD COLUMN conversion_logs JSONB DEFAULT '[]'::jsonb;

CREATE INDEX idx_ifc_models_conversion_status ON ifc_models(conversion_status, conversion_stage);
```

---

## Testing Strategy

### Unit Tests
```ruby
# spec/services/bim/ifc_models/validator_service_spec.rb
RSpec.describe Bim::IFCModels::ValidatorService do
  describe '#call' do
    context 'with valid IFC4 file' do
      it 'returns valid result with metadata' do
        result = described_class.new(valid_ifc4_path).call
        expect(result[:valid]).to be true
        expect(result[:ifc_version]).to eq 'IFC4'
      end
    end

    context 'with corrupted file' do
      it 'returns validation errors' do
        result = described_class.new(corrupted_ifc_path).call
        expect(result[:valid]).to be false
        expect(result[:schema_errors]).not_to be_empty
      end
    end
  end
end

# spec/services/bim/ifc_models/metadata_extractor_service_spec.rb
RSpec.describe Bim::IFCModels::MetadataExtractorService do
  it 'extracts spatial structure' do
    metadata = described_class.new(ifc_path).call
    expect(metadata[:spatial_structure]).to have_key('IfcBuilding')
  end
end
```

### Integration Tests
```ruby
# spec/features/ifc_models/enhanced_upload_spec.rb
RSpec.describe 'Enhanced IFC Upload', :js do
  it 'shows real-time progress during conversion' do
    visit bim_project_ifc_models_path(project)
    attach_file 'IFC File', test_ifc_path
    click_button 'Upload'

    expect(page).to have_content('Validation')
    expect(page).to have_selector('.stage-indicator.active', text: 'validation')

    # Wait for progress updates
    expect(page).to have_content('65%', wait: 30)
    expect(page).to have_selector('.stage-indicator.active', text: 'metadata_extraction')
  end

  it 'displays validation warnings before conversion' do
    visit bim_project_ifc_models_path(project)
    attach_file 'IFC File', large_geometry_ifc_path
    click_button 'Upload'

    expect(page).to have_content('Validation Warnings')
    expect(page).to have_content('Large geometry detected')
  end
end
```

### API Tests
```ruby
# spec/requests/api/bim/v1/ifc_models_spec.rb
RSpec.describe 'API Bim V1 IFC Models' do
  describe 'POST /api/bim/v1/projects/:id/ifc_models' do
    it 'accepts enhanced upload parameters' do
      post api_v1_project_ifc_models_path(project), params: {
        title: 'Test Model',
        attachment: fixture_file_upload('test.ifc'),
        options: {
          validate_schema: true,
          extract_metadata: true,
          priority: 'high'
        }
      }

      expect(response).to have_http_status(:created)
      expect(json_body[:conversion_stage]).to eq 'validation'
      expect(json_body[:conversion_progress]).to be >= 0
    end
  end

  describe 'GET /api/bim/v1/ifc_models/:id/logs' do
    it 'returns conversion logs' do
      ifc_model = create(:ifc_model, :with_logs)
      get api_v1_ifc_model_logs_path(ifc_model)

      expect(response).to have_http_status(:ok)
      expect(json_body[:logs]).to be_an(Array)
      expect(json_body[:logs].first).to have_key(:stage)
    end
  end
end
```

---

## Demo Deliverables

### Minimal Viable Demo
1. **Upload Interface**: Enhanced upload form with validation preview
2. **Progress Dashboard**: Real-time stage-by-stage progress indicator
3. **Metadata Viewer**: Display extracted IFC metadata in structured format
4. **Logs Viewer**: Conversion logs with filtering by stage/level

### Demo Scenario
```
User uploads "Building_A_Rev3.ifc" (500MB, IFC4)
    ↓
System validates schema (5 seconds)
  → Shows: "IFC4 detected, 45,000 entities, estimated time: 2 minutes"
  → Warnings: "3 large geometries detected"
    ↓
User proceeds
    ↓
Progress bar shows stages:
  [✓] Validation → [▶] IFC→DAE (45%) → [ ] DAE→glTF → [ ] Metadata → [ ] glTF→XKT → [ ] Optimization
    ↓
After completion:
  → Metadata tab shows spatial structure tree
  → Logs tab shows all conversion steps
  → Model loads in 3D viewer
```

---

## Dependencies & Risks

### Upstream Dependencies
- None (foundational slice)

### Downstream Dependencies
- **Slice 2 (3D Viewer)**: Needs optimized XKT files and metadata
- **Slice 4 (Clash Detection)**: Needs extracted geometry data
- **Slice 5 (Federated Models)**: Needs spatial structure metadata
- **Slice 6 (Model Comparison)**: Needs file checksums and versioning

### Technical Risks
1. **IfcOpenShell Python Integration**: May require subprocess calls from Ruby
   - **Mitigation**: Create thin Ruby wrapper around Python scripts

2. **Large File Handling**: Memory consumption during parsing
   - **Mitigation**: Stream-based parsing, temporary file cleanup

3. **Conversion Timeouts**: Very complex models may exceed job timeouts
   - **Mitigation**: Adjustable timeouts, model simplification options

4. **Storage Costs**: Storing multiple metadata/LOD versions
   - **Mitigation**: Configurable retention policies, compression

### Licensing Risks
- IfcOpenShell: LGPL 3.0 (compatible with GPL 3.0)
- python-occ-core: LGPL 3.0 (compatible)
- All proposed dependencies are GPL-compatible

---

## Success Criteria

### Functional Requirements
- ✅ IFC schema validation before conversion starts
- ✅ Real-time progress reporting (6 stages)
- ✅ Enhanced metadata extraction (spatial structure, Psets, quantities)
- ✅ Detailed conversion logs per stage
- ✅ File deduplication via checksums
- ✅ Conversion priority queue

### Non-Functional Requirements
- ✅ <5 second validation time for files <100MB
- ✅ <2 minute total conversion for typical models (50k entities)
- ✅ 99% conversion success rate for valid IFC files
- ✅ <10% storage increase for metadata vs original file size

### Quality Gates
- ✅ >90% unit test coverage for new services
- ✅ E2E test for complete upload → conversion → metadata display
- ✅ API contract tests for all new endpoints
- ✅ Documentation: API specs, admin guide for conversion tuning

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- Database migrations (metadata table, new columns)
- ValidatorService skeleton
- MetadataExtractorService skeleton
- Basic progress tracking in ViewConverterService

### Phase 2: Validation & Metadata (Week 2)
- Implement IFC version detection
- Schema validation (IfcOpenShell integration)
- Spatial structure extraction
- Property set extraction

### Phase 3: Progress & Logging (Week 3)
- Real-time progress updates (Turbo Streams)
- Per-stage logging infrastructure
- Frontend progress component
- API endpoints for logs

### Phase 4: Optimization & Polish (Week 4)
- File deduplication
- Priority queue
- Error recovery & retry logic
- Performance tuning
- Demo preparation

---

## Next Actions

1. **Switch to Action Mode** after validating:
   - No blocking dependencies ✅
   - Clear technical approach ✅
   - Testable acceptance criteria ✅

2. **Action Mode Tasks:**
   - Generate database migrations
   - Implement ValidatorService (TDD)
   - Implement MetadataExtractorService (TDD)
   - Enhance ViewConverterService
   - Build progress UI component
   - Create demo scenario

3. **Validation Checkpoint:**
   - Demo upload flow with progress tracking
   - Show extracted metadata in UI
   - Export results.json with metrics

---

**Deliberation Complete** ✅
**Ready for Action Mode** ✅
**Estimated LOC:** ~1,200 (Backend: 800, Frontend: 400)
**Estimated Duration:** 4 weeks
**Risk Level:** Low (foundational, well-scoped)
