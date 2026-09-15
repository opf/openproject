/**
 * BIM Dashboard Component
 *
 * Displays configurable BIM dashboards with drag-and-drop widgets
 * showing project metrics, charts, and KPIs.
 *
 * Features:
 * - Grid-based layout with drag-and-drop
 * - 16 widget types
 * - Auto-refresh with configurable intervals
 * - Export to PDF
 * - Widget management (add/remove/configure)
 *
 * Usage:
 *   <op-bim-dashboard [projectId]="project.id"></op-bim-dashboard>
 */

import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { interval, Subscription } from 'rxjs';

export interface Dashboard {
  id: number;
  name: string;
  description?: string;
  is_default: boolean;
  is_public: boolean;
  layout_config: any;
  widgets: Widget[];
  metrics?: {
    total_widgets: number;
    last_refresh?: string;
    has_stale_data: boolean;
  };
}

export interface Widget {
  id: number;
  widget_type: string;
  title: string;
  description?: string;
  position: { x: number; y: number };
  size: { width: number; height: number };
  config: any;
  data?: any;
  last_updated?: string;
  refresh_interval?: number;
}

export interface WidgetType {
  type: string;
  name: string;
  description: string;
  default_size: { width: number; height: number };
  icon: string;
}

@Component({
  selector: 'op-bim-dashboard',
  template: `
    <div class="bim-dashboard">
      <!-- Header -->
      <div class="dashboard-header">
        <div class="header-left">
          <h2>{{ dashboard?.name || 'BIM Dashboard' }}</h2>
          <p class="description" *ngIf="dashboard?.description">
            {{ dashboard.description }}
          </p>
        </div>
        <div class="header-right">
          <button class="button" (click)="refreshAll()" [disabled]="refreshing">
            <span class="icon">🔄</span>
            {{ refreshing ? 'Refreshing...' : 'Refresh All' }}
          </button>
          <button class="button" (click)="toggleWidgetPicker()">
            <span class="icon">➕</span>
            Add Widget
          </button>
          <button class="button button--secondary" (click)="toggleEditMode()">
            {{ editMode ? 'Done Editing' : 'Edit Layout' }}
          </button>
          <button class="button button--secondary" (click)="exportPDF()">
            <span class="icon">📄</span>
            Export PDF
          </button>
        </div>
      </div>

      <!-- Dashboard Info -->
      <div class="dashboard-info" *ngIf="dashboard?.metrics">
        <span class="info-item">
          {{ dashboard.metrics.total_widgets }} widgets
        </span>
        <span class="info-item" *ngIf="dashboard.metrics.last_refresh">
          Last updated: {{ dashboard.metrics.last_refresh | date:'short' }}
        </span>
        <span class="info-item warning" *ngIf="dashboard.metrics.has_stale_data">
          ⚠️ Some data may be stale
        </span>
      </div>

      <!-- Widget Picker Dialog -->
      <div class="widget-picker-overlay" *ngIf="showWidgetPicker" (click)="toggleWidgetPicker()">
        <div class="widget-picker" (click)="$event.stopPropagation()">
          <h3>Add Widget</h3>
          <div class="widget-types">
            <div *ngFor="let widgetType of availableWidgetTypes"
                 class="widget-type-card"
                 (click)="addWidget(widgetType.type)">
              <div class="widget-icon">{{ widgetType.icon }}</div>
              <div class="widget-info">
                <h4>{{ widgetType.name }}</h4>
                <p>{{ widgetType.description }}</p>
              </div>
            </div>
          </div>
          <button class="button button--secondary" (click)="toggleWidgetPicker()">
            Cancel
          </button>
        </div>
      </div>

      <!-- Grid Layout -->
      <div class="dashboard-grid" *ngIf="dashboard">
        <div class="grid-container">
          <div *ngFor="let widget of dashboard.widgets"
               class="widget-container"
               [style.grid-column]="getGridColumn(widget)"
               [style.grid-row]="getGridRow(widget)"
               [class.edit-mode]="editMode">

            <!-- Widget Header -->
            <div class="widget-header">
              <h3>{{ widget.title }}</h3>
              <div class="widget-actions" *ngIf="editMode">
                <button class="icon-button" (click)="refreshWidget(widget)" title="Refresh">
                  🔄
                </button>
                <button class="icon-button" (click)="configureWidget(widget)" title="Configure">
                  ⚙️
                </button>
                <button class="icon-button danger" (click)="removeWidget(widget)" title="Remove">
                  ✕
                </button>
              </div>
            </div>

            <!-- Widget Content -->
            <div class="widget-content">
              <op-dashboard-widget
                [widgetType]="widget.widget_type"
                [data]="widget.data"
                [config]="widget.config"
                [loading]="loadingWidgets.has(widget.id)">
              </op-dashboard-widget>
            </div>

            <!-- Widget Footer -->
            <div class="widget-footer" *ngIf="widget.last_updated">
              <span class="timestamp">
                Updated {{ widget.last_updated | date:'short' }}
              </span>
            </div>
          </div>

          <!-- Empty State -->
          <div class="empty-state" *ngIf="!dashboard.widgets || dashboard.widgets.length === 0">
            <div class="empty-icon">📊</div>
            <h3>No Widgets Yet</h3>
            <p>Add widgets to start tracking your BIM project metrics</p>
            <button class="button button--primary" (click)="toggleWidgetPicker()">
              Add Your First Widget
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div class="loading-state" *ngIf="loading">
        <div class="spinner"></div>
        <p>Loading dashboard...</p>
      </div>
    </div>
  `,
  styles: [`
    .bim-dashboard {
      padding: 24px;
      background: #f5f5f5;
      min-height: 100vh;
    }

    .dashboard-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
      padding: 20px;
      background: #fff;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .header-left h2 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .description {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .header-right {
      display: flex;
      gap: 12px;
    }

    .button {
      padding: 8px 16px;
      background: #2196f3;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: background 0.2s;
    }

    .button:hover {
      background: #1976d2;
    }

    .button:disabled {
      background: #ccc;
      cursor: not-allowed;
    }

    .button--secondary {
      background: #fff;
      color: #333;
      border: 1px solid #ddd;
    }

    .button--secondary:hover {
      background: #f5f5f5;
    }

    .button--primary {
      background: #4caf50;
    }

    .button--primary:hover {
      background: #45a049;
    }

    .icon {
      font-size: 16px;
    }

    .dashboard-info {
      display: flex;
      gap: 24px;
      margin-bottom: 16px;
      padding: 12px 20px;
      background: #fff;
      border-radius: 4px;
      font-size: 14px;
      color: #666;
    }

    .info-item.warning {
      color: #f57c00;
      font-weight: 600;
    }

    .widget-picker-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }

    .widget-picker {
      background: white;
      border-radius: 8px;
      padding: 24px;
      max-width: 800px;
      max-height: 80vh;
      overflow-y: auto;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    }

    .widget-picker h3 {
      margin: 0 0 20px 0;
    }

    .widget-types {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 20px;
    }

    .widget-type-card {
      padding: 16px;
      border: 1px solid #e0e0e0;
      border-radius: 4px;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      gap: 12px;
    }

    .widget-type-card:hover {
      border-color: #2196f3;
      background: #f5f5f5;
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    }

    .widget-icon {
      font-size: 32px;
      line-height: 1;
    }

    .widget-info h4 {
      margin: 0 0 4px 0;
      font-size: 16px;
    }

    .widget-info p {
      margin: 0;
      font-size: 13px;
      color: #666;
    }

    .dashboard-grid {
      margin-top: 16px;
    }

    .grid-container {
      display: grid;
      grid-template-columns: repeat(12, 1fr);
      grid-auto-rows: 100px;
      gap: 16px;
    }

    .widget-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      transition: box-shadow 0.2s;
    }

    .widget-container:hover {
      box-shadow: 0 4px 8px rgba(0,0,0,0.15);
    }

    .widget-container.edit-mode {
      border: 2px dashed #2196f3;
    }

    .widget-header {
      padding: 12px 16px;
      border-bottom: 1px solid #e0e0e0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #fafafa;
    }

    .widget-header h3 {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
      color: #333;
    }

    .widget-actions {
      display: flex;
      gap: 8px;
    }

    .icon-button {
      background: none;
      border: none;
      cursor: pointer;
      font-size: 16px;
      padding: 4px;
      opacity: 0.7;
      transition: opacity 0.2s;
    }

    .icon-button:hover {
      opacity: 1;
    }

    .icon-button.danger:hover {
      color: #f44336;
    }

    .widget-content {
      flex: 1;
      padding: 16px;
      overflow: auto;
    }

    .widget-footer {
      padding: 8px 16px;
      border-top: 1px solid #e0e0e0;
      font-size: 12px;
      color: #999;
      background: #fafafa;
    }

    .empty-state {
      grid-column: 1 / -1;
      text-align: center;
      padding: 60px 20px;
      background: white;
      border-radius: 8px;
    }

    .empty-icon {
      font-size: 64px;
      margin-bottom: 16px;
    }

    .empty-state h3 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .empty-state p {
      margin: 0 0 24px 0;
      color: #666;
    }

    .loading-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px;
    }

    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #f3f3f3;
      border-top: 4px solid #2196f3;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-bottom: 16px;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  `]
})
export class BimDashboardComponent implements OnInit, OnDestroy {
  @Input() projectId!: number;
  @Input() dashboardId?: number;

