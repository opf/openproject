# Slice 3: Work Package ↔ BIM Element Linking - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 3
**Dependencies:**
- Slice 1 (IFC Upload) - requires metadata extraction
- Slice 2 (3D Viewer) - requires element selection

---

## Current State Analysis

### Existing Capabilities (Community Edition)
- **BCF Issues**: Work packages linked to BCF issues via `bcf_issues` table
- **Viewpoint Association**: BCF viewpoints store selected elements in JSONB
- **Basic Linking**: One-to-one relationship (WorkPackage ↔ BCFIssue)
- **Element Selection**: Viewer can select elements and save to viewpoints
- **API Support**: BCF 2.1 API for external tools (Revit, etc.)

### Current Architecture
```
WorkPackage (has_one bcf_issue)
    ↓
BCFIssue
    ├─→ uuid (unique identifier)
    ├─→ markup (BCF XML)
    ├─→ stage, labels, index
    └─→ BCFViewpoint (has_many)
        ├─→ json_viewpoint (camera, components, clipping)
        └─→ components.selection (array of IFC element IDs)
```

**Key Files:**
- `/modules/bim/app/models/bim/bcf/issue.rb`
- `/modules/bim/app/models/bim/bcf/viewpoint.rb`
- `/modules/bim/app/services/bim/bcf/issues/create_service.rb`
- `/modules/bim/lib/open_project/bim/patches/work_package_patch.rb`

### Limitations to Address
1. **One-to-One Limitation**: Work package can only be linked to one BCF issue
2. **No Direct Element Linking**: Can only link via BCF viewpoints
3. **No Workflow Support**: No approval processes for BIM-related work packages
4. **Limited Metadata**: Element links don't store element properties
5. **No Bulk Linking**: Can't link multiple work packages to many elements
6. **No Relationship Types**: Can't specify why elements are linked (affected by, responsible for, etc.)
7. **No Element-Driven Workflows**: Can't trigger actions when elements change
8. **No Backlinks**: Elements don't show which work packages reference them

---

## Enterprise Enhancement Goals

### 1. Rich Element-to-Work Package Linking
- **Many-to-Many Relationships**: One work package can reference many elements, one element can be in many work packages
- **Relationship Types**:
  - `affected_by` - Element is affected by this issue
  - `responsible_for` - Work package tracks work on this element
  - `depends_on` - Work package depends on this element
  - `observes` - Monitoring element status
- **Element Properties Snapshot**: Store element metadata at link time
- **Link Status**: Active, completed, archived

### 2. Element-Aware Work Package Workflows
- **BIM-Specific Work Package Types**: E.g., "Clash Resolution", "RFI - BIM Element", "Design Change"
- **Approval Workflows**: Multi-stage approvals for changes affecting BIM elements
- **Status Propagation**: Work package status updates reflect in element visualization
- **Automated Assignment**: Auto-assign work packages based on element properties (e.g., discipline, zone)

### 3. Element Context in Work Packages
- **Element Property Display**: Show linked element properties in work package details
- **Visual Preview**: 3D thumbnail of linked elements
- **Geometry Tracking**: Track if linked element geometry has changed
- **Quantity Tracking**: Monitor quantities (area, volume) over time

### 4. Bulk Operations
- **Bulk Linking**: Select multiple elements, create/link to work packages
- **Template-Based Creation**: Create work packages from element selection using templates
- **Batch Updates**: Update multiple work packages based on element filter

### 5. Element-Driven Queries & Reporting
- **Filter by Element Properties**: Find work packages by element type, discipline, floor, zone
- **Spatial Queries**: Find work packages in specific building areas
- **Element Status Board**: Kanban view grouped by element type or location

---

## Proposed Architecture

### Layer 1: Enhanced Data Model

