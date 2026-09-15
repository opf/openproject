# Slice 4: Clash Detection - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 4
**Dependencies:**
- Slice 1 (IFC Upload) - requires geometry and metadata extraction
- Slice 2 (3D Viewer) - requires element visualization and highlighting
- Slice 3 (Linking) - for creating clash resolution work packages

---

## Current State Analysis

### Existing Capabilities (Community Edition)
❌ **No clash detection capabilities exist in Community Edition**

### Enterprise Enhancement Goals

Implement rule-based geometric clash detection using parsed IFC geometry data with spatial tolerance thresholds.

---

## Enterprise Feature Requirements

### 1. Geometric Clash Detection
- **Hard Clashes**: Elements physically intersecting (overlap > tolerance)
- **Soft Clashes**: Elements within clearance distance (safety zones)
- **4D Clashes**: Temporal conflicts (elements in same space at different construction phases)
- **Duplicate Detection**: Identical elements at same location

### 2. Clash Rules Engine
- **Predefined Rules**: Wall-Wall, Structural-MEP, etc.
- **Custom Rules**: User-defined clash tests
- **Discipline-Based**: Architectural vs MEP, Structural vs Architectural
- **Zone-Based**: Check specific building areas
- **Tolerance Configuration**: Per-rule tolerances (e.g., 10mm for hard, 50mm for soft)

### 3. Clash Reporting & Management
- **Clash Matrix**: Grid showing clash counts between disciplines/models
- **Clash Browser**: Filterable list of detected clashes
- **Status Tracking**: New, Active, Approved, Resolved, Closed
- **Assignment**: Assign clashes to responsible parties
- **Grouping**: Group related clashes for batch resolution

### 4. Visualization
- **Highlight Clashing Elements**: Color-code in 3D viewer
- **Clash Markers**: Visual indicators at clash locations
- **Clash Distance**: Show clearance distance for soft clashes
- **Clash Viewpoints**: Auto-generate BCF viewpoints for each clash

### 5. Integration with Work Packages
- **Auto-Create Work Packages**: One work package per clash or per group
- **Link Elements**: Auto-link clashing elements to work package
- **Workflow**: Track resolution through work package status

---

## Proposed Architecture

### Layer 1: Geometry Processing

```ruby
# New: modules/bim/app/services/bim/geometry/extractor_service.rb
class Bim::Geometry::ExtractorService
  def initialize(ifc_model)
    @ifc_model = ifc_model
    @ifc_file_path = ifc_model.attachments.find_by(description: 'ifc').file.path
  end

  def call
    extract_bounding_boxes
    extract_detailed_geometry # For precise clash detection
  end

  private

  def extract_bounding_boxes
    # Use IfcOpenShell to get AABB for each element
    # Returns: { element_id => { min: [x,y,z], max: [x,y,z] } }
    run_python_script('extract_aabb.py', @ifc_file_path)
  end

  def extract_detailed_geometry
    # For elements likely to clash, extract mesh vertices
    # Uses IFC geometric representations
    run_python_script('extract_geometry.py', @ifc_file_path)
  end

  def run_python_script(script_name, *args)
    script_path = Rails.root.join('lib', 'bim', 'python', script_name)
    cmd = "python3 #{script_path} #{args.join(' ')}"
    JSON.parse(`#{cmd}`)
  end
end

