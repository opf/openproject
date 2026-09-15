# Slice 5: Federated Models - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 5
**Dependencies:**
- Slice 1 (IFC Upload) - requires spatial structure metadata
- Slice 2 (3D Viewer) - requires multi-model loading

---

## Current State Analysis

### Existing Capabilities (Community Edition)
✅ **Multiple models can be loaded** in xeokit viewer
✅ **Basic coordination** via model tree

### Limitations
- No formal federation management
- No spatial coordination/alignment
- No unified coordinate system
- No federated properties/queries

---

## Enterprise Enhancement Goals

### 1. Federation Management
- **Federation Definition**: Group multiple IFC models into coordinated set
- **Spatial Alignment**: Define origin points and transformations
- **Discipline Organization**: Architectural, Structural, MEP groups
- **Version Control**: Track model versions within federation

### 2. Coordinate System Management
- **Project Base Point**: Define global origin
- **Model Alignment**: Transform models to shared coordinate system
- **Survey Points**: Real-world coordinates (lat/long)
- **Grid Systems**: Shared grids across models

### 3. Unified Visualization
- **Load All Models**: Single viewer showing all federated models
- **Discipline Filters**: Show/hide by discipline
- **Visual Distinction**: Color-code models by discipline
- **Transparency Controls**: Transparency per model/discipline

### 4. Federated Queries
- **Cross-Model Search**: Find elements across all models
- **Spatial Queries**: Elements within zone (from any model)
- **Property Aggregation**: Combine properties from all models

---

## Proposed Architecture

### Layer 1: Federation Data Model

```ruby
# New: modules/bim/app/models/bim/model_federation.rb
class Bim::ModelFederation < ApplicationRecord
  belongs_to :project
  has_many :federation_models, class_name: 'Bim::FederationModel', dependent: :destroy
  has_many :ifc_models, through: :federation_models

  validates :name, presence: true

  # Coordinate system configuration
  # base_point: { x: 0, y: 0, z: 0 } - Project origin
  # rotation: { x: 0, y: 0, z: 0 } - Rotation angles
  # units: 'meters' | 'feet'

  def load_all_models
    ifc_models.where(conversion_status: :completed)
  end

  def models_by_discipline
    federation_models.group_by(&:discipline)
  end

  def spatial_extent
    # Calculate overall bounding box of all models
    all_extents = federation_models.map(&:transformed_extent)
    combine_extents(all_extents)
  end

  private

  def combine_extents(extents)
    {
      min: [
        extents.map { |e| e[:min][0] }.min,
        extents.map { |e| e[:min][1] }.min,
        extents.map { |e| e[:min][2] }.min
      ],
      max: [
        extents.map { |e| e[:max][0] }.max,
        extents.map { |e| e[:max][1] }.max,
        extents.map { |e| e[:max][2] }.max
      ]
    }
  end
end

# New: modules/bim/app/models/bim/federation_model.rb
class Bim::FederationModel < ApplicationRecord
  belongs_to :model_federation
  belongs_to :ifc_model

  enum discipline: {
    architectural: 0,
    structural: 1,
    mechanical: 2,
    electrical: 3,
    plumbing: 4,
    civil: 5,
    landscape: 6,
    other: 99
  }

  # Transformation matrix for alignment
  # transform: { translation: [x, y, z], rotation: [rx, ry, rz], scale: [sx, sy, sz] }

  validates :ifc_model_id, uniqueness: { scope: :model_federation_id }

  def transformed_extent
    extent = ifc_model.ifc_model_metadata&.spatial_structure&.dig('extent') || default_extent
    apply_transformation(extent, transform)
  end

  private

  def default_extent
    { min: [0, 0, 0], max: [10, 10, 10] }
  end

  def apply_transformation(extent, transform)
    # Apply translation, rotation, scale to bounding box
    # Returns transformed min/max coordinates
  end
end
```

### Layer 2: Federation Services

```ruby
# New: modules/bim/app/services/bim/federations/create_service.rb
class Bim::Federations::CreateService < BaseServices::Create
  def call
    federation = Bim::ModelFederation.new(permitted_params)

    if federation.save
      add_models_to_federation(federation)
      calculate_optimal_alignment(federation) if params[:auto_align]
      ServiceResult.success(result: federation)
    else
      ServiceResult.failure(errors: federation.errors)
    end
  end

  private

  def add_models_to_federation(federation)
    params[:model_ids].each do |model_id|
      ifc_model = IFCModel.find(model_id)
      discipline = detect_discipline(ifc_model)

      federation.federation_models.create!(
        ifc_model: ifc_model,
        discipline: discipline,
        transform: default_transform
      )
    end
  end

  def detect_discipline(ifc_model)
    # Heuristic based on model title or content
    title = ifc_model.title.downcase

    return :architectural if title.include?('arch')
    return :structural if title.include?('struct')
    return :mechanical if title.include?('mech') || title.include?('hvac')
    return :electrical if title.include?('elec')
    return :plumbing if title.include?('plumb')

    :other
  end

  def calculate_optimal_alignment(federation)
    # Use shared grids or survey points to align models
    Bim::Federations::AlignmentService.new(federation).call
  end

  def default_transform
    {
      translation: [0, 0, 0],
      rotation: [0, 0, 0],
      scale: [1, 1, 1]
    }
  end
end

# New: modules/bim/app/services/bim/federations/alignment_service.rb
class Bim::Federations::AlignmentService
  def initialize(federation)
    @federation = federation
  end

  def call
    # Find common reference points (grids, survey points)
    reference_points = find_reference_points

    # Calculate transformations to align all models
    calculate_transformations(reference_points)

    # Apply transformations to federation models
    apply_transformations
  end

  private

  def find_reference_points
    # Extract IfcGrid or IfcSite from each model
    @federation.federation_models.map do |fm|
      {
        federation_model: fm,
        grids: extract_grids(fm.ifc_model),
        site: extract_site(fm.ifc_model)
      }
    end
  end

  def extract_grids(ifc_model)
    # Parse IFC metadata for IfcGrid elements
    metadata = ifc_model.ifc_model_metadata&.element_index
    metadata&.select { |_, v| v['type'] == 'IfcGrid' }
  end

  def extract_site(ifc_model)
    # Extract IfcSite with RefLatitude/RefLongitude
    metadata = ifc_model.ifc_model_metadata&.spatial_structure
    metadata&.dig('IfcSite')
  end

  def calculate_transformations(reference_points)
    # Find matching grids/coordinates
    # Calculate translation/rotation to align
    # Store in @transformations hash
  end

  def apply_transformations
    @transformations.each do |fm_id, transform|
      federation_model = @federation.federation_models.find(fm_id)
      federation_model.update!(transform: transform)
    end
  end
end
```