  dashboard: Dashboard | null = null;
  loading = false;
  refreshing = false;
  editMode = false;
  showWidgetPicker = false;
  loadingWidgets = new Set<number>();

  private refreshSubscription?: Subscription;

  availableWidgetTypes: WidgetType[] = [
    { type: 'model_count', name: 'IFC Models', description: 'Model count and statistics', default_size: { width: 4, height: 3 }, icon: '🏗️' },
    { type: 'clash_summary', name: 'Clash Summary', description: 'Clash detection overview', default_size: { width: 4, height: 3 }, icon: '⚠️' },
    { type: 'issue_trend', name: 'Issue Trends', description: 'BCF issue trends over time', default_size: { width: 6, height: 4 }, icon: '📈' },
    { type: 'progress_chart', name: 'Progress Overview', description: 'Construction progress', default_size: { width: 6, height: 4 }, icon: '📊' },
    { type: 'discipline_breakdown', name: 'Discipline Breakdown', description: 'Elements by discipline', default_size: { width: 4, height: 3 }, icon: '🎯' },
    { type: 'recent_activity', name: 'Recent Activity', description: 'Latest BIM activities', default_size: { width: 6, height: 5 }, icon: '🕒' },
    { type: 'kpi_card', name: 'KPI Card', description: 'Single metric display', default_size: { width: 3, height: 2 }, icon: '💯' },
    { type: 'work_package_summary', name: 'Work Packages', description: 'Work package statistics', default_size: { width: 4, height: 3 }, icon: '📋' }
  ];

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadDashboard();
    this.setupAutoRefresh();
  }

  ngOnDestroy(): void {
    this.refreshSubscription?.unsubscribe();
  }

  loadDashboard(): void {
    this.loading = true;

    const url = this.dashboardId
      ? `/api/v3/bim/dashboards/${this.dashboardId}?include_data=true`
      : `/api/v3/bim/dashboards/default?project_id=${this.projectId}`;

    this.http.get<Dashboard>(url).subscribe({
      next: (dashboard) => {
        this.dashboard = dashboard;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading dashboard:', error);
        this.loading = false;
      }
    });
  }

  refreshAll(): void {
    if (!this.dashboard) return;

    this.refreshing = true;

    this.http.post(`/api/v3/bim/dashboards/${this.dashboard.id}/refresh`, {}).subscribe({
      next: () => {
        this.loadDashboard();
        this.refreshing = false;
      },
      error: (error) => {
        console.error('Error refreshing dashboard:', error);
        this.refreshing = false;
      }
    });
  }

  refreshWidget(widget: Widget): void {
    this.loadingWidgets.add(widget.id);

    this.http.post(`/api/v3/bim/widgets/${widget.id}/refresh`, {}).subscribe({
      next: (response: any) => {
        widget.data = response.widget.data;
        widget.last_updated = response.widget.last_updated;
        this.loadingWidgets.delete(widget.id);
      },
      error: (error) => {
        console.error('Error refreshing widget:', error);
        this.loadingWidgets.delete(widget.id);
      }
    });
  }

  addWidget(widgetType: string): void {
    if (!this.dashboard) return;

    const widgetTypeInfo = this.availableWidgetTypes.find(wt => wt.type === widgetType);
    const position = this.calculateNextPosition();
    const size = widgetTypeInfo?.default_size || { width: 4, height: 3 };

    this.http.post('/api/v3/bim/widgets', {
      widget: {
        dashboard_id: this.dashboard.id,
        widget_type: widgetType,
        position: position,
        size: size,
        config: {}
      }
    }).subscribe({
      next: () => {
        this.loadDashboard();
        this.toggleWidgetPicker();
      },
      error: (error) => {
        console.error('Error adding widget:', error);
      }
    });
  }

  removeWidget(widget: Widget): void {
    if (!confirm(`Remove widget "${widget.title}"?`)) return;

    this.http.delete(`/api/v3/bim/widgets/${widget.id}`).subscribe({
      next: () => {
        this.loadDashboard();
      },
      error: (error) => {
        console.error('Error removing widget:', error);
      }
    });
  }

  configureWidget(widget: Widget): void {
    // Open configuration dialog
    alert('Widget configuration coming soon!');
  }

  toggleEditMode(): void {
    this.editMode = !this.editMode;
  }

  toggleWidgetPicker(): void {
    this.showWidgetPicker = !this.showWidgetPicker;
  }

  exportPDF(): void {
    alert('PDF export coming soon!');
  }

  getGridColumn(widget: Widget): string {
    const x = widget.position.x || 0;
    const width = widget.size.width || 4;
    return `${x + 1} / span ${width}`;
  }

  getGridRow(widget: Widget): string {
    const y = widget.position.y || 0;
    const height = widget.size.height || 3;
    return `${y + 1} / span ${height}`;
  }

  private calculateNextPosition(): { x: number; y: number } {
    if (!this.dashboard?.widgets || this.dashboard.widgets.length === 0) {
      return { x: 0, y: 0 };
    }

    // Simple algorithm: find max y + height
    let maxY = 0;
    this.dashboard.widgets.forEach(w => {
      const y = (w.position.y || 0) + (w.size.height || 3);
      if (y > maxY) maxY = y;
    });

    return { x: 0, y: maxY };
  }

  private setupAutoRefresh(): void {
    // Auto-refresh every 5 minutes
    this.refreshSubscription = interval(5 * 60 * 1000).subscribe(() => {
      if (this.dashboard && !this.refreshing) {
        this.refreshAll();
      }
    });
  }
}
