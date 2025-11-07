# Slice 8: BIM Dashboards & Reporting - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 8
**Dependencies:**
- Slice 3 (Linking) - for work package → element associations
- Slice 4 (Clash Detection) - for clash metrics
- Slice 9 (Progress Tracking) - for progress KPIs

---

## Current State Analysis

### Existing Capabilities (Community Edition)
✅ **Work Package Dashboards**: General project dashboards
❌ **No BIM-specific dashboards**

---

## Enterprise Enhancement Goals

### 1. BIM KPI Dashboards
- **Model Metrics**: Element counts, model size, conversion status
- **Clash Metrics**: Active clashes by discipline, resolution rate
- **Issue Tracking**: Open BCF issues, avg resolution time
- **Progress Metrics**: Elements completed vs planned
- **Quality Metrics**: RFI count, change order volume

### 2. Visual Reports
- **Charts**: Bar, pie, line charts for trends
- **Heatmaps**: Issues by building zone
- **3D Visualizations**: Color-coded progress in viewer
- **Timelines**: Progress over time

### 3. Configurable Widgets
- **Widget Library**: Reusable dashboard components
- **Drag-and-Drop**: Customize dashboard layout
- **Filters**: Date range, discipline, building level
- **Export**: PDF/Excel reports

---

## Proposed Architecture

### Layer 1: Metrics Aggregation

```ruby
# New: modules/bim/app/services/bim/metrics/aggregator_service.rb
class Bim::Metrics::AggregatorService
  def initialize(project, date_range: nil)
    @project = project
    @date_range = date_range || (30.days.ago..Time.current)
  end

  def call
    {
      models: model_metrics,
      clashes: clash_metrics,
      issues: issue_metrics,
      progress: progress_metrics,
      work_packages: work_package_metrics
    }
  end

  private

  def model_metrics
    models = @project.ifc_models.where(created_at: @date_range)

    {
      total_models: models.count,
      by_status: models.group(:conversion_status).count,
      total_size: models.sum(:file_size),
      avg_conversion_time: models.average(:conversion_duration)
    }
  end

  def clash_metrics
    tests = Bim::ClashTest.where(project: @project)
    clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: @project.id })

    {
      total_tests: tests.count,
      total_clashes: clashes.count,
      by_status: clashes.group(:status).count,
      by_discipline: clashes.group(:element1_type, :element2_type).count,
      resolution_rate: calculate_resolution_rate(clashes)
    }
  end

  def issue_metrics
    bcf_issues = Bim::Bcf::Issue.joins(work_package: :project)
                                 .where(projects: { id: @project.id })
                                 .where(created_at: @date_range)

    {
      total_issues: bcf_issues.count,
      open_issues: bcf_issues.joins(:work_package).where(work_packages: { status_id: Status.open.ids }).count,
      avg_resolution_time: calculate_avg_resolution_time(bcf_issues),
      by_priority: bcf_issues.joins(:work_package).group('work_packages.priority_id').count
    }
  end

  def progress_metrics
    # Implemented in Slice 9
    {}
  end

  def work_package_metrics
    wps = @project.work_packages.where(created_at: @date_range)

    {
      total: wps.count,
      with_bim_links: wps.joins(:element_links).distinct.count,
      by_type: wps.group(:type_id).count
    }
  end

  def calculate_resolution_rate(clashes)
    total = clashes.count
    resolved = clashes.where(status: [:resolved, :closed]).count
    return 0 if total.zero?

    (resolved.to_f / total * 100).round(2)
  end

  def calculate_avg_resolution_time(issues)
    # Time from created_at to status = closed
    # Return in hours
  end
end
```

### Layer 2: Dashboard Configuration

```ruby
# New: modules/bim/app/models/bim/dashboard.rb
class Bim::Dashboard < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :dashboard_widgets, class_name: 'Bim::DashboardWidget', dependent: :destroy

  def render_data
    dashboard_widgets.map do |widget|
      {
        id: widget.id,
        type: widget.widget_type,
        position: widget.position,
        size: widget.size,
        config: widget.config,
        data: widget.fetch_data
      }
    end
  end
end

# New: modules/bim/app/models/bim/dashboard_widget.rb
class Bim::DashboardWidget < ApplicationRecord
  belongs_to :dashboard, class_name: 'Bim::Dashboard'

  enum widget_type: {
    model_count: 0,
    clash_summary: 1,
    issue_trend: 2,
    progress_chart: 3,
    discipline_breakdown: 4,
    recent_activity: 5,
    kpi_card: 6
  }

  # position: { x: 0, y: 0 }
  # size: { width: 4, height: 3 } (grid units)
  # config: widget-specific settings

  def fetch_data
    case widget_type
    when 'clash_summary'
      fetch_clash_data
    when 'issue_trend'
      fetch_issue_trend_data
    # ... other types
    end
  end

  private

  def fetch_clash_data
    project = dashboard.project
    clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })

    {
      total: clashes.count,
      new: clashes.where(status: :new).count,
      resolved: clashes.where(status: :resolved).count,
      by_discipline: clashes.group(:element1_type).count
    }
  end
end
```

### Layer 3: Database Schema

```sql
-- Dashboards
CREATE TABLE bim_dashboards (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  is_default BOOLEAN DEFAULT false,
  layout JSONB DEFAULT '[]'::jsonb, -- Grid layout config
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Dashboard widgets
CREATE TABLE bim_dashboard_widgets (
  id BIGSERIAL PRIMARY KEY,
  dashboard_id BIGINT NOT NULL REFERENCES bim_dashboards(id) ON DELETE CASCADE,
  widget_type INTEGER NOT NULL,
  position JSONB NOT NULL, -- {x, y}
  size JSONB NOT NULL, -- {width, height}
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_widgets_dashboard ON bim_dashboard_widgets(dashboard_id);
```

### Layer 4: Frontend

```typescript
// bim-dashboard.component.ts
@Component({
  selector: 'op-bim-dashboard',
  template: `
    <gridster [options]="gridsterOptions">
      <gridster-item *ngFor="let widget of widgets"
                     [item]="widget">
        <op-dashboard-widget
          [type]="widget.type"
          [config]="widget.config"
          [data]="widget.data">
        </op-dashboard-widget>
      </gridster-item>
    </gridster>

    <button (click)="addWidget()">Add Widget</button>
    <button (click)="exportPDF()">Export PDF</button>
  `
})
export class BimDashboardComponent {
  widgets: DashboardWidget[] = [];

  ngOnInit() {
    this.loadDashboard();
  }

  loadDashboard() {
    this.dashboardService.get(this.dashboardId).subscribe(dashboard => {
      this.widgets = dashboard.widgets;
    });
  }

  addWidget() {
    // Open widget selector dialog
  }

  exportPDF() {
    this.dashboardService.exportPDF(this.dashboardId).subscribe(pdf => {
      // Download PDF
    });
  }
}
```

---

## Demo Deliverables

**MVP Demo:**
1. Default BIM dashboard with 6 widgets
2. Clash summary widget showing 15 active clashes
3. Issue trend chart (last 30 days)
4. Progress gauge (65% complete)
5. Export dashboard to PDF

---

**Deliberation Complete** ✅
**Estimated LOC:** ~1,200 (Ruby: 700, TypeScript: 500)
**Estimated Duration:** 2 weeks
**Risk Level:** Low-Medium
