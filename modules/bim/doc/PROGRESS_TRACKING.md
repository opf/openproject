# Progress Tracking & Baseline Management

## Overview

The Progress Tracking feature provides comprehensive construction progress management for BIM elements. Track element-level completion, create baseline snapshots, compare progress over time, and sync with work packages.

## Key Features

### 1. Element-Level Progress Tracking
- **Status Management**: planned, in_progress, completed, on_hold
- **Percentage Completion**: 0-100% progress tracking
- **Schedule Tracking**: Planned vs actual dates with variance calculation
- **Work Package Integration**: Link elements to work packages, sync progress
- **User Tracking**: Record who updated progress and when

### 2. Baseline Management
- **Progress Snapshots**: Capture point-in-time progress state
- **Comparison Analysis**: Compare current progress to baselines
- **Variance Tracking**: Element-level and model-level variance
- **Current Baseline**: Mark one baseline as current for reference
- **Statistics**: Pre-calculated statistics by type and status

### 3. Schedule Variance Analysis
- **Delayed Detection**: Identify elements behind schedule
- **Ahead Detection**: Track elements completed early
- **Duration Calculation**: Planned vs actual duration
- **Visual Indicators**: Color-coded progress visualization

### 4. Bulk Operations
- **Bulk Updates**: Update multiple elements in single transaction
- **Work Package Sync**: Sync progress from all linked work packages
- **Baseline Snapshots**: Create snapshots of all element progress
- **Transactional**: All-or-nothing updates with rollback

## API Reference

### Element Progress Endpoints

#### List Element Progress
```bash
GET /api/v3/bim/progress?model_id=123&status=in_progress&element_type=IfcWall

Query Parameters:
  - model_id (required): IFC model ID
  - status: Filter by status (planned, in_progress, completed, on_hold)
  - element_type: Filter by IFC type (IfcWall, IfcDoor, etc.)
  - work_package_id: Filter by work package
  - baseline_id: Filter by baseline (omit for current progress)
  - page, per_page: Pagination (default: page=1, per_page=50, max=200)

Response:
{
  "progress": [
    {
      "id": 1,
      "element_id": "wall-1",
      "element_name": "North Wall",
      "element_type": "IfcWall",
      "display_name": "North Wall",
      "status": "in_progress",
      "percent_complete": 75,
      "progress_color": "#ff9800",
      "work_package_id": 42,
      "updated_at": "2025-01-15T10:30:00Z",
      "updated_by": "John Doe"
    }
  ],
  "total": 150,
  "page": 1,
  "per_page": 50
}
```

#### Show Element Progress (Detailed)
```bash
GET /api/v3/bim/progress/1

Response:
{
  "id": 1,
  "element_id": "wall-1",
  "status": "in_progress",
  "percent_complete": 75,
  "planned_start": "2025-01-01",
  "planned_finish": "2025-01-20",
  "actual_start": "2025-01-02",
  "actual_finish": null,
  "planned_duration_days": 19,
  "actual_duration_days": null,
  "schedule_variance_days": null,
  "delayed": false,
  "ahead_of_schedule": false,
  "complete": false,
  "in_progress": true,
  "started": true
}
```

#### Create/Update Element Progress
```bash
POST /api/v3/bim/progress
{
  "ifc_model_id": 123,
  "element_id": "wall-1",
  "percent_complete": 50,
  "status": "in_progress",  // Optional, auto-determined from percent_complete
  "planned_start": "2025-01-01",
  "planned_finish": "2025-01-20",
  "work_package_id": 42
}

Response: 201 Created with element progress details
```

#### Update Element Progress
```bash
PATCH /api/v3/bim/progress/1
{
  "percent_complete": 100
}

Note: Status is automatically updated based on percent_complete:
  - 0% → planned
  - 1-99% → in_progress
  - 100% → completed
```

#### Bulk Update Progress
```bash
POST /api/v3/bim/progress/bulk_update
{
  "model_id": 123,
  "updates": [
    { "element_id": "wall-1", "percent_complete": 75 },
    { "element_id": "wall-2", "percent_complete": 100 },
    { "element_id": "door-1", "percent_complete": 50 }
  ]
}

Response:
{
  "message": "Bulk update successful",
  "updated_count": 3,
  "progress": [ /* array of updated progress */ ]
}

Note: Transactional - all updates succeed or all rollback
```

#### Sync from Work Packages
```bash
POST /api/v3/bim/progress/sync_work_packages
{
  "model_id": 123
}

Response:
{
  "message": "Work package sync successful",
  "synced_count": 15
}

Note: Updates all elements linked to work packages
      Uses work_package.done_ratio or status.is_closed
```

