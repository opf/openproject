# Clash Detection Feature

## Overview

The Clash Detection feature automatically identifies geometric conflicts between BIM elements within IFC models. It detects hard clashes (physical intersections), soft clashes (clearance violations), and provides comprehensive tracking and resolution workflows.

## Key Features

### 1. Automated Detection
- **Hard Clashes**: Physical element intersections
- **Soft Clashes**: Clearance violations (elements too close)
- **Clearance Clashes**: Minimum distance violations
- **Workflow Clashes**: Construction sequence conflicts

### 2. Severity Classification
- **Critical**: Must resolve immediately (large overlaps, structural conflicts)
- **Major**: Should resolve soon (significant clearance violations)
- **Minor**: Can resolve later or accept (small overlaps, non-critical)

### 3. Resolution Tracking
- Assign clashes to users
- Link to work packages for resolution
- Approve clashes as acceptable
- Mark as resolved with resolution type
- Track resolution history

### 4. Detection Algorithms
- **AABB Intersection**: Axis-Aligned Bounding Box detection
- **Overlap Volume**: Calculate intersection volume for hard clashes
- **Distance Calculation**: Minimum distance between elements
- **Clash Point**: 3D location of conflict

## API Reference

### Detect Clashes

```bash
POST /api/v3/bim/clashes/detect
{
  "ifc_model_id": 123,
  "clearance_distance": 50.0,
  "soft_clash_distance": 100.0,
  "detect_hard_clashes": true,
  "detect_soft_clashes": true,
  "element_types": ["IfcWall", "IfcColumn"]
}
```

### List Clashes

```bash
GET /api/v3/bim/clashes?ifc_model_id=123&status=new&severity=critical
```

### Approve Clash

```bash
POST /api/v3/bim/clashes/:id/approve
{
  "comment": "Acceptable clearance violation"
}
```

### Resolve Clash

```bash
POST /api/v3/bim/clashes/:id/resolve
{
  "resolution_type": "redesign",
  "comment": "Elements redesigned to eliminate overlap"
}
```

## Usage Examples

### Detect All Clashes in Model

```ruby
service = Bim::ClashDetectionService.new(
  ifc_model: ifc_model,
  options: {
    clearance_distance: 50.0,
    soft_clash_distance: 100.0,
    detect_hard_clashes: true
  }
)

result = service.detect_all_clashes
puts "Found #{result.result[:count]} clashes"
```

### Detect Clashes for Specific Element

```ruby
result = service.detect_clashes_for_element('wall-101')
result.result[:clashes].each do |clash|
  puts "Clash: #{clash.display_name} - #{clash.severity}"
end
```

### Create Work Package for Clash

```ruby
clash = Bim::Clash.find(123)
work_package = clash.create_work_package!(
  type_id: task_type.id,
  assigned_to: user
)
```

## Clash Lifecycle

1. **Detection**: Clash is detected and created with status 'new'
2. **Assignment**: Clash assigned to user, status changes to 'active'
3. **Review**: User reviews in 3D viewer
4. **Resolution**: Either:
   - Approve as acceptable
   - Resolve with fix (redesign, relocate, etc.)
   - Link to work package for tracking
5. **Closure**: Clash marked as closed/archived

## Configuration

Default detection thresholds:
```ruby
{
  clearance_distance: 50.0,      # mm
  soft_clash_distance: 100.0,    # mm
  min_overlap_volume: 0.001      # cubic units
}
```

## Performance Considerations

- Detection complexity: O(n²) where n = element count
- Use element type filters to reduce comparisons
- Batch detection preferred over individual
- Detection run IDs enable result comparison
- Consider spatial indexing for large models (future enhancement)

## Best Practices

1. Run detection after major model changes
2. Set appropriate thresholds for your project
3. Use element filters to focus on relevant clashes
4. Assign critical clashes immediately
5. Link complex clashes to work packages
6. Document resolution decisions in comments
7. Use approval for minor acceptable clashes

## Resolution Types

- **redesign**: Elements were redesigned to eliminate clash
- **accepted**: Clash accepted as minor/acceptable (e.g., intentional overlap)
- **relocated**: Elements were moved in space
- **removed**: One element was removed from design
- **phased**: Construction phasing eliminates physical conflict
- **false_positive**: Clash was incorrectly detected

## Integration

Clash Detection integrates with:
- **Element Linking**: Link clashes to work packages
- **BCF**: Export clashes as BCF issues (future)
- **3D Viewer**: Visualize clashes in context (future)
- **Reporting**: Generate clash reports (future)

## Database Schema

```sql
CREATE TABLE bim_clashes (
  id SERIAL PRIMARY KEY,
  ifc_model_id INTEGER NOT NULL,
  element_a_id VARCHAR(50) NOT NULL,
  element_b_id VARCHAR(50) NOT NULL,
  clash_type INTEGER NOT NULL,  -- 0=hard, 1=soft, 2=clearance, 3=workflow
  severity INTEGER NOT NULL,    -- 0=critical, 1=major, 2=minor
  status INTEGER NOT NULL,      -- 0=new, 1=active, 2=approved, 3=resolved, 4=closed
  distance DECIMAL(10,4),
  overlap_volume DECIMAL(15,4),
  clash_point JSONB,
  detected_at TIMESTAMP NOT NULL,
  -- resolution tracking fields
  work_package_id INTEGER,
  assigned_to_id INTEGER,
  approved_by_id INTEGER,
  resolved_by_id INTEGER,
  resolution_type INTEGER,
  -- unique constraint
  UNIQUE(ifc_model_id, element_a_id, element_b_id)
);
```

## Future Enhancements

- OBB (Oriented Bounding Box) detection for accuracy
- Mesh-based clash detection for exact geometry
- Spatial indexing (R-tree, octree) for performance
- Clash grouping and clustering
- Clash animations in 3D viewer
- Automatic clash resolution suggestions
- ML-based clash severity prediction
- BCF export/import integration
- Clash trending and analytics

## Support

For issues or questions:
- GitHub: https://github.com/opf/openproject/issues
- Community: https://community.openproject.org