### Layer 3: Database Schema

```sql
-- Model federations
CREATE TABLE bim_model_federations (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  base_point JSONB DEFAULT '{"x": 0, "y": 0, "z": 0}'::jsonb,
  rotation JSONB DEFAULT '{"x": 0, "y": 0, "z": 0}'::jsonb,
  units VARCHAR(20) DEFAULT 'meters',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_federations_project ON bim_model_federations(project_id);

-- Models within federation
CREATE TABLE bim_federation_models (
  id BIGSERIAL PRIMARY KEY,
  model_federation_id BIGINT NOT NULL REFERENCES bim_model_federations(id) ON DELETE CASCADE,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  discipline INTEGER DEFAULT 99, -- 0=arch, 1=struct, 2=mech, etc.
  transform JSONB DEFAULT '{"translation": [0,0,0], "rotation": [0,0,0], "scale": [1,1,1]}'::jsonb,
  display_order INTEGER DEFAULT 0,
  visible BOOLEAN DEFAULT true,
  color VARCHAR(7), -- Hex color for discipline
  opacity DECIMAL(3, 2) DEFAULT 1.0, -- 0.0 to 1.0
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_federation_model UNIQUE (model_federation_id, ifc_model_id)
);

CREATE INDEX idx_federation_models_federation ON bim_federation_models(model_federation_id);
CREATE INDEX idx_federation_models_discipline ON bim_federation_models(discipline);
```

### Layer 4: API & Frontend

```ruby
# API Endpoints
POST   /api/bim/v1/projects/:id/federations
GET    /api/bim/v1/projects/:id/federations
GET    /api/bim/v1/federations/:id
PUT    /api/bim/v1/federations/:id
DELETE /api/bim/v1/federations/:id
POST   /api/bim/v1/federations/:id/align # Auto-alignment
GET    /api/bim/v1/federations/:id/viewer_config # Config for multi-model viewer
```

```typescript
// federated-viewer.component.ts
@Component({
  selector: 'op-federated-viewer',
  template: `
    <div class="federated-viewer">
      <div class="discipline-controls">
        <h3>Disciplines</h3>
        <div *ngFor="let disc of disciplines" class="discipline-toggle">
          <input type="checkbox"
                 [(ngModel)]="disc.visible"
                 (change)="toggleDiscipline(disc)">
          <span [style.color]="disc.color">{{ disc.name }}</span>
          <input type="range" min="0" max="100"
                 [(ngModel)]="disc.opacity"
                 (change)="updateOpacity(disc)">
        </div>
      </div>

      <op-ifc-viewer
        [federationId]="federationId"
        [models]="visibleModels"
        (loaded)="onModelsLoaded()">
      </op-ifc-viewer>
    </div>
  `
})
export class FederatedViewerComponent {
  @Input() federationId: number;
  disciplines: DisciplineConfig[] = [];
  visibleModels: any[] = [];

  ngOnInit() {
    this.loadFederation();
  }

  loadFederation() {
    this.federationService.get(this.federationId).subscribe(federation => {
      this.disciplines = this.groupByDiscipline(federation.federation_models);
      this.updateVisibleModels();
    });
  }

  toggleDiscipline(disc: DisciplineConfig) {
    disc.visible = !disc.visible;
    this.updateVisibleModels();
  }

  updateVisibleModels() {
    this.visibleModels = this.disciplines
      .filter(d => d.visible)
      .flatMap(d => d.models);
  }
}
```

---

## Demo Deliverables

**MVP Demo:**
1. Create federation "Building A - Full Coordination"
2. Add 3 models: Architectural, Structural, MEP
3. Auto-align using shared grids
4. Viewer loads all 3 models
5. Toggle disciplines on/off
6. Adjust transparency to see through Arch and view MEP

---

**Deliberation Complete** ✅
**Estimated LOC:** ~1,200 (Ruby: 800, TypeScript: 400)
**Estimated Duration:** 2 weeks
**Risk Level:** Medium
