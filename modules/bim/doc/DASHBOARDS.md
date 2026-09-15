# BIM Dashboards & Reporting

## Overview

The BIM Dashboards feature provides comprehensive project visualization and reporting capabilities. Create customizable dashboards with drag-and-drop widgets displaying real-time BIM metrics, charts, and KPIs.

## Key Features

### 1. Configurable Dashboards
- **Multi-Dashboard Support**: Create unlimited dashboards per project
- **Default Dashboard**: Auto-generated default dashboard for quick start
- **User-Specific**: Personal dashboards for individual users
- **Public/Private**: Share dashboards or keep them private
- **Grid Layout**: Responsive 12-column grid with drag-and-drop
- **Export/Import**: Save dashboard templates and share configurations

### 2. Widget Library (16 Types)
- **model_count**: IFC model statistics and counts
- **clash_summary**: Clash detection overview with resolution rates
- **issue_trend**: BCF issue trends over time
- **progress_chart**: Construction progress visualization
- **discipline_breakdown**: Elements grouped by discipline
- **recent_activity**: Latest BIM activities feed
- **kpi_card**: Single metric display (customizable)
- **work_package_summary**: Work package statistics
- **model_size_chart**: Model file size comparison
- **clash_heatmap**: Clashes by location/type
- **issue_status_pie**: Issues by status distribution
- **progress_timeline**: Progress over time
- **resolution_rate**: Clash/issue resolution metrics
- **element_count_bar**: Elements by type
- **conversion_status**: Model conversion metrics
- **schedule_variance**: Schedule performance indicators

### 3. Metrics Aggregation
- **Real-time KPIs**: Live metrics from all BIM sources
- **Composite Scores**: Health, quality, collaboration, activity scores
- **Configurable Date Ranges**: Filter metrics by time period
- **Performance Tracking**: Monitor trends over time

### 4. Auto-Refresh
- **Widget-Level Refresh**: Individual refresh intervals per widget
- **Dashboard Refresh**: Refresh all widgets at once
- **Caching**: Efficient data caching with TTL
- **Force Refresh**: Manual refresh capability

## API Reference

### Dashboard Endpoints

#### List Dashboards
```bash
GET /api/v3/bim/dashboards?project_id=123&is_public=true

Query Parameters:
  - project_id: Filter by project
  - user_id: Filter by user
  - is_default: Filter by default status
  - is_public: Filter by public status

Response:
{
  "dashboards": [
    {
      "id": 1,
      "project_id": 123,
      "user_id": 456,
      "name": "Project Overview",
      "description": "Main dashboard",
      "is_default": true,
      "is_public": true,
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T10:00:00Z"
    }
  ]
}
```

#### Show Dashboard
```bash
GET /api/v3/bim/dashboards/1?include_data=true&force_refresh=false

Query Parameters:
  - include_data: Include widget data (default: false)
  - force_refresh: Force data refresh (default: false)

Response:
{
  "id": 1,
  "name": "Project Overview",
  "layout_config": { "cols": 12, "rowHeight": 100 },
  "settings": {},
  "metrics": {
    "total_widgets": 10,
    "last_refresh": "2025-01-15T12:00:00Z",
    "has_stale_data": false
  },
  "widgets": [
    {
      "id": 1,
      "type": "model_count",
      "title": "IFC Models",
      "position": { "x": 0, "y": 0 },
      "size": { "width": 4, "height": 3 },
      "data": { "total": 5, "recent": 2 },
      "last_updated": "2025-01-15T12:00:00Z"
    }
  ]
}
```

#### Create Dashboard
```bash
POST /api/v3/bim/dashboards
{
  "dashboard": {
    "project_id": 123,
    "name": "My Dashboard",
    "description": "Custom dashboard",
    "is_default": false,
    "is_public": false,
    "layout_config": { "cols": 12 }
  }
}
```

#### Clone Dashboard
```bash
POST /api/v3/bim/dashboards/1/clone
{
  "user_id": 456,
  "project_id": 789
}

Note: Creates copy of dashboard with all widgets
```

#### Refresh Dashboard
```bash
POST /api/v3/bim/dashboards/1/refresh

Note: Refreshes all widget caches
```

