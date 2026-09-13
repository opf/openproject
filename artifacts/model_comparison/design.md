# Slice 6: Model Comparison - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 6
**Dependencies:**
- Slice 1 (IFC Upload) - requires file checksums and versioning
- Slice 2 (3D Viewer) - requires visual overlays
- Slice 5 (Federated Models) - optional for comparing federated sets

---

## Current State Analysis

### Existing Capabilities (Community Edition)
❌ **No model comparison capabilities**

---

## Enterprise Enhancement Goals

### 1. IFC Version Comparison
- **Detect Changes**: Added, deleted, modified elements
- **Geometry Changes**: Element moved, resized, or reshaped
- **Property Changes**: Parameter value changes
- **Visual Diff**: Color-coded overlay (green=added, red=deleted, yellow=modified)

### 2. Comparison Types
- **Model vs Model**: Compare two different IFC files
- **Version vs Version**: Compare revisions of same model
- **Baseline vs Current**: Compare against saved baseline
- **Federated Comparison**: Compare entire federation sets

### 3. Change Reporting
- **Change Summary**: Count of additions, deletions, modifications
- **Element-Level Details**: What changed in each element
- **Export Reports**: PDF/CSV change reports
- **Change Approval**: Workflow for reviewing changes

---

## Proposed Architecture

### Layer 1: Comparison Service

```ruby
# New: modules/bim/app/services/bim/comparison/compare_service.rb
class Bim::Comparison::CompareService
  def initialize(model1, model2)
    @model1 = model1
    @model2 = model2
  end

  def call
    metadata1 = load_metadata(@model1)
    metadata2 = load_metadata(@model2)

    changes = {
      added: find_added(metadata1, metadata2),
      deleted: find_deleted(metadata1, metadata2),
      modified: find_modified(metadata1, metadata2)
    }

    # Save comparison results
    comparison = Bim::ModelComparison.create!(
      model1: @model1,
      model2: @model2,
      added_count: changes[:added].size,
      deleted_count: changes[:deleted].size,
      modified_count: changes[:modified].size,
      changes_data: changes
    )

    ServiceResult.success(result: comparison)
  end

  private

  def load_metadata(model)
    model.ifc_model_metadata&.element_index || {}
  end

  def find_added(metadata1, metadata2)
    (metadata2.keys - metadata1.keys).map do |elem_id|
      { element_id: elem_id, element: metadata2[elem_id] }
    end
  end

  def find_deleted(metadata1, metadata2)
    (metadata1.keys - metadata2.keys).map do |elem_id|
      { element_id: elem_id, element: metadata1[elem_id] }
    end
  end

  def find_modified(metadata1, metadata2)
    common_ids = metadata1.keys & metadata2.keys

    common_ids.filter_map do |elem_id|
      changes = detect_element_changes(metadata1[elem_id], metadata2[elem_id])
      { element_id: elem_id, changes: changes } if changes.any?
    end
  end

  def detect_element_changes(elem1, elem2)
    changes = []

    # Geometry change
    if elem1.dig('geometry', 'hash') != elem2.dig('geometry', 'hash')
      changes << { type: 'geometry', old: elem1['geometry'], new: elem2['geometry'] }
    end

    # Property changes
    props1 = elem1['properties'] || {}
    props2 = elem2['properties'] || {}

    (props1.keys | props2.keys).each do |prop_key|
      if props1[prop_key] != props2[prop_key]
        changes << {
          type: 'property',
          key: prop_key,
          old: props1[prop_key],
          new: props2[prop_key]
        }
      end
    end

    changes
  end
end
```

### Layer 2: Data Model

```ruby
# New: modules/bim/app/models/bim/model_comparison.rb
class Bim::ModelComparison < ApplicationRecord
  belongs_to :model1, class_name: 'Bim::IFCModels::IFCModel'
  belongs_to :model2, class_name: 'Bim::IFCModels::IFCModel'
  belongs_to :created_by, class_name: 'User', optional: true

  # changes_data: { added: [], deleted: [], modified: [] }

  def total_changes
    added_count + deleted_count + modified_count
  end

  def generate_report
    Bim::Comparison::ReportGenerator.new(self).call
  end
end
```

### Layer 3: Database Schema

```sql
CREATE TABLE bim_model_comparisons (
  id BIGSERIAL PRIMARY KEY,
  model1_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  model2_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  added_count INTEGER DEFAULT 0,
  deleted_count INTEGER DEFAULT 0,
  modified_count INTEGER DEFAULT 0,
  changes_data JSONB DEFAULT '{}'::jsonb,
  created_by_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_comparisons_model1 ON bim_model_comparisons(model1_id);
CREATE INDEX idx_comparisons_model2 ON bim_model_comparisons(model2_id);
```

### Layer 4: Viewer Integration

```typescript
// comparison-viewer.component.ts
export class ComparisonViewerComponent {
  loadComparison(comparisonId: number) {
    this.comparisonService.get(comparisonId).subscribe(comparison => {
      this.applyComparisonColors(comparison.changes_data);
    });
  }

  applyComparisonColors(changes: any) {
    // Added elements: Green
    changes.added.forEach((elem: any) => {
      this.viewerService.colorElement(elem.element_id, '#00FF00');
    });

    // Deleted elements: Red
    changes.deleted.forEach((elem: any) => {
      this.viewerService.colorElement(elem.element_id, '#FF0000');
    });

    // Modified elements: Yellow
    changes.modified.forEach((elem: any) => {
      this.viewerService.colorElement(elem.element_id, '#FFFF00');
    });
  }
}
```

---

**Deliberation Complete** ✅
**Estimated LOC:** ~800 (Ruby: 600, TypeScript: 200)
**Estimated Duration:** 2 weeks
**Risk Level:** Medium
