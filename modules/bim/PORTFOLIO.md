# Portfolio Analytics & Multi-Project Dashboards

## Overview

The Portfolio Analytics system provides centralized dashboards and cross-project visibility for BIM-enabled projects. It aggregates key performance indicators (KPIs) across multiple projects, enabling executives, PMOs, and BIM managers to monitor portfolio health, identify trends, and compare project performance.

### Key Features

- **Multi-Project Aggregation**: Collect metrics from all active BIM projects
- **Portfolio-Wide KPIs**: Clash resolution rates, issue closure rates, workflow completion, model conversion rates
- **Trend Analysis**: Track metric changes over time with automatic trend detection
- **Project Comparison**: Rank and compare projects by specific metrics
- **Drill-Down Capability**: Navigate from portfolio → project → model → element
- **Status Thresholds**: Automatic classification as good/warning/critical
- **Scheduled Collection**: Nightly automated metric gathering
- **Export & Reporting**: CSV/JSON export for compliance and analysis

## Architecture

### Components

1. **Bim::PortfolioMetric** - Core model storing aggregated metrics
2. **Bim::Services::PortfolioAnalyticsService** - Collects and aggregates metrics
3. **API::V3::Bim::PortfolioController** - REST API endpoints
4. **Bim::PortfolioMetricsCollectorJob** - Scheduled background job
5. **Rake Tasks** - Command-line management tools

### Data Model

```ruby
# bim_portfolio_metrics table
{
  metric_type: 'clash',          # Type of metric
  metric_name: 'resolution_rate', # Specific metric name
  metric_date: Date,              # Date for this metric
  scope: 'portfolio',             # portfolio, project, or discipline
  project_id: Integer,            # Optional project scope

  # Values
  value: Decimal,                 # Current metric value
  previous_value: Decimal,        # Previous value for trend
  change_amount: Decimal,         # Absolute change
  change_percentage: Decimal,     # Percentage change

  # Classification
  status: 'good',                 # good, warning, critical
  trend: 'improving',             # improving, declining, stable
  category: 'quality',            # quality, performance, collaboration, progress

  # Thresholds
  threshold_good: Decimal,        # Value >= this is "good"
  threshold_warning: Decimal,     # Value >= this is "warning", else "critical"

  # Metadata
  unit: 'percentage',             # Unit of measurement
  details: JSONB,                 # Additional details
  breakdown: JSONB,               # Sub-category breakdown
  tags: Array,                    # Searchable tags
  discipline: String,             # Optional discipline scope

  # Collection metadata
  collected_at: DateTime,         # When collected
  collected_by_id: Integer,       # Who collected (User)
  stale: Boolean                  # Whether metric is outdated
}
```

### Metric Types

The system collects six primary metric types:

#### 1. Clash Metrics
- **resolution_rate**: Percentage of clashes resolved
- **avg_resolution_time**: Average days to resolve clashes

#### 2. Issue Metrics
- **closure_rate**: Percentage of BCF issues closed

#### 3. Workflow Metrics
- **completion_rate**: Percentage of workflows completed
- **avg_approval_time**: Average hours for approvals

#### 4. Progress Metrics
- **avg_completion**: Average element completion percentage

#### 5. Audit Metrics
- **daily_activity**: Average actions per day (30-day window)

#### 6. Model Metrics
- **conversion_rate**: Percentage of models successfully converted

### Metric Scopes

Metrics can be collected at three scopes:

1. **Portfolio**: Aggregated across all projects
2. **Project**: Specific to a single project
3. **Discipline**: Specific to a discipline (e.g., Architecture, MEP)

## API Reference

Base URL: `/api/v3/bim/portfolio`

### 1. Portfolio Dashboard

**GET** `/api/v3/bim/portfolio/dashboard`

Returns high-level portfolio summary with key metrics.

**Query Parameters:**
- `date` (optional): Date for metrics (default: today)
- `project_ids` (optional): Comma-separated project IDs to include