#### Get Default Dashboard
```bash
GET /api/v3/bim/dashboards/default?project_id=123

Note: Returns or creates default dashboard for project
```

### Widget Endpoints

#### Show Widget
```bash
GET /api/v3/bim/widgets/1?include_data=true

Response:
{
  "id": 1,
  "dashboard_id": 1,
  "widget_type": "clash_summary",
  "title": "Clash Summary",
  "position": { "x": 0, "y": 0 },
  "size": { "width": 4, "height": 3 },
  "config": {},
  "data": {
    "total_clashes": 42,
    "new_count": 15,
    "resolved_count": 20,
    "resolution_rate": 47.62
  },
  "last_updated": "2025-01-15T12:00:00Z"
}
```

#### Create Widget
```bash
POST /api/v3/bim/widgets
{
  "widget": {
    "dashboard_id": 1,
    "widget_type": "model_count",
    "title": "Models",
    "position": { "x": 0, "y": 0 },
    "size": { "width": 4, "height": 3 },
    "config": {},
    "refresh_interval": 300
  }
}
```

#### Update Widget
```bash
PATCH /api/v3/bim/widgets/1
{
  "widget": {
    "title": "Updated Title",
    "size": { "width": 6, "height": 4 }
  }
}
```

#### Refresh Widget
```bash
POST /api/v3/bim/widgets/1/refresh

Note: Forces widget data refresh
```

### Metrics Endpoint

#### Get Project Metrics
```bash
GET /api/v3/bim/metrics?project_id=123&date_range=30&include_sections=models,clashes,progress

Query Parameters:
  - project_id: Project ID (required)
  - date_range: Number of days (default: 30)
  - include_sections: Comma-separated sections to include

Response:
{
  "timestamp": "2025-01-15T12:00:00Z",
  "project_id": 123,
  "date_range": { "from": "...", "to": "..." },
  "models": {
    "total": 5,
    "by_status": { "completed": 4, "processing": 1 },
    "total_size_mb": 250.5,
    "conversion_success_rate": 80.0
  },
  "clashes": {
    "total_clashes": 42,
    "new_clashes": 15,
    "resolved_clashes": 20,
    "resolution_rate": 47.62,
    "by_severity": { "critical": 5, "major": 20, "minor": 17 }
  },
  "progress": {
    "overall_progress": 65.5,
    "total_elements": 500,
    "completed_elements": 327,
    "delayed_count": 12,
    "ahead_count": 5
  },
  "summary": {
    "health_score": 75.5,
    "activity_level": "high",
    "quality_score": 82.3,
    "collaboration_score": 68.9
  }
}
```

## Usage Examples

### Create Custom Dashboard

```ruby
# Create dashboard
dashboard = Bim::Dashboard.create!(
  project: project,
  user: current_user,
  name: 'Executive Dashboard',
  description: 'High-level project overview',
  is_public: true
)

# Add widgets
dashboard.add_widget(
  :model_count,
  position: { x: 0, y: 0 },
  size: { width: 3, height: 3 }
)

dashboard.add_widget(
  :progress_chart,
  position: { x: 3, y: 0 },
  size: { width: 6, height: 4 }
)

dashboard.add_widget(
  :clash_summary,
  position: { x: 9, y: 0 },
  size: { width: 3, height: 3 }
)
```

### Get Metrics for Dashboard

```ruby
service = Bim::Metrics::AggregatorService.new(
  project: project,
  date_range: 30.days.ago..Time.current
)

metrics = service.call

puts "Health Score: #{metrics[:summary][:health_score]}"
puts "Total Clashes: #{metrics[:clashes][:total_clashes]}"
puts "Overall Progress: #{metrics[:progress][:overall_progress]}%"
```

### Clone Dashboard for Another User

```ruby
source_dashboard = Bim::Dashboard.find(1)
cloned = source_dashboard.clone_for(user: new_user)

puts "Cloned: #{cloned.name}"
puts "Widgets: #{cloned.widgets.count}"
```

### Export and Import Dashboard