```ruby
# New model: modules/bim/app/models/bim/element_link.rb
class Bim::ElementLink < ApplicationRecord
  belongs_to :work_package
  belongs_to :ifc_model

  # Relationship types
  enum relationship_type: {
    affected_by: 0,
    responsible_for: 1,
    depends_on: 2,
    observes: 3,
    related_to: 4
  }

  enum status: {
    active: 0,
    completed: 1,
    archived: 2
  }

  # Element identification
  # element_id: IFC element GUID (e.g., "2O2Fr$t4X7Zf8NOew3FNr2")
  # element_type: IfcWall, IfcDoor, etc.
  # element_name: Human-readable name

  # Snapshot of element properties at link time
  # element_properties: JSONB containing Psets, quantities, etc.

  validates :element_id, presence: true
  validates :relationship_type, presence: true

  scope :active, -> { where(status: :active) }
  scope :by_element_type, ->(type) { where(element_type: type) }
  scope :by_relationship, ->(rel) { where(relationship_type: rel) }

  def element_metadata
    ifc_model.ifc_model_metadata&.find_element(element_id)
  end

  def geometry_changed?
    current_metadata = element_metadata
    return false unless current_metadata && element_properties

    current_metadata.dig('geometry', 'hash') !=
      element_properties.dig('geometry', 'hash')
  end
end

# Enhanced: modules/bim/app/models/bim/bcf/issue.rb
class Bim::Bcf::Issue < ApplicationRecord
  belongs_to :work_package
  has_many :element_links, through: :work_package

  # ... existing code ...

  def linked_elements
    element_links.includes(:ifc_model).map do |link|
      {
        id: link.element_id,
        type: link.element_type,
        name: link.element_name,
        model: link.ifc_model.title,
        relationship: link.relationship_type
      }
    end
  end
end

# Patch: modules/bim/lib/open_project/bim/patches/work_package_patch.rb
module Bim::Patches::WorkPackagePatch
  def self.included(base)
    base.class_eval do
      has_many :element_links, class_name: 'Bim::ElementLink', dependent: :destroy
      has_one :bcf_issue, class_name: 'Bim::Bcf::Issue', dependent: :destroy

      def linked_elements
        element_links.includes(:ifc_model)
      end

      def link_element(ifc_model:, element_id:, relationship_type: :related_to, properties: {})
        element_links.create!(
          ifc_model: ifc_model,
          element_id: element_id,
          element_type: properties[:type],
          element_name: properties[:name],
          relationship_type: relationship_type,
          element_properties: properties
        )
      end

      def unlink_element(element_id)
        element_links.find_by(element_id: element_id)&.destroy
      end
    end
  end
end
```

### Layer 2: Services for Linking

```ruby
# New: modules/bim/app/services/bim/element_links/create_service.rb
class Bim::ElementLinks::CreateService < BaseServices::Create
  def initialize(user:, work_package:, ifc_model:)
    @work_package = work_package
    @ifc_model = ifc_model
    super(user: user)
  end

  def call
    in_contract_and_model do
      link_elements
      send_notifications if success?
    end
  end

  private

  def link_elements
    params[:elements].each do |element_data|
      element_link = Bim::ElementLink.new(
        work_package: @work_package,
        ifc_model: @ifc_model,
        element_id: element_data[:id],
        element_type: element_data[:type],
        element_name: element_data[:name],
        relationship_type: element_data[:relationship_type] || :related_to,
        element_properties: fetch_element_properties(element_data[:id])
      )

      unless element_link.save
        service_result.errors.merge!(element_link.errors)
        break
      end

      service_result.result = element_link
    end
  end

  def fetch_element_properties(element_id)
    metadata_service = Bim::IFCModels::MetadataExtractorService.new(@ifc_model)
    metadata_service.extract_element_properties(element_id)
  end

  def send_notifications
    OpenProject::Notifications.send(
      OpenProject::Events::WORK_PACKAGE_UPDATED,
      work_package: @work_package,
      user: user
    )
  end
end

# New: modules/bim/app/services/bim/element_links/bulk_create_service.rb
class Bim::ElementLinks::BulkCreateService
  def initialize(user:, ifc_model:, element_ids:, work_package_template:)
    @user = user
    @ifc_model = ifc_model
    @element_ids = element_ids
    @template = work_package_template
  end

  def call
    work_packages = []

    @element_ids.each do |element_id|
      wp = create_work_package_for_element(element_id)
      work_packages << wp if wp.persisted?
    end

    ServiceResult.success(result: work_packages)
  end

  private

  def create_work_package_for_element(element_id)
    metadata = fetch_element_metadata(element_id)

    # Create work package with template + element-specific data
    wp = WorkPackages::CreateService.new(user: @user).call(
      project: @ifc_model.project,
      type_id: @template[:type_id],
      subject: "#{@template[:subject_prefix]} - #{metadata[:name]}",
      description: generate_description(metadata),
      custom_field_values: @template[:custom_fields]
    ).result

    # Link element to work package
    wp.link_element(
      ifc_model: @ifc_model,
      element_id: element_id,
      relationship_type: @template[:relationship_type],
      properties: metadata
    )

    wp
  end

  def fetch_element_metadata(element_id)
    extractor = Bim::IFCModels::MetadataExtractorService.new(@ifc_model)
    extractor.extract_element_properties(element_id)
  end

  def generate_description(metadata)
    <<~DESC
      **Element Information:**
      - Type: #{metadata[:type]}
      - Name: #{metadata[:name]}
      - Level: #{metadata[:level]}
      - Discipline: #{metadata.dig(:properties, 'Discipline')}

      #{@template[:description]}
    DESC
  end
end
```