**Response:**
```json
{
  "_type": "PortfolioDashboard",
  "date": "2025-11-10",
  "generated_at": "2025-11-10T12:00:00Z",
  "summary": {
    "total_metrics": 120,
    "by_category": {
      "quality": 40,
      "performance": 30,
      "collaboration": 25,
      "progress": 25
    },
    "by_status": {
      "good": 80,
      "warning": 25,
      "critical": 15
    },
    "critical_count": 15
  },
  "metrics": {
    "quality": [...],
    "performance": [...],
    "collaboration": [...],
    "progress": [...]
  },
  "status_overview": {
    "good": 80,
    "warning": 25,
    "critical": 15
  },
  "trends": {
    "improving": 60,
    "declining": 20,
    "stable": 40
  },
  "project_count": 15
}
```

### 2. List Metrics

**GET** `/api/v3/bim/portfolio/metrics`

Returns detailed metrics with filtering and pagination.

**Query Parameters:**
- `date` (optional): Specific date (default: today)
- `start_date` (optional): Start of date range
- `scope` (optional): Filter by scope (portfolio, project, discipline)
- `metric_type` (optional): Filter by type (clash, issue, workflow, progress, audit, model)
- `metric_name` (optional): Filter by name
- `category` (optional): Filter by category (quality, performance, collaboration, progress)
- `status` (optional): Filter by status (good, warning, critical)
- `project_id` (optional): Filter by project
- `include_stale` (optional): Include stale metrics (default: false)
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 50, max: 200)

**Response:**
```json
{
  "_type": "PortfolioMetricsCollection",
  "total": 120,
  "count": 50,
  "page": 1,
  "per_page": 50,
  "_embedded": {
    "metrics": [
      {
        "_type": "PortfolioMetric",
        "id": 123,
        "metric_type": "clash",
        "metric_name": "resolution_rate",
        "metric_date": "2025-11-10",
        "scope": "portfolio",
        "project": null,
        "value": 85.5,
        "formatted_value": "85.5%",
        "unit": "percentage",
        "category": "quality",
        "status": "good",
        "trend": "improving",
        "change": {
          "previous_value": 82.0,
          "change_amount": 3.5,
          "change_percentage": 4.27
        },
        "thresholds": {
          "good": 80.0,
          "warning": 60.0
        },
        "details": {},
        "breakdown": {},
        "tags": [],
        "collected_at": "2025-11-10T02:00:00Z",
        "collected_by": { "id": 1, "name": "System" },
        "stale": false
      }
    ]
  }
}
```

### 3. Time Series

**GET** `/api/v3/bim/portfolio/time_series`

Returns time series data for trending charts.

**Query Parameters:**
- `metric_type` (required): Type of metric
- `metric_name` (required): Name of metric
- `start_date` (optional): Start date (default: 30 days ago)
- `end_date` (optional): End date (default: today)
- `scope` (optional): Scope filter (default: portfolio)
- `project_id` (optional): Project filter

**Response:**
```json
{
  "_type": "PortfolioTimeSeries",
  "metric_type": "clash",
  "metric_name": "resolution_rate",
  "scope": "portfolio",
  "start_date": "2025-10-10",
  "end_date": "2025-11-10",
  "data_points": 31,
  "series": [
    {
      "date": "2025-10-10",
      "value": 78.5,
      "trend": "improving",
      "change_percentage": 2.3
    },
    {
      "date": "2025-10-11",
      "value": 79.2,
      "trend": "improving",
      "change_percentage": 0.89
    }
  ]
}
```

### 4. Project Comparison

**GET** `/api/v3/bim/portfolio/comparison`

Compare metrics across projects.

**Query Parameters:**
- `metric_type` (required): Type of metric
- `metric_name` (required): Name of metric
- `date` (optional): Date for comparison (default: today)
- `project_ids` (optional): Comma-separated project IDs
- `top_limit` (optional): Number of top performers (default: 5)
- `bottom_limit` (optional): Number of bottom performers (default: 5)