# Python script: lib/bim/python/extract_aabb.py
"""
import ifcopenshell
import ifcopenshell.geom
import json
import sys

def extract_bounding_boxes(ifc_path):
    ifc_file = ifcopenshell.open(ifc_path)
    settings = ifcopenshell.geom.settings()
    settings.set(settings.USE_WORLD_COORDS, True)

    results = {}

    for element in ifc_file.by_type('IfcProduct'):
        if element.Representation:
            try:
                shape = ifcopenshell.geom.create_shape(settings, element)
                bbox = shape.geometry.bounding_box

                results[element.GlobalId] = {
                    'min': [bbox.min_x, bbox.min_y, bbox.min_z],
                    'max': [bbox.max_x, bbox.max_y, bbox.max_z],
                    'type': element.is_a(),
                    'name': getattr(element, 'Name', '')
                }
            except:
                pass  # Skip elements without geometry

    return results

if __name__ == '__main__':
    ifc_path = sys.argv[1]
    results = extract_bounding_boxes(ifc_path)
    print(json.dumps(results))
"""
```

### Layer 2: Clash Detection Engine

```ruby
# New: modules/bim/app/services/bim/clashes/detection_service.rb
class Bim::Clashes::DetectionService
  def initialize(ifc_models:, clash_test:)
    @ifc_models = Array(ifc_models)
    @clash_test = clash_test
  end

  def call
    # Step 1: Load geometry for all models
    geometries = load_geometries

    # Step 2: Build spatial index for fast queries
    spatial_index = build_spatial_index(geometries)

    # Step 3: Run clash detection
    clashes = detect_clashes(spatial_index, geometries)

    # Step 4: Save results
    save_clashes(clashes)

    ServiceResult.success(result: clashes)
  end

  private

  def load_geometries
    @ifc_models.each_with_object({}) do |model, hash|
      extractor = Bim::Geometry::ExtractorService.new(model)
      hash[model.id] = extractor.call
    end
  end

  def build_spatial_index(geometries)
    # Use R-Tree or similar spatial index
    index = RTree.new

    geometries.each do |model_id, elements|
      elements.each do |element_id, bbox|
        index.insert(
          bbox_to_rect(bbox),
          { model_id: model_id, element_id: element_id }
        )
      end
    end

    index
  end

  def detect_clashes(spatial_index, geometries)
    clashes = []

    geometries.each do |model_id, elements|
      elements.each do |element_id, bbox|
        # Skip self-clashes within same model if configured
        next if @clash_test.exclude_self_clashes? && single_model?

        # Find potentially clashing elements using spatial index
        candidates = spatial_index.search(expand_bbox(bbox, @clash_test.tolerance))

        candidates.each do |candidate|
          # Skip self-comparison
          next if candidate[:model_id] == model_id && candidate[:element_id] == element_id

          # Check clash rules
          if clash_detected?(bbox, geometries[candidate[:model_id]][candidate[:element_id]])
            clashes << create_clash_record(
              model_id, element_id, bbox,
              candidate[:model_id], candidate[:element_id],
              geometries[candidate[:model_id]][candidate[:element_id]]
            )
          end
        end
      end
    end

    clashes
  end

  def clash_detected?(bbox1, bbox2)
    case @clash_test.clash_type
    when 'hard'
      bboxes_intersect?(bbox1, bbox2, @clash_test.tolerance)
    when 'soft'
      bboxes_within_clearance?(bbox1, bbox2, @clash_test.clearance_distance)
    when 'duplicate'
      bboxes_identical?(bbox1, bbox2, @clash_test.tolerance)
    end
  end

  def bboxes_intersect?(bbox1, bbox2, tolerance)
    # Check if AABBs overlap (with tolerance)
    bbox1['max'][0] + tolerance >= bbox2['min'][0] &&
      bbox1['min'][0] - tolerance <= bbox2['max'][0] &&
      bbox1['max'][1] + tolerance >= bbox2['min'][1] &&
      bbox1['min'][1] - tolerance <= bbox2['max'][1] &&
      bbox1['max'][2] + tolerance >= bbox2['min'][2] &&
      bbox1['min'][2] - tolerance <= bbox2['max'][2]
  end

  def bboxes_within_clearance?(bbox1, bbox2, clearance)
    # Calculate minimum distance between bboxes
    distance = calculate_bbox_distance(bbox1, bbox2)
    distance > 0 && distance < clearance
  end

  def bboxes_identical?(bbox1, bbox2, tolerance)
    # Check if centers and sizes are within tolerance
    center1 = bbox_center(bbox1)
    center2 = bbox_center(bbox2)

    distance(center1, center2) < tolerance
  end

  def save_clashes(clashes)
    clashes.map do |clash_data|
      Bim::Clash.create!(
        clash_test: @clash_test,
        element1_id: clash_data[:element1_id],
        element1_type: clash_data[:element1_type],
        element1_model_id: clash_data[:model1_id],
        element2_id: clash_data[:element2_id],
        element2_type: clash_data[:element2_type],
        element2_model_id: clash_data[:model2_id],
        clash_point: clash_data[:clash_point],
        distance: clash_data[:distance],
        status: :new
      )
    end
  end

  # Utility methods
  def bbox_to_rect(bbox)
    RTree::Rectangle.new(
      bbox['min'][0], bbox['min'][1], bbox['min'][2],
      bbox['max'][0], bbox['max'][1], bbox['max'][2]
    )
  end

  def expand_bbox(bbox, expansion)
    {
      'min' => bbox['min'].map { |v| v - expansion },
      'max' => bbox['max'].map { |v| v + expansion }
    }
  end

  def bbox_center(bbox)
    [
      (bbox['min'][0] + bbox['max'][0]) / 2.0,
      (bbox['min'][1] + bbox['max'][1]) / 2.0,
      (bbox['min'][2] + bbox['max'][2]) / 2.0
    ]
  end

  def distance(point1, point2)
    Math.sqrt(
      (point1[0] - point2[0])**2 +
      (point1[1] - point2[1])**2 +
      (point1[2] - point2[2])**2
    )
  end

  def create_clash_record(model1_id, elem1_id, bbox1, model2_id, elem2_id, bbox2)
    {
      model1_id: model1_id,
      element1_id: elem1_id,
      element1_type: bbox1['type'],
      model2_id: model2_id,
      element2_id: elem2_id,
      element2_type: bbox2['type'],
      clash_point: calculate_clash_point(bbox1, bbox2),
      distance: calculate_bbox_distance(bbox1, bbox2)
    }
  end

  def calculate_clash_point(bbox1, bbox2)
    # Midpoint between bbox centers
    center1 = bbox_center(bbox1)
    center2 = bbox_center(bbox2)

    [
      (center1[0] + center2[0]) / 2.0,
      (center1[1] + center2[1]) / 2.0,
      (center1[2] + center2[2]) / 2.0
    ]
  end

  def calculate_bbox_distance(bbox1, bbox2)
    # Minimum distance between bboxes (0 if intersecting)
    dx = [bbox1['min'][0] - bbox2['max'][0], 0, bbox2['min'][0] - bbox1['max'][0]].max
    dy = [bbox1['min'][1] - bbox2['max'][1], 0, bbox2['min'][1] - bbox1['max'][1]].max
    dz = [bbox1['min'][2] - bbox2['max'][2], 0, bbox2['min'][2] - bbox1['max'][2]].max

    Math.sqrt(dx**2 + dy**2 + dz**2)
  end