### Layer 3: Workflows & Approval

```ruby
# New: modules/bim/app/models/bim/approval_workflow.rb
class Bim::ApprovalWorkflow < ApplicationRecord
  belongs_to :work_package

  # Workflow stages: submitted → reviewed → approved/rejected → implemented
  enum stage: {
    draft: 0,
    submitted: 1,
    under_review: 2,
    approved: 3,
    rejected: 4,
    implemented: 5
  }

  has_many :approvals, class_name: 'Bim::Approval', dependent: :destroy

  def add_approver(user:, role:)
    approvals.create!(user: user, role: role, status: :pending)
  end

  def approve(user:, comment: nil)
    approval = approvals.find_by(user: user, status: :pending)
    return unless approval

    approval.update!(status: :approved, comment: comment, approved_at: Time.current)

    # Check if all approvals complete
    transition_to_approved! if all_approved?
  end

  def reject(user:, comment:)
    approval = approvals.find_by(user: user)
    approval&.update!(status: :rejected, comment: comment, approved_at: Time.current)
    self.stage = :rejected
    save!
  end

  private

  def all_approved?
    approvals.where(status: :pending).empty? &&
      approvals.where(status: :approved).any?
  end

  def transition_to_approved!
    self.stage = :approved
    save!
    notify_work_package_approved
  end
end

# New: modules/bim/app/models/bim/approval.rb
class Bim::Approval < ApplicationRecord
  belongs_to :approval_workflow, class_name: 'Bim::ApprovalWorkflow'
  belongs_to :user

  enum status: { pending: 0, approved: 1, rejected: 2 }
  enum role: { reviewer: 0, approver: 1, stakeholder: 2 }

  validates :user_id, uniqueness: { scope: :approval_workflow_id }
end
```

### Layer 4: Database Schema