**Response:**
```json
{
  "_type": "PortfolioComparison",
  "metric_type": "clash",
  "metric_name": "resolution_rate",
  "date": "2025-11-10",
  "projects_compared": 15,
  "comparison": [
    {
      "project_id": 1,
      "project_name": "Project Alpha",
      "value": 92.5,
      "formatted_value": "92.5%",
      "status": "good",
      "trend": "improving"
    }
  ],
  "rankings": {
    "top_performers": [...],
    "bottom_performers": [...]
  }
}
```

### 5. Category Breakdown

**GET** `/api/v3/bim/portfolio/breakdown`

Get detailed breakdown for a specific category.

**Query Parameters:**
- `category` (required): Category name (quality, performance, collaboration, progress)
- `scope` (optional): Scope filter (default: portfolio)
- `project_id` (optional): Project filter
- `date` (optional): Date (default: today)

**Response:**
```json
{
  "_type": "PortfolioBreakdown",
  "category": "quality",
  "scope": "portfolio",
  "date": "2025-11-10",
  "breakdown": {
    "clash_resolution_rate": 85.5,
    "model_conversion_rate": 98.2
  }
}
```

### 6. Collect Metrics

**POST** `/api/v3/bim/portfolio/collect`

Manually trigger metric collection. Requires admin access.

**Body Parameters:**
- `date` (optional): Date to collect (default: today)
- `project_ids` (optional): Array of project IDs

**Response:**
```json
{
  "_type": "PortfolioCollectionResult",
  "date": "2025-11-10",
  "collected_at": "2025-11-10T12:00:00Z",
  "projects_processed": 15,
  "metrics_collected": 120,
  "errors": [],
  "status": "success"
}
```

### 7. Export Metrics

**GET** `/api/v3/bim/portfolio/export`

Export portfolio data to CSV or JSON.

**Query Parameters:**
- `format` (optional): Format (csv or json, default: csv)
- `start_date` (optional): Start date (default: 30 days ago)
- `end_date` (optional): End date (default: today)
- `scope` (optional): Scope filter
- `category` (optional): Category filter

**Response:**
Downloads file with name `portfolio_metrics_[start]_[end].[format]`

### 8. Statistics

**GET** `/api/v3/bim/portfolio/stats`

Get portfolio statistics.

**Response:**
```json
{
  "_type": "PortfolioStatistics",
  "total_metrics": 3600,
  "fresh_metrics": 120,
  "stale_metrics": 3480,
  "by_scope": {
    "portfolio": 40,
    "project": 80
  },
  "by_category": {
    "quality": 40,
    "performance": 30,
    "collaboration": 25,
    "progress": 25
  },
  "by_status": {
    "good": 80,
    "warning": 25,
    "critical": 15
  },
  "by_trend": {
    "improving": 60,
    "declining": 20,
    "stable": 40
  },
  "latest_collection": "2025-11-10T02:00:00Z",
  "oldest_metric": "2025-08-10",
  "newest_metric": "2025-11-10"
}
```

## Rake Tasks

### Collect Metrics

Collect portfolio metrics for the current date or a specific date.

```bash
# Collect for today across all active projects
rake bim:portfolio:collect

# Collect for specific date
rake bim:portfolio:collect DATE=2025-11-01

# Collect for specific projects only
rake bim:portfolio:collect PROJECT_IDS=1,2,3
```

### Display Statistics

Show portfolio statistics and summary.

```bash
rake bim:portfolio:stats
```

Output includes:
- Total, fresh, and stale metrics
- Breakdown by scope, category, status, trend
- Top 5 critical metrics
- Date range coverage
- Latest collection timestamp

### Dashboard Summary

Display high-level portfolio dashboard in console.

```bash
# Today's dashboard
rake bim:portfolio:dashboard

# Specific date
rake bim:portfolio:dashboard DATE=2025-11-01
```

### Compare Projects

Compare projects by a specific metric.

```bash
rake bim:portfolio:compare METRIC_TYPE=clash METRIC_NAME=resolution_rate

# With specific date
rake bim:portfolio:compare METRIC_TYPE=issue METRIC_NAME=closure_rate DATE=2025-11-01
```

### Time Series

Show time series for a specific metric.