end
```

### Layer 3: Data Models

```ruby
# New: modules/bim/app/models/bim/clash_test.rb
class Bim::ClashTest < ApplicationRecord
  belongs_to :project
  has_many :clash_test_models, dependent: :destroy
  has_many :ifc_models, through: :clash_test_models
  has_many :clashes, dependent: :destroy

  enum clash_type: { hard: 0, soft: 1, duplicate: 2 }
  enum status: { pending: 0, running: 1, completed: 2, failed: 3 }

  validates :name, presence: true
  validates :tolerance, numericality: { greater_than_or_equal_to: 0 }

  def run!
    update!(status: :running, last_run_at: Time.current)

    result = Bim::Clashes::DetectionService.new(
      ifc_models: ifc_models,
      clash_test: self
    ).call

    if result.success?
      update!(
        status: :completed,
        clash_count: clashes.count,
        completed_at: Time.current
      )
    else
      update!(status: :failed, error_message: result.errors.full_messages.join(', '))
    end
  end

  def clash_matrix
    # Returns matrix of clash counts grouped by model/discipline
    clashes.group(:element1_model_id, :element2_model_id).count
  end
end

# New: modules/bim/app/models/bim/clash.rb
class Bim::Clash < ApplicationRecord
  belongs_to :clash_test
  belongs_to :element1_model, class_name: 'Bim::IFCModels::IFCModel', foreign_key: 'element1_model_id'
  belongs_to :element2_model, class_name: 'Bim::IFCModels::IFCModel', foreign_key: 'element2_model_id'
  belongs_to :work_package, optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true

  enum status: {
    new: 0,
    active: 1,
    approved: 2, # Clash is acceptable
    resolved: 3,
    closed: 4
  }

  validates :element1_id, :element2_id, presence: true

  scope :unresolved, -> { where(status: [:new, :active]) }
  scope :by_status, ->(status) { where(status: status) }

  def create_work_package!(user:, type:)
    wp = WorkPackages::CreateService.new(user: user).call(
      project: clash_test.project,
      type: type,
      subject: "Clash: #{element1_type} / #{element2_type}",
      description: generate_description,
      assigned_to: assigned_to
    ).result

    # Link both elements to work package
    wp.link_element(
      ifc_model: element1_model,
      element_id: element1_id,
      relationship_type: :affected_by,
      properties: { type: element1_type }
    )

    wp.link_element(
      ifc_model: element2_model,
      element_id: element2_id,
      relationship_type: :affected_by,
      properties: { type: element2_type }
    )

    # Create BCF viewpoint at clash location
    create_bcf_viewpoint!(wp)

    update!(work_package: wp, status: :active)
    wp
  end

  def generate_description
    <<~DESC
      **Clash Details:**
      - Type: #{clash_test.clash_type.humanize}
      - Distance: #{distance.round(3)} meters
      - Location: X=#{clash_point[0].round(2)}, Y=#{clash_point[1].round(2)}, Z=#{clash_point[2].round(2)}

      **Element 1:**
      - Type: #{element1_type}
      - ID: #{element1_id}
      - Model: #{element1_model.title}

      **Element 2:**
      - Type: #{element2_type}
      - ID: #{element2_id}
      - Model: #{element2_model.title}

      Please review and resolve this clash.
    DESC
  end

  def create_bcf_viewpoint!(work_package)
    # Auto-generate viewpoint focused on clash location
    bcf_issue = work_package.bcf_issue || work_package.create_bcf_issue!(uuid: SecureRandom.uuid)

    bcf_issue.viewpoints.create!(
      uuid: SecureRandom.uuid,
      viewpoint_name: 'Clash View',
      json_viewpoint: {
        camera: {
          camera_view_point: clash_point,
          camera_direction: [0, 0, -1],
          camera_up_vector: [0, 1, 0]
        },
        components: {
          selection: [element1_id, element2_id],
          coloring: [
            { color: '#FF0000', component: [element1_id] },
            { color: '#0000FF', component: [element2_id] }
          ]
        }
      }
    )
  end