```sql
-- Element links table
CREATE TABLE bim_element_links (
  id BIGSERIAL PRIMARY KEY,
  work_package_id BIGINT NOT NULL REFERENCES work_packages(id) ON DELETE CASCADE,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  element_id VARCHAR(255) NOT NULL, -- IFC GUID
  element_type VARCHAR(100), -- IfcWall, IfcDoor, etc.
  element_name VARCHAR(255),
  relationship_type INTEGER DEFAULT 4, -- 0=affected_by, 1=responsible_for, 2=depends_on, 3=observes, 4=related_to
  status INTEGER DEFAULT 0, -- 0=active, 1=completed, 2=archived
  element_properties JSONB DEFAULT '{}'::jsonb, -- Snapshot of properties
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_element_links_wp ON bim_element_links(work_package_id);
CREATE INDEX idx_element_links_model ON bim_element_links(ifc_model_id);
CREATE INDEX idx_element_links_element_id ON bim_element_links(element_id);
CREATE INDEX idx_element_links_element_type ON bim_element_links(element_type);
CREATE INDEX idx_element_links_relationship ON bim_element_links(relationship_type);
CREATE INDEX idx_element_links_status ON bim_element_links(status);
CREATE INDEX idx_element_links_properties ON bim_element_links USING gin(element_properties);

-- Unique constraint: prevent duplicate links
CREATE UNIQUE INDEX idx_unique_element_link
  ON bim_element_links(work_package_id, ifc_model_id, element_id, relationship_type)
  WHERE status = 0; -- Only for active links

-- Approval workflows
CREATE TABLE bim_approval_workflows (
  id BIGSERIAL PRIMARY KEY,
  work_package_id BIGINT NOT NULL REFERENCES work_packages(id) ON DELETE CASCADE,
  stage INTEGER DEFAULT 0, -- 0=draft, 1=submitted, 2=under_review, 3=approved, 4=rejected, 5=implemented
  submitted_at TIMESTAMP,
  approved_at TIMESTAMP,
  implemented_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_approval_workflows_wp ON bim_approval_workflows(work_package_id);
CREATE INDEX idx_approval_workflows_stage ON bim_approval_workflows(stage);

-- Individual approvals
CREATE TABLE bim_approvals (
  id BIGSERIAL PRIMARY KEY,
  approval_workflow_id BIGINT NOT NULL REFERENCES bim_approval_workflows(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role INTEGER DEFAULT 0, -- 0=reviewer, 1=approver, 2=stakeholder
  status INTEGER DEFAULT 0, -- 0=pending, 1=approved, 2=rejected
  comment TEXT,
  approved_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_approval_per_user UNIQUE (approval_workflow_id, user_id)
);

CREATE INDEX idx_approvals_workflow ON bim_approvals(approval_workflow_id);
CREATE INDEX idx_approvals_user ON bim_approvals(user_id);
CREATE INDEX idx_approvals_status ON bim_approvals(status);

-- Add to ifc_model_metadata for reverse lookups
ALTER TABLE ifc_model_metadata
  ADD COLUMN element_index JSONB DEFAULT '{}'::jsonb; -- Fast element property lookup

CREATE INDEX idx_ifc_metadata_element_index ON ifc_model_metadata USING gin(element_index);
```

### Layer 5: API Endpoints

```ruby
module API::Bim::V1
  # Element Links
  POST   /api/bim/v1/work_packages/:id/element_links
  GET    /api/bim/v1/work_packages/:id/element_links
  DELETE /api/bim/v1/element_links/:id
  PUT    /api/bim/v1/element_links/:id # Update relationship type, status

  # Bulk Operations
  POST   /api/bim/v1/ifc_models/:id/bulk_link_elements
  POST   /api/bim/v1/ifc_models/:id/create_work_packages_from_elements

  # Element Queries
  GET    /api/bim/v1/ifc_models/:id/elements/:element_id/work_packages
  GET    /api/bim/v1/work_packages?filter[element_type]=IfcWall
  GET    /api/bim/v1/work_packages?filter[element_level]=Floor+1

  # Approval Workflows
  POST   /api/bim/v1/work_packages/:id/approval_workflow
  GET    /api/bim/v1/work_packages/:id/approval_workflow
  POST   /api/bim/v1/approval_workflows/:id/approve
  POST   /api/bim/v1/approval_workflows/:id/reject
end
```

### Layer 6: Frontend Components