```bash
# Portfolio-wide time series
rake bim:portfolio:time_series METRIC_TYPE=clash METRIC_NAME=resolution_rate

# With custom date range
rake bim:portfolio:time_series \
  METRIC_TYPE=workflow \
  METRIC_NAME=completion_rate \
  START_DATE=2025-10-01 \
  END_DATE=2025-11-01

# For specific project
rake bim:portfolio:time_series \
  METRIC_TYPE=progress \
  METRIC_NAME=avg_completion \
  SCOPE=project \
  PROJECT_ID=1
```

### Export Metrics

Export portfolio metrics to CSV or JSON.

```bash
# Export to CSV (default)
rake bim:portfolio:export

# Export to JSON
rake bim:portfolio:export FORMAT=json OUTPUT=metrics.json

# Export with filters
rake bim:portfolio:export \
  FORMAT=csv \
  START_DATE=2025-10-01 \
  END_DATE=2025-11-01 \
  SCOPE=portfolio \
  CATEGORY=quality
```

### Clean Up Stale Metrics

Mark old metrics as stale or delete them.

```bash
# Mark metrics older than 90 days as stale
rake bim:portfolio:cleanup

# Mark metrics older than specific date
rake bim:portfolio:cleanup OLDER_THAN="2025-08-01"

# Delete stale metrics
rake bim:portfolio:cleanup DELETE=true
```

### Project Rankings

Show top and bottom performing projects for a metric.

```bash
# Default: top and bottom 5
rake bim:portfolio:rankings METRIC_TYPE=clash METRIC_NAME=resolution_rate

# Custom limit
rake bim:portfolio:rankings \
  METRIC_TYPE=workflow \
  METRIC_NAME=completion_rate \
  LIMIT=10 \
  DATE=2025-11-01
```

### Schedule Information

Display scheduling information for automated collection.

```bash
rake bim:portfolio:schedule
```

## Scheduled Collection

### Background Job

The `Bim::PortfolioMetricsCollectorJob` runs on a schedule to collect metrics automatically.

```ruby
# Manual execution
Bim::PortfolioMetricsCollectorJob.perform_later

# With options
Bim::PortfolioMetricsCollectorJob.perform_later(
  date: Date.current,
  project_ids: [1, 2, 3],
  user_id: 1
)
```

### Scheduling Options

#### 1. Cron

Add to your crontab:

```cron
0 2 * * * cd /path/to/app && bin/rake bim:portfolio:collect RAILS_ENV=production
```

#### 2. Whenever Gem

In `config/schedule.rb`:

```ruby
every 1.day, at: '2:00 am' do
  rake 'bim:portfolio:collect'
end
```

#### 3. Sidekiq Scheduler

In `config/sidekiq.yml`:

```yaml
:schedule:
  portfolio_metrics_collection:
    cron: '0 2 * * *'
    class: Bim::PortfolioMetricsCollectorJob
    queue: default
```

**Recommendation**: Run daily at 2:00 AM to minimize impact on system performance.

## Trend Detection

The system automatically detects trends by comparing current and previous values:

### Calculation Logic

```ruby
# Change percentage
change_percentage = ((value - previous_value) / previous_value) * 100

# Trend classification
if change_percentage.abs < 5
  trend = 'stable'
elsif change_percentage > 0
  trend = 'improving'
else
  trend = 'declining'
end
```

### Interpretation

- **Improving**: Value increased by more than 5%
- **Declining**: Value decreased by more than 5%
- **Stable**: Change is less than 5% in either direction

Note: For metrics where lower is better (e.g., avg_resolution_time), the interpretation should be inverted in your UI.

## Status Thresholds

Each metric has configurable thresholds for automatic status classification:

### Default Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Clash Resolution Rate | ≥ 80% | ≥ 60% | < 60% |
| Issue Closure Rate | ≥ 75% | ≥ 50% | < 50% |
| Workflow Completion | ≥ 80% | ≥ 60% | < 60% |
| Progress Completion | ≥ 75% | ≥ 50% | < 50% |
| Model Conversion Rate | ≥ 95% | ≥ 85% | < 85% |

### Custom Thresholds

Thresholds can be customized when storing metrics:

```ruby
store_metric(
  metric_type: 'clash',
  metric_name: 'resolution_rate',
  value: 75.0,
  threshold_good: 85.0,    # Custom: require 85% for "good"
  threshold_warning: 70.0  # Custom: require 70% for "warning"
)
```

## Service Usage

### Basic Collection

```ruby
# Collect all metrics for today across all active projects
analytics = Bim::Services::PortfolioAnalyticsService.new
results = analytics.collect_all_metrics(user: current_user)

# Results hash
{
  date: Date.current,
  collected_at: Time.current,
  metrics_collected: 120,
  projects_processed: 15,
  errors: []
}
```

### Filtered Collection

```ruby
# Collect for specific projects
projects = Project.where(id: [1, 2, 3])
analytics = Bim::Services::PortfolioAnalyticsService.new(
  date: Date.yesterday,
  projects: projects
)
results = analytics.collect_all_metrics(user: current_user)
```

### Portfolio-Wide Only

```ruby
analytics = Bim::Services::PortfolioAnalyticsService.new
analytics.collect_portfolio_metrics(user: current_user)
```

### Project-Specific Only

```ruby
analytics = Bim::Services::PortfolioAnalyticsService.new
project = Project.find(1)
analytics.collect_project_metrics(project, user: current_user)
```

## Model Queries

### Dashboard Data

```ruby
# Portfolio-wide dashboard for today
summary = Bim::PortfolioMetric.dashboard_summary(
  scope: 'portfolio',
  date: Date.current
)

# Project-specific dashboard
summary = Bim::PortfolioMetric.dashboard_summary(
  scope: 'project',
  project_id: 1,
  date: Date.current
)
```

### Time Series

```ruby
# Get 30-day time series
series = Bim::PortfolioMetric.time_series(
  'clash',
  'resolution_rate',
  scope: 'portfolio',
  start_date: 30.days.ago.to_date,
  end_date: Date.current
)

# Returns array of hashes:
# [
#   { date: Date, value: Float, trend: String, change_percentage: Float },
#   ...
# ]
```

### Project Comparison

```ruby
# Compare all projects by clash resolution rate
comparison = Bim::PortfolioMetric.project_comparison(
  'clash',
  'resolution_rate',
  date: Date.current
)

# Returns array of hashes:
# [
#   {
#     project_id: Integer,
#     project_name: String,
#     value: Float,
#     formatted_value: String,
#     status: String,
#     trend: String
#   },
#   ...
# ]
```

### Rankings

```ruby
# Top 5 performers
top = Bim::PortfolioMetric.top_performers(
  'workflow',
  'completion_rate',
  date: Date.current,
  limit: 5
)

# Bottom 5 performers
bottom = Bim::PortfolioMetric.bottom_performers(
  'workflow',
  'completion_rate',
  date: Date.current,
  limit: 5
)
```

### Filtering

```ruby
# Fresh metrics only
metrics = Bim::PortfolioMetric.fresh

# By category
metrics = Bim::PortfolioMetric.by_category('quality')

# By status
critical = Bim::PortfolioMetric.critical_status

# By trend
improving = Bim::PortfolioMetric.improving

# Combined filters
metrics = Bim::PortfolioMetric
  .portfolio_wide
  .by_category('performance')
  .critical_status
  .for_date(Date.current)
```

## Access Control

### Authorization

Portfolio access requires one of:
- Admin role
- `view_ifc_models` permission in any project

Export and manual collection require:
- Admin role, OR
- `manage_ifc_models` permission in the relevant project

### API Controller Authorization

```ruby
# View access
before_action :authorize_portfolio_access

def authorize_portfolio_access
  unless current_user.admin? || current_user.allowed_in_any_project?(:view_ifc_models)
    render json: { error: 'Unauthorized' }, status: :forbidden
  end
end

# Export access
def authorize_export
  unless current_user.admin? || current_user.allowed_in_project?(:manage_ifc_models, @project)
    render json: { error: 'Export permission required' }, status: :forbidden
  end
end
```

## Performance Considerations

### Optimization Strategies