#### Get Model Statistics
```bash
GET /api/v3/bim/progress/statistics?model_id=123

Response:
{
  "total_elements": 100,
  "completed_elements": 25,
  "in_progress_elements": 50,
  "planned_elements": 20,
  "on_hold_elements": 5,
  "average_progress": 47.5,
  "overall_progress": 25.0,
  "delayed_count": 8,
  "ahead_count": 3,
  "on_schedule_count": 14
}
```

### Baseline Endpoints

#### List Baselines
```bash
GET /api/v3/bim/baselines?model_id=123&is_current=true

Query Parameters:
  - model_id: Filter by model
  - is_current: Filter by current status (true/false)
  - page, per_page: Pagination (default: page=1, per_page=25, max=100)

Response:
{
  "baselines": [
    {
      "id": 1,
      "name": "Week 1 Baseline",
      "description": "End of week 1",
      "snapshot_date": "2025-01-07",
      "is_current": true,
      "total_elements": 100,
      "completed_elements": 30,
      "overall_progress": 30.0,
      "completion_percentage": 30.0,
      "created_at": "2025-01-07T17:00:00Z",
      "created_by": "Project Manager"
    }
  ],
  "total": 5,
  "page": 1,
  "per_page": 25
}
```

#### Show Baseline (Detailed)
```bash
GET /api/v3/bim/baselines/1

Response:
{
  "id": 1,
  "name": "Week 1 Baseline",
  "overall_progress": 30.0,
  "statistics": { /* JSONB data */ },
  "statistics_by_type": {
    "IfcWall": { "total": 40, "completed": 10, "progress": 25.0 },
    "IfcDoor": { "total": 20, "completed": 5, "progress": 25.0 }
  },
  "statistics_by_status": {
    "completed": 30,
    "in_progress": 40,
    "planned": 30
  }
}
```

#### Create Baseline
```bash
POST /api/v3/bim/baselines
{
  "ifc_model_id": 123,
  "name": "Q1 2025 Baseline",
  "description": "First quarter progress baseline",
  "snapshot_date": "2025-03-31",
  "create_snapshot": true  // Immediately snapshot current progress
}

Response: 201 Created with baseline details
```

#### Create Snapshot
```bash
POST /api/v3/bim/baselines/1/snapshot

Note: Creates snapshot of current progress state
      Copies all current element progress to baseline
      Updates baseline statistics
```

#### Set as Current
```bash
POST /api/v3/bim/baselines/1/set_current

Note: Sets this baseline as current
      Unsets previous current baseline for same model
```

#### Compare to Current
```bash
GET /api/v3/bim/baselines/1/compare

Response:
{
  "baseline_name": "Week 1 Baseline",
  "baseline_date": "2025-01-07",
  "baseline_progress": 30.0,
  "current_progress": 52.5,
  "variance": 22.5,
  "element_changes": [
    {
      "element_id": "wall-1",
      "element_name": "North Wall",
      "baseline_progress": 25,
      "current_progress": 75,
      "variance": 50
    },
    {
      "element_id": "wall-2",
      "element_name": "South Wall",
      "baseline_progress": 50,
      "current_progress": 100,
      "variance": 50
    }
  ]
}

Note: element_changes sorted by absolute variance (largest first)
```

## Usage Examples

### Track Element Progress

```ruby
# Get progress tracking service
service = Bim::Progress::TrackingService.new(
  ifc_model: model,
  user: current_user
)

# Update single element
result = service.update_element_progress(
  element_id: 'wall-1',
  percent_complete: 75,
  planned_start: Date.current - 10.days,
  planned_finish: Date.current + 5.days
)

progress = result.result
puts "Progress: #{progress.percent_complete}%"
puts "Status: #{progress.status}"
puts "Color: #{progress.progress_color}"
```

### Bulk Update Progress

```ruby
service = Bim::Progress::TrackingService.new(ifc_model: model)

updates = [
  { element_id: 'wall-1', percent_complete: 50 },
  { element_id: 'wall-2', percent_complete: 75 },
  { element_id: 'door-1', percent_complete: 100 }
]

result = service.bulk_update_progress(updates)

if result.success?
  puts "Updated #{result.result.size} elements"
else
  puts "Errors: #{result.errors}"
end
```

### Create and Compare Baselines

```ruby
# Create baseline with snapshot
baseline = Bim::ProgressBaseline.create!(
  ifc_model: model,
  name: 'Week 1 Baseline',
  snapshot_date: Date.current,
  created_by: current_user
)

baseline.create_snapshot!

# Later... advance progress
service.update_element_progress(element_id: 'wall-1', percent_complete: 100)

# Compare to baseline
comparison = service.compare_to_baseline(baseline)

puts "Baseline: #{comparison[:baseline_progress]}%"
puts "Current: #{comparison[:current_progress]}%"
puts "Variance: #{comparison[:variance]}%"

comparison[:element_changes].each do |change|
  puts "  #{change[:element_name]}: #{change[:variance]:+d}%"
end
```