```typescript
// New: element-link-panel.component.ts
@Component({
  selector: 'op-element-link-panel',
  template: `
    <div class="element-links">
      <h3>Linked BIM Elements ({{ elementLinks.length }})</h3>

      <button (click)="openLinkDialog()">
        <op-icon icon="link"></op-icon>
        Link Elements
      </button>

      <table class="element-links-table">
        <thead>
          <tr>
            <th>Element</th>
            <th>Type</th>
            <th>Model</th>
            <th>Relationship</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let link of elementLinks">
            <td>
              <a (click)="highlightElement(link)">{{ link.element_name }}</a>
            </td>
            <td>{{ link.element_type }}</td>
            <td>{{ link.ifc_model.title }}</td>
            <td>
              <select [(ngModel)]="link.relationship_type"
                      (change)="updateLink(link)">
                <option value="affected_by">Affected By</option>
                <option value="responsible_for">Responsible For</option>
                <option value="depends_on">Depends On</option>
                <option value="observes">Observes</option>
                <option value="related_to">Related To</option>
              </select>
            </td>
            <td>
              <span class="status-badge" [class]="link.status">
                {{ link.status }}
              </span>
            </td>
            <td>
              <button (click)="viewElement(link)">View 3D</button>
              <button (click)="unlinkElement(link)">Unlink</button>
            </td>
          </tr>
        </tbody>
      </table>

      <div *ngIf="elementLinks.length > 0" class="element-properties">
        <h4>Element Properties</h4>
        <div *ngFor="let link of selectedLinks">
          <h5>{{ link.element_name }}</h5>
          <dl>
            <dt *ngFor="let prop of link.element_properties | keyvalue">
              {{ prop.key }}
            </dt>
            <dd *ngFor="let prop of link.element_properties | keyvalue">
              {{ prop.value }}
            </dd>
          </dl>
        </div>
      </div>
    </div>
  `
})
export class ElementLinkPanelComponent implements OnInit {
  @Input() workPackageId: number;
  elementLinks: ElementLink[] = [];
  selectedLinks: ElementLink[] = [];

  constructor(
    private elementLinkService: ElementLinkService,
    private viewerService: IFCViewerService,
    private dialog: MatDialog
  ) {}

  ngOnInit() {
    this.loadElementLinks();
  }

  loadElementLinks() {
    this.elementLinkService.getLinksForWorkPackage(this.workPackageId)
      .subscribe(links => this.elementLinks = links);
  }

  openLinkDialog() {
    const dialogRef = this.dialog.open(ElementLinkDialogComponent, {
      data: {
        workPackageId: this.workPackageId,
        viewerService: this.viewerService
      }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadElementLinks();
      }
    });
  }

  highlightElement(link: ElementLink) {
    this.viewerService.highlightElement(link.element_id);
    this.viewerService.zoomToElement(link.element_id);
  }

  viewElement(link: ElementLink) {
    // Open viewer in modal or navigate to viewer page
    this.router.navigate(['/bim', link.ifc_model.id, 'viewer'], {
      queryParams: { element: link.element_id }
    });
  }

  updateLink(link: ElementLink) {
    this.elementLinkService.updateLink(link.id, {
      relationship_type: link.relationship_type
    }).subscribe();
  }

  unlinkElement(link: ElementLink) {
    if (confirm(`Unlink ${link.element_name}?`)) {
      this.elementLinkService.deleteLink(link.id).subscribe(() => {
        this.loadElementLinks();
      });
    }
  }
}

// New: element-link-dialog.component.ts
@Component({
  selector: 'op-element-link-dialog',
  template: `
    <h2>Link BIM Elements</h2>

    <div class="link-dialog">
      <div class="viewer-pane">
        <op-ifc-viewer
          [modelId]="data.modelId"
          [selectionMode]="true"
          (elementsSelected)="onElementsSelected($event)">
        </op-ifc-viewer>
      </div>

      <div class="selection-pane">
        <h3>Selected Elements ({{ selectedElements.length }})</h3>

        <div class="relationship-selector">
          <label>Relationship Type:</label>
          <select [(ngModel)]="relationshipType">
            <option value="affected_by">Affected By</option>
            <option value="responsible_for">Responsible For</option>
            <option value="depends_on">Depends On</option>
            <option value="observes">Observes</option>
            <option value="related_to">Related To</option>
          </select>
        </div>

        <ul class="selected-elements-list">
          <li *ngFor="let element of selectedElements">
            {{ element.name }} ({{ element.type }})
            <button (click)="removeElement(element)">×</button>
          </li>
        </ul>

        <div class="actions">
          <button (click)="cancel()">Cancel</button>
          <button (click)="linkElements()"
                  [disabled]="selectedElements.length === 0">
            Link {{ selectedElements.length }} Element(s)
          </button>
        </div>
      </div>
    </div>
  `
})
export class ElementLinkDialogComponent {
  selectedElements: any[] = [];
  relationshipType = 'related_to';

  constructor(
    public dialogRef: MatDialogRef<ElementLinkDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private elementLinkService: ElementLinkService
  ) {}

  onElementsSelected(elements: any[]) {
    this.selectedElements = elements;
  }

  removeElement(element: any) {
    this.selectedElements = this.selectedElements.filter(e => e.id !== element.id);
  }

  linkElements() {
    this.elementLinkService.createLinks(this.data.workPackageId, {
      elements: this.selectedElements.map(e => ({
        id: e.id,
        type: e.type,
        name: e.name,
        relationship_type: this.relationshipType
      }))
    }).subscribe(() => {
      this.dialogRef.close(true);
    });
  }

  cancel() {
    this.dialogRef.close(false);
  }
}
```