1. **Scheduled Collection**: Run nightly to pre-calculate metrics
2. **Stale Metrics**: Mark old metrics as stale to exclude from queries by default
3. **Indexes**: Comprehensive indexes on frequently queried columns
4. **JSONB**: Use JSONB fields for flexible details and breakdown data
5. **Caching**: Consider caching dashboard summaries for high-traffic scenarios

### Database Indexes

The migration creates these indexes:

```ruby
# Lookups
add_index :bim_portfolio_metrics, [:metric_type, :metric_name]
add_index :bim_portfolio_metrics, :metric_date
add_index :bim_portfolio_metrics, :project_id
add_index :bim_portfolio_metrics, :scope
add_index :bim_portfolio_metrics, :category
add_index :bim_portfolio_metrics, :status
add_index :bim_portfolio_metrics, :collected_at
add_index :bim_portfolio_metrics, :stale

# Uniqueness (one metric per type/name/date/scope)
add_index :bim_portfolio_metrics,
  [:metric_type, :metric_name, :metric_date, :project_id, :scope],
  unique: true,
  name: 'index_portfolio_metrics_uniqueness'

# JSONB queries
add_index :bim_portfolio_metrics, :details, using: :gin
add_index :bim_portfolio_metrics, :breakdown, using: :gin
```

### Query Performance

For large portfolios (100+ projects):

```ruby
# Good: Use scopes and indexes
Bim::PortfolioMetric.portfolio_wide.fresh.by_category('quality')

# Bad: Load all then filter in Ruby
Bim::PortfolioMetric.all.select { |m| m.category == 'quality' && !m.stale }

# Good: Use time series method (optimized query)
Bim::PortfolioMetric.time_series('clash', 'resolution_rate', ...)

# Bad: Load all dates then iterate
dates.map { |date| Bim::PortfolioMetric.for_date(date).first }
```

## Integration with Audit Logging

Portfolio analytics integrates with the audit logging system:

### Logged Actions

1. **portfolio_metrics_collected**: When metrics are collected (scheduled or manual)
2. **export_data**: When portfolio data is exported

### Example Audit Log

```ruby
Bim::AuditLog.log(
  user: current_user,
  action: :portfolio_metrics_collected,
  details: {
    date: Date.current,
    projects_processed: 15,
    metrics_collected: 120,
    errors_count: 0,
    scheduled: true
  },
  severity: :info,
  tags: ['portfolio', 'metrics', 'scheduled']
)
```

### Query Audit Logs

```ruby
# Find all portfolio metric collections
logs = Bim::AuditLog.for_action(:portfolio_metrics_collected)

# Find exports
logs = Bim::AuditLog.for_action(:export_data)
                    .where("details->>'export_type' = ?", 'portfolio_metrics')
```

## Troubleshooting

### No Metrics Collected

**Problem**: `collect_all_metrics` returns 0 metrics

**Solutions**:
1. Check that projects have BIM data (models, clashes, issues, etc.)
2. Verify projects are marked as active
3. Check for errors in the results hash
4. Review Rails logs for collection errors

### Stale Metrics

**Problem**: Dashboard shows outdated data

**Solutions**:
1. Run `rake bim:portfolio:collect` to refresh
2. Check that scheduled job is running
3. Verify job scheduler (cron, whenever, sidekiq-scheduler)
4. Check for collection errors in audit logs

### Performance Issues

**Problem**: Dashboard loads slowly

**Solutions**:
1. Ensure scheduled collection is running nightly
2. Clean up old stale metrics with `rake bim:portfolio:cleanup`
3. Add database indexes if custom queries
4. Consider caching dashboard responses
5. Limit date ranges in queries

### Missing Projects in Comparison

**Problem**: Some projects don't appear in comparison

**Solutions**:
1. Verify projects are active (`Project.where(active: true)`)
2. Check that projects have data for the specific metric
3. Confirm metrics were collected for those projects (check results[:errors])
4. Verify project IDs if using filtered collection

## Best Practices

### 1. Scheduled Collection

- **Frequency**: Daily collection is recommended
- **Timing**: Run at 2:00 AM (low traffic period)
- **Error Handling**: Monitor audit logs for collection failures
- **Notifications**: Set up alerts for admins if errors occur