### Sync from Work Packages

```ruby
service = Bim::Progress::TrackingService.new(ifc_model: model, user: current_user)

result = service.sync_from_work_packages

puts "Synced #{result.result[:synced_count]} elements from work packages"
```

### Get Model Statistics

```ruby
service = Bim::Progress::TrackingService.new(ifc_model: model)

stats = service.calculate_model_progress

puts "Overall Progress: #{stats[:overall_progress]}%"
puts "Completed: #{stats[:completed_elements]} / #{stats[:total_elements]}"
puts "Delayed: #{stats[:delayed_count]}"
puts "Ahead: #{stats[:ahead_count]}"
```

### Frontend Integration

```typescript
<op-progress-tracker
  [modelId]="123"
  [viewer]="xeokitViewer"
  (progressUpdated)="onProgressUpdated($event)">
</op-progress-tracker>
```

## Demo Data

Generate comprehensive demo data:

```bash
rails runner modules/bim/db/seeds/progress_tracking_demo_data.rb
```

Creates:
- 1 IFC model with 17 elements
- 6 work packages (foundation, columns, walls, etc.)
- 17 element progress records (various statuses and schedules)
- 2 baselines (Week 1, Week 2)
- Realistic progress distribution (completed, in progress, planned)
- Schedule variance examples (delayed, ahead, on time)

## Database Schema

### bim_element_progresses

```sql
CREATE TABLE bim_element_progresses (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL,
  baseline_id BIGINT,
  work_package_id BIGINT,
  updated_by_id BIGINT,
  element_id VARCHAR(255) NOT NULL,
  element_type VARCHAR(255),
  element_name VARCHAR(255),
  status INTEGER DEFAULT 0 NOT NULL,  -- 0: planned, 1: in_progress, 2: completed, 3: on_hold
  percent_complete INTEGER DEFAULT 0 NOT NULL,
  planned_start DATE,
  planned_finish DATE,
  actual_start DATE,
  actual_finish DATE,
  CONSTRAINT percent_complete_range CHECK (percent_complete >= 0 AND percent_complete <= 100),
  CONSTRAINT unique_element_per_baseline UNIQUE (ifc_model_id, element_id, baseline_id)
);
```

### bim_progress_baselines

```sql
CREATE TABLE bim_progress_baselines (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL,
  created_by_id BIGINT,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  snapshot_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT FALSE,
  total_elements INTEGER DEFAULT 0 NOT NULL,
  completed_elements INTEGER DEFAULT 0 NOT NULL,
  overall_progress DECIMAL(5,2) DEFAULT 0.0,
  statistics JSONB DEFAULT '{}',
  CONSTRAINT completed_within_total CHECK (completed_elements <= total_elements)
);
```

## Status Transitions

Progress status automatically transitions based on percent_complete:

```
percent_complete = 0    → status: planned
percent_complete = 1-99 → status: in_progress
percent_complete = 100  → status: completed

Manual override: status: on_hold (preserves percent_complete)
```

## Progress Color Coding

Visual indicators based on status and schedule:

```
completed → #4caf50 (green)
in_progress + delayed → #f44336 (red)
in_progress + ahead → #2196f3 (blue)
in_progress + on_track → #ff9800 (orange)
on_hold → #9e9e9e (gray)
planned → #e0e0e0 (light gray)
```

## Best Practices

1. **Regular Updates**: Update progress weekly or bi-weekly
2. **Baseline Snapshots**: Create baselines at project milestones
3. **Work Package Linking**: Link elements to work packages for sync
4. **Schedule Tracking**: Set planned dates for variance analysis
5. **Bulk Operations**: Use bulk updates for efficiency
6. **Current Baseline**: Maintain one current baseline for reference
7. **Demo Data**: Use demo data for training and testing

## Performance

- Progress queries: O(n) where n = element count
- Bulk updates: Transactional, optimized for batches up to 500
- Statistics calculation: Pre-aggregated on baselines
- Baseline comparison: Efficient with proper indexes
- Supports models up to 10,000 elements efficiently

## Future Enhancements

- PDF/Excel export of progress reports
- Gantt chart visualization
- Progress forecasting and projections
- BCF integration for issue tracking
- Mobile app for field updates
- Photo documentation
- Resource allocation tracking
- Cost integration

## Related Features

- **Model Comparison**: Compare model versions
- **Clash Detection**: Identify geometric conflicts
- **Work Package Linking**: Connect BIM to project tasks
- **Baseline Management**: Historical progress tracking