end
```

### Layer 4: Database Schema

```sql
-- Clash tests configuration
CREATE TABLE bim_clash_tests (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  clash_type INTEGER DEFAULT 0, -- 0=hard, 1=soft, 2=duplicate
  tolerance DECIMAL(10, 4) DEFAULT 0.01, -- meters
  clearance_distance DECIMAL(10, 4), -- for soft clashes
  exclude_self_clashes BOOLEAN DEFAULT true,
  status INTEGER DEFAULT 0, -- 0=pending, 1=running, 2=completed, 3=failed
  clash_count INTEGER DEFAULT 0,
  last_run_at TIMESTAMP,
  completed_at TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_clash_tests_project ON bim_clash_tests(project_id);
CREATE INDEX idx_clash_tests_status ON bim_clash_tests(status);

-- Models included in clash test
CREATE TABLE bim_clash_test_models (
  id BIGSERIAL PRIMARY KEY,
  clash_test_id BIGINT NOT NULL REFERENCES bim_clash_tests(id) ON DELETE CASCADE,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  group_name VARCHAR(100), -- e.g., 'Architectural', 'MEP', 'Structural'
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_clash_test_model UNIQUE (clash_test_id, ifc_model_id)
);

CREATE INDEX idx_clash_test_models_test ON bim_clash_test_models(clash_test_id);

-- Detected clashes
CREATE TABLE bim_clashes (
  id BIGSERIAL PRIMARY KEY,
  clash_test_id BIGINT NOT NULL REFERENCES bim_clash_tests(id) ON DELETE CASCADE,
  element1_id VARCHAR(255) NOT NULL, -- IFC GUID
  element1_type VARCHAR(100),
  element1_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  element2_id VARCHAR(255) NOT NULL,
  element2_type VARCHAR(100),
  element2_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  clash_point JSONB, -- [x, y, z]
  distance DECIMAL(10, 4), -- 0 for hard clashes, > 0 for soft
  status INTEGER DEFAULT 0, -- 0=new, 1=active, 2=approved, 3=resolved, 4=closed
  work_package_id BIGINT REFERENCES work_packages(id) ON DELETE SET NULL,
  assigned_to_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  resolution_notes TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_clashes_test ON bim_clashes(clash_test_id);
CREATE INDEX idx_clashes_status ON bim_clashes(status);
CREATE INDEX idx_clashes_element1 ON bim_clashes(element1_id, element1_model_id);
CREATE INDEX idx_clashes_element2 ON bim_clashes(element2_id, element2_model_id);
CREATE INDEX idx_clashes_work_package ON bim_clashes(work_package_id);

-- Add geometry data to ifc_model_metadata
ALTER TABLE ifc_model_metadata
  ADD COLUMN geometry_index JSONB DEFAULT '{}'::jsonb; -- Bounding boxes for all elements

CREATE INDEX idx_ifc_metadata_geometry ON ifc_model_metadata USING gin(geometry_index);
```

### Layer 5: Background Job

```ruby
# New: modules/bim/app/workers/bim/clash_detection_job.rb
class Bim::ClashDetectionJob < ApplicationJob
  queue_as :clash_detection

  def perform(clash_test_id)
    clash_test = Bim::ClashTest.find(clash_test_id)
    clash_test.run!
  rescue => e
    clash_test.update!(status: :failed, error_message: e.message)
    raise
  end
end
```

### Layer 6: API & Frontend

```ruby
# API endpoints
POST   /api/bim/v1/projects/:id/clash_tests
GET    /api/bim/v1/projects/:id/clash_tests
GET    /api/bim/v1/clash_tests/:id
PUT    /api/bim/v1/clash_tests/:id
DELETE /api/bim/v1/clash_tests/:id
POST   /api/bim/v1/clash_tests/:id/run # Start detection
GET    /api/bim/v1/clash_tests/:id/clashes
GET    /api/bim/v1/clash_tests/:id/matrix # Clash matrix
PUT    /api/bim/v1/clashes/:id # Update status
POST   /api/bim/v1/clashes/:id/create_work_package
```

```typescript
// clash-detection-panel.component.ts
@Component({
  selector: 'op-clash-detection-panel',
  template: `
    <div class="clash-detection">
      <h2>Clash Detection</h2>

      <button (click)="createClashTest()">New Clash Test</button>

      <table class="clash-tests">
        <thead>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Models</th>
            <th>Clashes</th>
            <th>Status</th>
            <th>Last Run</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let test of clashTests">
            <td>{{ test.name }}</td>
            <td>{{ test.clash_type }}</td>
            <td>{{ test.ifc_models.length }}</td>
            <td>{{ test.clash_count }}</td>
            <td><span class="status-badge" [class]="test.status">{{ test.status }}</span></td>
            <td>{{ test.last_run_at | date }}</td>
            <td>
              <button (click)="runTest(test)">Run</button>
              <button (click)="viewClashes(test)">View Clashes</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  `
})
export class ClashDetectionPanelComponent {}
```

---

## Technology Stack

### Backend
- **ifcopenshell-python** (≥ 0.7.0) - Geometry extraction
- **rtree** gem - Spatial indexing (optional, can use simple nested loops for MVP)
- Python 3.8+ runtime

### Frontend
- Use existing xeokit viewer for visualization
- No new dependencies

---

## Demo Deliverables

**MVP Demo:**
1. Create clash test between 2 models
2. Run detection (shows 15 clashes)
3. View clash matrix
4. Click clash → viewer highlights elements
5. Create work package from clash
6. Resolve clash → mark as resolved

---

**Deliberation Complete** ✅
**Estimated LOC:** ~1,800 (Ruby: 1,200, Python: 400, TypeScript: 200)
**Estimated Duration:** 3 weeks
**Risk Level:** Medium-High (geometric algorithms)