### 2. Metric Retention

- **Fresh Metrics**: Keep last 30-90 days readily accessible
- **Historical Data**: Mark older metrics as stale but retain for long-term analysis
- **Cleanup**: Periodically delete metrics older than 2 years if not needed

### 3. Custom Metrics

To add custom metrics:

```ruby
# In PortfolioAnalyticsService
def collect_custom_metrics_portfolio(user:)
  # Calculate your metric
  custom_value = calculate_custom_metric

  store_metric(
    metric_type: 'custom',
    metric_name: 'my_metric',
    scope: 'portfolio',
    value: custom_value,
    unit: 'count',
    category: 'quality',
    threshold_good: 100,
    threshold_warning: 75,
    user: user
  )
end

# Call from collect_portfolio_metrics
def collect_portfolio_metrics(user: nil)
  # ... existing metrics ...
  collect_custom_metrics_portfolio(user: user)
end
```

### 4. Dashboard Design

- **Focus on Trends**: Show trend indicators (↑↓→) prominently
- **Status Colors**: Use color coding for good/warning/critical
- **Drill-Down**: Provide links from portfolio → project views
- **Time Ranges**: Offer 7-day, 30-day, 90-day views
- **Comparison**: Show project rankings and comparisons
- **Export**: Provide easy export for executive reporting

### 5. Monitoring

Monitor these indicators:

- **Collection Success Rate**: Should be 100%
- **Processing Time**: Should complete within 5 minutes
- **Critical Metrics Count**: Alert if increasing
- **Declining Trends**: Alert if multiple key metrics declining

## Examples

### Example 1: Portfolio Health Dashboard

```ruby
# Controller action
def portfolio_health
  date = Date.current

  # Get overall status distribution
  status_dist = Bim::PortfolioMetric.portfolio_wide
                                    .for_date(date)
                                    .group(:status)
                                    .count

  # Get key metrics
  clash_rate = Bim::PortfolioMetric.portfolio_wide
                                   .for_metric_type('clash')
                                   .for_metric_name('resolution_rate')
                                   .for_date(date)
                                   .first

  issue_rate = Bim::PortfolioMetric.portfolio_wide
                                   .for_metric_type('issue')
                                   .for_metric_name('closure_rate')
                                   .for_date(date)
                                   .first

  # Get trending data (30 days)
  clash_trend = Bim::PortfolioMetric.time_series(
    'clash',
    'resolution_rate',
    start_date: 30.days.ago.to_date,
    end_date: date
  )

  render json: {
    status_overview: status_dist,
    key_metrics: {
      clash_resolution: clash_rate,
      issue_closure: issue_rate
    },
    trends: {
      clash_resolution: clash_trend
    }
  }
end
```

### Example 2: Project Performance Comparison

```ruby
# Compare all projects by workflow completion
comparison = Bim::PortfolioMetric.project_comparison(
  'workflow',
  'completion_rate',
  date: Date.current
)

# Sort by value (best to worst)
sorted = comparison.sort_by { |p| -p[:value].to_f }

# Display
sorted.each_with_index do |project, index|
  puts "#{index + 1}. #{project[:project_name]}: #{project[:formatted_value]} [#{project[:status]}]"
end
```

### Example 3: Alert on Critical Metrics

```ruby
# Find all critical metrics in the portfolio
critical = Bim::PortfolioMetric.portfolio_wide
                               .for_date(Date.current)
                               .critical_status

if critical.any?
  # Send notification to admins
  AdminMailer.critical_metrics_alert(
    metrics: critical,
    date: Date.current
  ).deliver_later
end
```

### Example 4: Historical Analysis

```ruby
# Analyze clash resolution rate over last 90 days
series = Bim::PortfolioMetric.time_series(
  'clash',
  'resolution_rate',
  start_date: 90.days.ago.to_date,
  end_date: Date.current
)

values = series.map { |point| point[:value] }

analysis = {
  average: values.sum / values.size,
  minimum: values.min,
  maximum: values.max,
  trend: series.last[:trend],
  improvement: values.last - values.first
}
```