---

## Testing Strategy

### Unit Tests
```ruby
# spec/models/bim/element_link_spec.rb
RSpec.describe Bim::ElementLink do
  it 'validates presence of element_id' do
    link = build(:element_link, element_id: nil)
    expect(link).not_to be_valid
  end

  it 'detects geometry changes' do
    link = create(:element_link, element_properties: { geometry: { hash: 'ABC123' } })

    # Simulate element geometry change in metadata
    allow(link.ifc_model.ifc_model_metadata).to receive(:find_element)
      .and_return({ 'geometry' => { 'hash' => 'XYZ789' } })

    expect(link.geometry_changed?).to be true
  end
end

# spec/services/bim/element_links/create_service_spec.rb
RSpec.describe Bim::ElementLinks::CreateService do
  it 'creates element links with properties' do
    result = described_class.new(
      user: user,
      work_package: work_package,
      ifc_model: ifc_model
    ).call(elements: [
      { id: 'elem-123', type: 'IfcWall', name: 'Wall-001', relationship_type: 'affected_by' }
    ])

    expect(result).to be_success
    expect(work_package.element_links.count).to eq 1
  end
end

# spec/services/bim/element_links/bulk_create_service_spec.rb
RSpec.describe Bim::ElementLinks::BulkCreateService do
  it 'creates work packages for multiple elements' do
    result = described_class.new(
      user: user,
      ifc_model: ifc_model,
      element_ids: ['elem-1', 'elem-2', 'elem-3'],
      work_package_template: {
        type_id: type.id,
        subject_prefix: 'RFI',
        relationship_type: 'affected_by'
      }
    ).call

    expect(result).to be_success
    expect(result.result.count).to eq 3
  end
end
```

### Integration Tests
```ruby
# spec/features/bim/element_linking_spec.rb
RSpec.describe 'BIM Element Linking', :js do
  it 'links elements to work package from viewer' do
    visit work_package_path(work_package)

    click_button 'Link BIM Elements'

    # Viewer opens in modal
    within('.element-link-dialog') do
      # Simulate element selection in viewer
      find('.viewer-canvas').click(x: 100, y: 100)

      expect(page).to have_content('Selected Elements (1)')
      expect(page).to have_content('Wall-001')

      select 'Affected By', from: 'Relationship Type'
      click_button 'Link 1 Element(s)'
    end

    # Back to work package
    expect(page).to have_content('Linked BIM Elements (1)')
    expect(page).to have_content('Wall-001')
    expect(page).to have_content('Affected By')
  end

  it 'displays element properties in work package' do
    work_package.link_element(
      ifc_model: ifc_model,
      element_id: 'wall-123',
      relationship_type: :responsible_for,
      properties: { type: 'IfcWall', name: 'Wall-001', height: 3.5 }
    )

    visit work_package_path(work_package)

    within('.element-link-panel') do
      click_link 'Wall-001'

      expect(page).to have_content('Element Properties')
      expect(page).to have_content('height: 3.5')
    end
  end

  it 'creates multiple work packages from element selection' do
    visit bim_project_ifc_viewer_path(project, ifc_model)

    # Select multiple elements
    find('.select-mode-button').click
    find('.viewer-canvas').click(x: 100, y: 100)
    find('.viewer-canvas').click(x: 200, y: 200)

    expect(page).to have_content('2 elements selected')

    click_button 'Bulk Actions'
    click_button 'Create Work Packages'

    within('.bulk-create-dialog') do
      fill_in 'Subject Prefix', with: 'RFI'
      select 'Request for Information', from: 'Type'
      click_button 'Create'
    end

    expect(page).to have_content('2 work packages created')
  end
end
```

