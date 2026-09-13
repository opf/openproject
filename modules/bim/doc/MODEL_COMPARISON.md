# Model Comparison Feature

## Overview

The Model Comparison feature enables version comparison of IFC models to detect changes between revisions. It identifies added, deleted, and modified elements with detailed change tracking.

## Key Features

### 1. Element-Level Diff
- **Added Elements**: New elements in model2 not in model1
- **Deleted Elements**: Elements in model1 removed in model2
- **Modified Elements**: Elements changed between versions
- **Unchanged Elements**: Identical elements

### 2. Change Detection
- **Geometry Changes**: Bounding box position and size changes
- **Property Changes**: Parameter value modifications
- **Type Changes**: IFC element type modifications
- **Configurable**: Options to enable/disable detection types

### 3. Approval Workflow
- Review comparisons
- Approve changes for implementation
- Reject changes with comments
- Track approval history

## API Reference

### Run Comparison

```bash
POST /api/v3/bim/comparisons
{
  "model1_id": 123,
  "model2_id": 456,
  "name": "V1 vs V2",
  "description": "Comparison of initial design to updated version",
  "options": {
    "detect_geometry_changes": true,
    "detect_property_changes": true,
    "ignore_properties": ["LastModified"]
  }
}
```

### List Comparisons

```bash
GET /api/v3/bim/comparisons?model_id=123&status=completed
```

### Approve Comparison

```bash
POST /api/v3/bim/comparisons/:id/approve
{
  "comment": "Changes approved for implementation"
}
```

### Reject Comparison

```bash
POST /api/v3/bim/comparisons/:id/reject
{
  "comment": "Too many structural changes"
}
```

## Usage Examples

### Compare Two Models

```ruby
service = Bim::Comparison::CompareService.new(
  model1: old_model,
  model2: new_model,
  options: {
    detect_geometry_changes: true,
    detect_property_changes: true,
    ignore_properties: ['LastModified', 'RevitId']
  }
)

result = service.call
comparison = result.result

puts "Changes found: #{comparison.total_changes}"
puts "Added: #{comparison.added_count}"
puts "Deleted: #{comparison.deleted_count}"
puts "Modified: #{comparison.modified_count}"
```

### Generate Report

```ruby
comparison = Bim::ModelComparison.find(123)
generator = Bim::Comparison::ReportGenerator.new(comparison)
report = generator.generate

puts report[:summary]
puts report[:change_details]
puts report[:recommendations]
```

### Frontend Integration

```typescript
<op-comparison-viewer
  [comparisonId]="123"
  [viewer]="xeokitViewer"
  (approved)="onApproved($event)"
  (rejected)="onRejected($event)">
</op-comparison-viewer>
```

## Demo Data

Generate demo data:

```bash
rails runner modules/bim/db/seeds/model_comparison_demo_data.rb
```

Creates:
- 2 model versions (V1, V2)
- 1 comparison with changes
- Approved comparison example

## Database Schema

```sql
CREATE TABLE bim_model_comparisons (
  id BIGSERIAL PRIMARY KEY,
  model1_id BIGINT NOT NULL,
  model2_id BIGINT NOT NULL,
  comparison_type VARCHAR(50) DEFAULT 'version',
  status INTEGER DEFAULT 0,
  added_count INTEGER DEFAULT 0,
  deleted_count INTEGER DEFAULT 0,
  modified_count INTEGER DEFAULT 0,
  unchanged_count INTEGER DEFAULT 0,
  changes_data JSONB DEFAULT '{}',
  statistics JSONB DEFAULT '{}'
);
```

## Best Practices

1. **Meaningful Names**: Give comparisons descriptive names
2. **Regular Comparisons**: Compare after major model updates
3. **Review Changes**: Always review before approval
4. **Property Filtering**: Use ignore list for irrelevant properties
5. **Documentation**: Add comments when approving/rejecting

## Performance

- Comparison complexity: O(n) where n = element count
- Optimized for models up to 100,000 elements
- Results cached in database
- Statistics pre-calculated

## Future Enhancements

- PDF/CSV export
- Visual diff in 3D viewer
- BCF integration
- Baseline management
- Federated model comparison