## Frontend Integration

### Dashboard Component Example

```vue
<template>
  <div class="portfolio-dashboard">
    <h1>Portfolio Overview</h1>

    <!-- Status Overview -->
    <div class="status-cards">
      <StatusCard
        v-for="status in ['good', 'warning', 'critical']"
        :key="status"
        :status="status"
        :count="statusCounts[status]"
      />
    </div>

    <!-- Key Metrics -->
    <div class="key-metrics">
      <MetricCard
        v-for="metric in keyMetrics"
        :key="metric.id"
        :metric="metric"
        @click="drillDown(metric)"
      />
    </div>

    <!-- Trend Chart -->
    <TrendChart :series="trendData" />

    <!-- Project Comparison -->
    <ProjectComparison :data="comparisonData" />
  </div>
</template>

<script>
export default {
  data() {
    return {
      dashboard: null,
      trendData: [],
      comparisonData: []
    }
  },

  async mounted() {
    await this.loadDashboard()
    await this.loadTrends()
    await this.loadComparison()
  },

  methods: {
    async loadDashboard() {
      const response = await fetch('/api/v3/bim/portfolio/dashboard')
      this.dashboard = await response.json()
    },

    async loadTrends() {
      const response = await fetch(
        '/api/v3/bim/portfolio/time_series?' +
        'metric_type=clash&metric_name=resolution_rate'
      )
      const data = await response.json()
      this.trendData = data.series
    },

    async loadComparison() {
      const response = await fetch(
        '/api/v3/bim/portfolio/comparison?' +
        'metric_type=workflow&metric_name=completion_rate'
      )
      const data = await response.json()
      this.comparisonData = data.comparison
    },

    drillDown(metric) {
      // Navigate to project-specific view
      this.$router.push({
        name: 'project-metrics',
        params: { projectId: metric.project_id }
      })
    }
  }
}
</script>
```

## Migration Path

### From Existing Dashboards

If you have existing project-specific dashboards:

1. **Install**: Run the migration to create `bim_portfolio_metrics`
2. **Initial Collection**: Run `rake bim:portfolio:collect` to populate data
3. **Schedule**: Set up nightly collection job
4. **Update UI**: Add portfolio dashboard views
5. **Permissions**: Verify PMO/executive users have access

### From Manual Reporting

If you currently generate reports manually:

1. **Map Metrics**: Identify which manual metrics map to portfolio metrics
2. **Custom Metrics**: Add custom metric collection for any gaps
3. **Export Templates**: Use portfolio export to replace manual data gathering
4. **Automate**: Schedule reports to generate automatically
5. **Training**: Train users on self-service dashboard

## Support and Maintenance

### Regular Maintenance Tasks

**Daily**:
- Verify scheduled collection completed successfully
- Monitor for critical metrics

**Weekly**:
- Review error logs from collections
- Check for declining trends in key metrics

**Monthly**:
- Clean up stale metrics older than 90 days
- Review and adjust thresholds if needed
- Analyze long-term trends

**Quarterly**:
- Review custom metrics for relevance
- Optimize queries and indexes if performance degrades
- Update documentation for any customizations

### Logging and Debugging

Enable detailed logging:

```ruby
# In production.rb or development.rb
config.log_level = :info

# Check logs
tail -f log/production.log | grep "Portfolio"

# Or use audit logs
Bim::AuditLog.for_action(:portfolio_metrics_collected)
            .recent
            .each do |log|
  puts "#{log.created_at}: #{log.details}"
end
```

## Related Documentation

- [Audit Logging (AUDIT.md)](./AUDIT.md) - Data provenance and audit trails
- [Workflow Automation (WORKFLOWS.md)](./WORKFLOWS.md) - Workflow metrics source
- [Clash Detection (CLASHES.md)](./CLASHES.md) - Clash metrics source
- [Progress Tracking (PROGRESS.md)](./PROGRESS.md) - Progress metrics source

---

**Version**: 1.0
**Last Updated**: 2025-11-10
**Slice**: V9.4 - Portfolio Dashboards & Multi-Project Analytics