---

## Demo Deliverables

### Minimal Viable Demo
1. **Element Linking UI**: Dialog to select elements in viewer and link to work package
2. **Link Management**: Table showing linked elements with relationship types
3. **Element Properties Display**: Show properties of linked elements
4. **Bulk Creation**: Create multiple work packages from selected elements
5. **Approval Workflow**: Simple approval flow for BIM work packages

### Demo Scenario
```
User opens Work Package "Clash Resolution #123"
    ↓
Clicks "Link BIM Elements"
    ↓
Viewer opens in dialog, selects 3 walls
    ↓
Sets relationship type to "Affected By"
    ↓
Clicks "Link 3 Elements"
    ↓
Work package now shows:
  - Linked BIM Elements (3)
  - Wall-001 (IfcWall) - Affected By
  - Wall-002 (IfcWall) - Affected By
  - Door-005 (IfcDoor) - Affected By
    ↓
Clicks "Wall-001" → properties expand:
  - Height: 3.5m
  - Width: 0.2m
  - Material: Concrete
  - Level: Floor 1
    ↓
Clicks "View 3D" → opens viewer, zooms to Wall-001
```

---

## Dependencies & Risks

### Upstream Dependencies
- **Slice 1 (IFC Upload)**: Requires element metadata extraction
- **Slice 2 (3D Viewer)**: Requires element selection and highlighting

### Downstream Dependencies
- **Slice 4 (Clash Detection)**: Links clashes to work packages
- **Slice 7 (Collaboration)**: Element-aware comments
- **Slice 8 (Dashboards)**: Element-based reporting
- **Slice 9 (Progress Tracking)**: Element-level progress

### Technical Risks
1. **Performance**: Many-to-many linking could create large datasets
   - **Mitigation**: Pagination, lazy loading, database indexing

2. **Metadata Sync**: Element properties may become stale
   - **Mitigation**: Geometry change detection, refresh UI

3. **Viewer Integration**: Complex selection interactions
   - **Mitigation**: Use xeokit's built-in selection tools

### Licensing Risks
- No new dependencies, GPL-compatible ✅

---

## Success Criteria

### Functional Requirements
- ✅ Many-to-many element-to-work package linking
- ✅ 5 relationship types (affected_by, responsible_for, etc.)
- ✅ Element property snapshot at link time
- ✅ Bulk work package creation from element selection
- ✅ Approval workflow for BIM work packages
- ✅ Element-based work package queries

### Non-Functional Requirements
- ✅ Link creation <500ms for up to 100 elements
- ✅ Support 1000+ links per work package
- ✅ Geometry change detection <1s

### Quality Gates
- ✅ >90% unit test coverage
- ✅ E2E tests for linking workflows
- ✅ API contract tests

---

## Implementation Phases

### Phase 1: Data Model (Week 1)
- Create `bim_element_links` table
- Enhance MetadataExtractorService for element lookup
- Update WorkPackage patch

### Phase 2: Services (Week 2)
- CreateService, BulkCreateService
- Element property snapshotting
- Geometry change detection

### Phase 3: API & Frontend (Week 3)
- API endpoints for CRUD
- ElementLinkPanelComponent
- ElementLinkDialogComponent
- Viewer selection integration

### Phase 4: Workflows (Week 4)
- Approval workflow models
- Approval UI components
- Notifications

---

**Deliberation Complete** ✅
**Ready for Action Mode** (after Slices 1 & 2)
**Estimated LOC:** ~2,000 (Backend: 1,200, Frontend: 800)
**Estimated Duration:** 4 weeks
**Risk Level:** Medium
