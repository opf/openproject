# Slice 9: Progress & Baseline Tracking - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 9
**Dependencies:**
- Slice 1 (IFC Upload) - requires element metadata
- Slice 3 (Linking) - for work package → element mapping

---

## Current State Analysis

### Existing Capabilities (Community Edition)
✅ **Work Package Progress**: % complete field
✅ **Gantt Charts**: Timeline visualization
❌ **No BIM element-level progress tracking**
❌ **No baseline comparison**

---

## Enterprise Enhancement Goals

### 1. Element-Level Progress
- **Track Completion**: Mark elements as planned, in-progress, complete
- **Progress Percentage**: Calculate % based on element count or quantity
- **Discipline Progress**: Track by architectural, structural, MEP
- **Zone Progress**: Progress by building level/zone

### 2. Baseline Management
- **Create Baselines**: Snapshot current state as baseline
- **Planned vs Actual**: Compare current progress to baseline
- **Variance Analysis**: Identify delays or acceleration
- **Visual Comparison**: Color-code elements by variance

### 3. Integration with OpenProject Core
- **Gantt Baseline**: Link to OpenProject's baseline feature
- **Progress Sync**: Work package % complete → element progress
- **Reporting**: Progress dashboards (Slice 8 integration)

---

## Proposed Architecture

### Layer 1: Progress Tracking

```ruby
# New: modules/bim/app/models/bim/element_progress.rb
class Bim::ElementProgress < ApplicationRecord
  belongs_to :ifc_model
  belongs_to :baseline, class_name: 'Bim::ProgressBaseline', optional: true

  enum status: {
    planned: 0,
    in_progress: 1,
    completed: 2,
    on_hold: 3
  }

  # element_id: IFC GUID
  # element_type: IfcWall, etc.
  # planned_start, planned_finish: Dates
  # actual_start, actual_finish: Dates
  # percent_complete: 0-100

  def variance_days
    return 0 unless planned_finish && actual_finish
    (actual_finish - planned_finish).to_i
  end

  def is_delayed?
    variance_days > 0
  end
end

# New: modules/bim/app/models/bim/progress_baseline.rb
class Bim::ProgressBaseline < ApplicationRecord
  belongs_to :project
  has_many :element_progresses, class_name: 'Bim::ElementProgress'

  # snapshot_date: When baseline was created
  # name: "Q1 2025 Baseline"

  def create_snapshot!
    # Snapshot current element progress
    project.ifc_models.each do |model|
      model.elements.each do |element|
        element_progresses.create!(
          ifc_model: model,
          element_id: element[:id],
          element_type: element[:type],
          status: element[:status] || :planned,
          percent_complete: element[:progress] || 0,
          planned_start: element[:planned_start],
          planned_finish: element[:planned_finish]
        )
      end
    end
  end

  def compare_to_current
    # Calculate variance for each element
    element_progresses.map do |baseline_elem|
      current = find_current_element(baseline_elem.element_id)
      {
        element_id: baseline_elem.element_id,
        baseline_progress: baseline_elem.percent_complete,
        current_progress: current&.percent_complete || 0,
        variance: (current&.percent_complete || 0) - baseline_elem.percent_complete
      }
    end
  end
end
```

### Layer 2: Database Schema

```sql
-- Progress baselines
CREATE TABLE bim_progress_baselines (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  snapshot_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Element progress tracking
CREATE TABLE bim_element_progresses (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  baseline_id BIGINT REFERENCES bim_progress_baselines(id) ON DELETE CASCADE,
  element_id VARCHAR(255) NOT NULL,
  element_type VARCHAR(100),
  status INTEGER DEFAULT 0, -- 0=planned, 1=in_progress, 2=completed, 3=on_hold
  percent_complete INTEGER DEFAULT 0 CHECK (percent_complete >= 0 AND percent_complete <= 100),
  planned_start DATE,
  planned_finish DATE,
  actual_start DATE,
  actual_finish DATE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_element_progress_model ON bim_element_progresses(ifc_model_id);
CREATE INDEX idx_element_progress_element ON bim_element_progresses(element_id);
CREATE INDEX idx_element_progress_baseline ON bim_element_progresses(baseline_id);
```

### Layer 3: Viewer Integration

```typescript
// Show progress in 3D viewer
export class ProgressVisualizationService {
  visualizeProgress(modelId: number, baseline?: number) {
    this.progressService.getProgress(modelId, baseline).subscribe(data => {
      data.forEach(elem => {
        const color = this.getProgressColor(elem.percent_complete, elem.variance);
        this.viewerService.colorElement(elem.element_id, color);
      });
    });
  }

  getProgressColor(progress: number, variance?: number): string {
    if (variance && variance < 0) return '#00FF00'; // Ahead of schedule
    if (variance && variance > 10) return '#FF0000'; // Behind schedule
    if (progress === 100) return '#0000FF'; // Complete
    if (progress > 0) return '#FFFF00'; // In progress
    return '#CCCCCC'; // Planned
  }
}
```

---

## Demo Deliverables

**MVP Demo:**
1. Create baseline "Q1 2025"
2. Update element progress (25 elements → 75% complete)
3. Compare to baseline → 10 elements behind schedule
4. Viewer shows color-coded progress (red=delayed, green=ahead, blue=complete)
5. Generate progress report

---

**Deliberation Complete** ✅
**Estimated LOC:** ~800 (Ruby: 600, TypeScript: 200)
**Estimated Duration:** 2 weeks
**Risk Level:** Low