```ruby
# Export
config = dashboard.export_config
File.write('dashboard_template.json', config.to_json)

# Import
config = JSON.parse(File.read('dashboard_template.json'))
new_dashboard = Bim::Dashboard.import_config(
  config,
  project: project,
  user: current_user
)
```

### Frontend Integration

```typescript
// In your Angular component
<op-bim-dashboard [projectId]="project.id"></op-bim-dashboard>

// Or specify dashboard ID
<op-bim-dashboard
  [projectId]="project.id"
  [dashboardId]="123">
</op-bim-dashboard>
```

## Widget Configuration

### Widget Types and Default Sizes

| Widget Type | Default Size | Description |
|------------|-------------|-------------|
| model_count | 4x3 | Model statistics |
| clash_summary | 4x3 | Clash overview |
| issue_trend | 6x4 | Issue chart |
| progress_chart | 6x4 | Progress visualization |
| discipline_breakdown | 4x3 | Discipline stats |
| recent_activity | 6x5 | Activity feed |
| kpi_card | 3x2 | Single metric |
| work_package_summary | 4x3 | WP statistics |

### Widget Config Options

Each widget type supports custom configuration:

```json
{
  "date_range": { "days": 30 },
  "metric_type": "clashes",
  "chart_type": "bar",
  "filters": {
    "discipline": "Structural",
    "status": "active"
  }
}
```

## Demo Data

Generate comprehensive demo data:

```bash
rails runner modules/bim/db/seeds/dashboard_demo_data.rb
```

Creates:
- 1 default dashboard with 10 widgets
- Full widget coverage (KPIs, charts, trends, activity)
- Realistic grid layout
- Auto-refreshed widget data

## Database Schema

### bim_dashboards

```sql
CREATE TABLE bim_dashboards (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id),
  user_id BIGINT REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_default BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  layout_config JSONB DEFAULT '{}',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_default_per_project UNIQUE (project_id) WHERE is_default = true
);
```

### bim_dashboard_widgets

```sql
CREATE TABLE bim_dashboard_widgets (
  id BIGSERIAL PRIMARY KEY,
  dashboard_id BIGINT NOT NULL REFERENCES bim_dashboards(id),
  widget_type INTEGER NOT NULL,
  title VARCHAR(255),
  description TEXT,
  position JSONB NOT NULL,
  size JSONB NOT NULL,
  config JSONB DEFAULT '{}',
  cached_data JSONB DEFAULT '{}',
  cached_at TIMESTAMP,
  refresh_interval INTEGER,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Performance

- **Widget Caching**: All widget data cached with configurable TTL
- **Lazy Loading**: Widgets load data on-demand
- **Selective Refresh**: Refresh individual widgets or all at once
- **Efficient Queries**: Optimized database queries with proper indexes
- **GIN Indexes**: JSONB columns indexed for fast queries

## Best Practices

1. **Default Dashboard**: Use default dashboard for standard metrics
2. **Widget Placement**: Group related widgets together
3. **Refresh Intervals**: Set appropriate intervals (5-15 minutes)
4. **Date Ranges**: Use 30-day ranges for trends, 7-day for activity
5. **Public Dashboards**: Share standard dashboards with team
6. **Clone Dashboards**: Use templates for consistency
7. **KPI Cards**: Use for critical metrics (top of dashboard)
8. **Charts**: Use for trends and comparisons

## Troubleshooting

**Widgets not loading:**
- Check project has BIM data (models, clashes, etc.)
- Verify widget refresh interval
- Force refresh dashboard

**Stale data:**
- Check cached_at timestamp
- Force widget refresh
- Adjust refresh_interval

**Performance issues:**
- Reduce number of widgets
- Increase refresh intervals
- Use selective metric loading

## Future Enhancements

- PDF/Excel export
- Scheduled reports via email
- Mobile-optimized dashboards
- Custom widget builder
- Dashboard sharing links
- Alerts and notifications
- Historical data comparison
- Advanced filtering

## Related Features

- **Progress Tracking**: Element-level progress data
- **Clash Detection**: Clash metrics and trends
- **Model Comparison**: Model version analytics
- **BCF Issues**: Issue tracking and resolution
- **Work Packages**: Task and deliverable metrics
