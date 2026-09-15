/**
 * Dashboard Widget Component
 *
 * Renders individual widget content based on widget type and data.
 * Supports 16 different widget types with appropriate visualizations.
 */

import { Component, Input, OnChanges } from '@angular/core';

@Component({
  selector: 'op-dashboard-widget',
  template: `
    <div class="widget-renderer" [class.loading]="loading">
      <!-- Loading State -->
      <div class="loading-overlay" *ngIf="loading">
        <div class="spinner"></div>
      </div>

      <!-- Error State -->
      <div class="error-state" *ngIf="data?.error">
        <span class="error-icon">⚠️</span>
        <p>{{ data.error }}</p>
      </div>

      <!-- Widget Content -->
      <div [ngSwitch]="widgetType" *ngIf="!loading && !data?.error">
        <!-- Model Count -->
        <div *ngSwitchCase="'model_count'" class="widget-model-count">
          <div class="stat-card">
            <div class="stat-value">{{ data?.total || 0 }}</div>
            <div class="stat-label">Total Models</div>
          </div>
          <div class="stat-grid">
            <div class="stat-item">
              <span class="label">Recent:</span>
              <span class="value">{{ data?.recent_uploads || 0 }}</span>
            </div>
            <div class="stat-item">
              <span class="label">Success Rate:</span>
              <span class="value">{{ data?.by_status?.completed || 0 }}</span>
            </div>
          </div>
        </div>

        <!-- Clash Summary -->
        <div *ngSwitchCase="'clash_summary'" class="widget-clash-summary">
          <div class="summary-stats">
            <div class="stat-box stat-box--danger">
              <div class="stat-number">{{ data?.new_count || 0 }}</div>
              <div class="stat-text">New Clashes</div>
            </div>
            <div class="stat-box stat-box--success">
              <div class="stat-number">{{ data?.resolved_count || 0 }}</div>
              <div class="stat-text">Resolved</div>
            </div>
            <div class="stat-box">
              <div class="stat-number">{{ data?.resolution_rate || 0 }}%</div>
              <div class="stat-text">Resolution Rate</div>
            </div>
          </div>
        </div>

        <!-- Issue Trend -->
        <div *ngSwitchCase="'issue_trend'" class="widget-issue-trend">
          <div class="chart-container">
            <div class="simple-chart">
              <div *ngFor="let value of data?.values; let i = index"
                   class="chart-bar"
                   [style.height.%]="(value / getMax(data?.values)) * 100"
                   [title]="data?.labels[i] + ': ' + value">
              </div>
            </div>
            <div class="chart-labels">
              <span *ngFor="let label of data?.labels" class="chart-label">
                {{ label | date:'MMM d' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Progress Chart -->
        <div *ngSwitchCase="'progress_chart'" class="widget-progress-chart">
          <div class="progress-circle">
            <svg viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="40" class="progress-bg"></circle>
              <circle cx="50" cy="50" r="40" class="progress-fill"
                      [style.stroke-dashoffset]="calculateDashOffset(data?.overall_progress || 0)">
              </circle>
            </svg>
            <div class="progress-text">
              <span class="percentage">{{ data?.overall_progress || 0 }}%</span>
              <span class="label">Complete</span>
            </div>
          </div>
          <div class="progress-breakdown">
            <div class="breakdown-item">
              <span class="color-dot completed"></span>
              <span class="text">Completed: {{ data?.completed || 0 }}</span>
            </div>
            <div class="breakdown-item">
              <span class="color-dot in-progress"></span>
              <span class="text">In Progress: {{ data?.in_progress || 0 }}</span>
            </div>
            <div class="breakdown-item">
              <span class="color-dot planned"></span>
              <span class="text">Planned: {{ data?.planned || 0 }}</span>
            </div>
          </div>
        </div>

        <!-- KPI Card -->
        <div *ngSwitchCase="'kpi_card'" class="widget-kpi-card">
          <div class="kpi-value">{{ data?.value || 0 }}{{ data?.unit || '' }}</div>
          <div class="kpi-label">{{ data?.label || 'Metric' }}</div>
        </div>

        <!-- Recent Activity -->
        <div *ngSwitchCase="'recent_activity'" class="widget-recent-activity">
          <div class="activity-list">
            <div *ngFor="let activity of data?.activities" class="activity-item">
              <span class="activity-icon" [class]="activity.type">
                {{ activity.type === 'clash' ? '⚠️' : '📝' }}
              </span>
              <div class="activity-content">
                <p class="activity-description">{{ activity.description }}</p>
                <span class="activity-time">{{ activity.timestamp | date:'short' }}</span>
              </div>
            </div>
            <div *ngIf="!data?.activities || data.activities.length === 0" class="empty-message">
              No recent activity
            </div>
          </div>
        </div>

        <!-- Work Package Summary -->
        <div *ngSwitchCase="'work_package_summary'" class="widget-wp-summary">
          <div class="summary-row">
            <span class="label">Total Packages:</span>
            <span class="value">{{ data?.total || 0 }}</span>
          </div>
          <div class="summary-row">
            <span class="label">With BIM Links:</span>
            <span class="value">{{ data?.with_bim_links || 0 }}</span>
          </div>
          <div class="summary-row">
            <span class="label">Linkage Rate:</span>
            <span class="value success">{{ data?.bim_linkage_rate || 0 }}%</span>
          </div>
          <div class="summary-row">
            <span class="label">Avg Completion:</span>
            <span class="value">{{ data?.avg_completion || 0 }}%</span>
          </div>
        </div>

        <!-- Discipline Breakdown -->
        <div *ngSwitchCase="'discipline_breakdown'" class="widget-discipline">
          <div class="discipline-list">
            <div *ngFor="let label of data?.labels; let i = index" class="discipline-item">
              <span class="discipline-name">{{ label }}</span>
              <div class="discipline-bar">
                <div class="bar-fill"
                     [style.width.%]="(data.values[i] / getMax(data?.values)) * 100">
                </div>
              </div>
              <span class="discipline-count">{{ data.values[i] }}</span>
            </div>
          </div>
        </div>

        <!-- Resolution Rate -->
        <div *ngSwitchCase="'resolution_rate'" class="widget-resolution">
          <div class="rate-row">
            <span class="label">Clash Resolution:</span>
            <div class="rate-bar">
              <div class="rate-fill" [style.width.%]="data?.clashes || 0"></div>
            </div>
            <span class="value">{{ data?.clashes || 0 }}%</span>
          </div>
          <div class="rate-row">
            <span class="label">Issue Resolution:</span>
            <div class="rate-bar">
              <div class="rate-fill" [style.width.%]="data?.issues || 0"></div>
            </div>
            <span class="value">{{ data?.issues || 0 }}%</span>
          </div>
        </div>

        <!-- Default/Generic -->
        <div *ngSwitchDefault class="widget-generic">
          <pre>{{ data | json }}</pre>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .widget-renderer {
      height: 100%;
      position: relative;
    }

    .loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(255,255,255,0.8);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 10;
    }

    .spinner {
      width: 30px;
      height: 30px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #2196f3;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .error-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      color: #f44336;
    }

    .error-icon {
      font-size: 32px;
      margin-bottom: 8px;
    }

    /* Model Count Widget */
    .widget-model-count .stat-card {
      text-align: center;
      margin-bottom: 16px;
    }

    .stat-value {
      font-size: 48px;
      font-weight: 700;
      color: #2196f3;
    }

    .stat-label {
      font-size: 14px;
      color: #666;
      margin-top: 4px;
    }

    .stat-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .stat-item {
      display: flex;
      justify-content: space-between;
      padding: 8px;
      background: #f5f5f5;
      border-radius: 4px;
    }

    .stat-item .label {
      color: #666;
      font-size: 13px;
    }

    .stat-item .value {
      font-weight: 600;
      color: #333;
    }

    /* Clash Summary Widget */
    .summary-stats {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      height: 100%;
    }

    .stat-box {
      background: #f5f5f5;
      border-radius: 8px;
      padding: 16px;
      text-align: center;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }

    .stat-box--danger {
      background: #ffebee;
      border-left: 4px solid #f44336;
    }

    .stat-box--success {
      background: #e8f5e9;
      border-left: 4px solid #4caf50;
    }

    .stat-number {
      font-size: 32px;
      font-weight: 700;
      color: #333;
      margin-bottom: 4px;
    }

    .stat-text {
      font-size: 12px;
      color: #666;
    }

    /* Chart Widgets */
    .chart-container {
      height: 100%;
      display: flex;
      flex-direction: column;
    }

    .simple-chart {
      flex: 1;
      display: flex;
      align-items: flex-end;
      gap: 4px;
      padding: 8px 0;
    }

    .chart-bar {
      flex: 1;
      background: linear-gradient(to top, #2196f3, #64b5f6);
      border-radius: 4px 4px 0 0;
      min-height: 4px;
      transition: all 0.3s;
    }

    .chart-bar:hover {
      background: linear-gradient(to top, #1976d2, #2196f3);
    }

    .chart-labels {
      display: flex;
      justify-content: space-between;
      font-size: 10px;
      color: #666;
      margin-top: 8px;
    }

    /* Progress Chart Widget */
    .widget-progress-chart {
      display: flex;
      align-items: center;
      gap: 24px;
      height: 100%;
    }

    .progress-circle {
      position: relative;
      width: 120px;
      height: 120px;
      flex-shrink: 0;
    }

    .progress-circle svg {
      transform: rotate(-90deg);
    }

    .progress-bg {
      fill: none;
      stroke: #e0e0e0;
      stroke-width: 8;
    }

    .progress-fill {
      fill: none;
      stroke: #4caf50;
      stroke-width: 8;
      stroke-dasharray: 251.2;
      transition: stroke-dashoffset 0.5s;
    }

    .progress-text {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
    }

    .progress-text .percentage {
      display: block;
      font-size: 24px;
      font-weight: 700;
      color: #333;
    }

    .progress-text .label {
      font-size: 12px;
      color: #666;
    }

    .progress-breakdown {
      flex: 1;
    }

    .breakdown-item {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 12px;
    }

    .color-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }

    .color-dot.completed { background: #4caf50; }
    .color-dot.in-progress { background: #ff9800; }
    .color-dot.planned { background: #e0e0e0; }

    /* KPI Card Widget */
    .widget-kpi-card {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
    }

    .kpi-value {
      font-size: 56px;
      font-weight: 700;
      color: #2196f3;
      line-height: 1;
    }

    .kpi-label {
      font-size: 16px;
      color: #666;
      margin-top: 8px;
    }

    /* Recent Activity Widget */
    .activity-list {
      max-height: 100%;
      overflow-y: auto;
    }

    .activity-item {
      display: flex;
      gap: 12px;
      padding: 12px;
      border-bottom: 1px solid #e0e0e0;
    }

    .activity-item:last-child {
      border-bottom: none;
    }

    .activity-icon {
      font-size: 20px;
      flex-shrink: 0;
    }

    .activity-content {
      flex: 1;
    }

    .activity-description {
      margin: 0 0 4px 0;
      font-size: 14px;
      color: #333;
    }

    .activity-time {
      font-size: 12px;
      color: #999;
    }

    .empty-message {
      text-align: center;
      padding: 24px;
      color: #999;
    }

    /* Work Package Summary Widget */
    .widget-wp-summary .summary-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #e0e0e0;
    }

    .widget-wp-summary .summary-row:last-child {
      border-bottom: none;
    }

    .summary-row .label {
      color: #666;
      font-size: 14px;
    }

    .summary-row .value {
      font-weight: 600;
      color: #333;
    }

    .summary-row .value.success {
      color: #4caf50;
    }

    /* Discipline Breakdown Widget */
    .discipline-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .discipline-item {
      display: grid;
      grid-template-columns: 120px 1fr 50px;
      gap: 12px;
      align-items: center;
    }

    .discipline-name {
      font-size: 13px;
      color: #666;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .discipline-bar {
      height: 20px;
      background: #e0e0e0;
      border-radius: 10px;
      overflow: hidden;
    }

    .bar-fill {
      height: 100%;
      background: linear-gradient(to right, #2196f3, #64b5f6);
      transition: width 0.3s;
    }

    .discipline-count {
      text-align: right;
      font-weight: 600;
      font-size: 14px;
      color: #333;
    }

    /* Resolution Rate Widget */
    .widget-resolution .rate-row {
      display: grid;
      grid-template-columns: 140px 1fr 60px;
      gap: 12px;
      align-items: center;
      margin-bottom: 16px;
    }

    .rate-bar {
      height: 24px;
      background: #e0e0e0;
      border-radius: 12px;
      overflow: hidden;
    }

    .rate-fill {
      height: 100%;
      background: linear-gradient(to right, #4caf50, #66bb6a);
      transition: width 0.3s;
    }

    /* Generic Widget */
    .widget-generic pre {
      margin: 0;
      font-size: 11px;
      overflow: auto;
      max-height: 100%;
    }
  `]
})
export class DashboardWidgetComponent implements OnChanges {
  @Input() widgetType!: string;
  @Input() data: any;
  @Input() config: any;
  @Input() loading = false;

  ngOnChanges(): void {
    // React to data changes
  }

  getMax(values: number[]): number {
    if (!values || values.length === 0) return 1;
    return Math.max(...values);
  }

  calculateDashOffset(percentage: number): number {
    const circumference = 2 * Math.PI * 40;
    return circumference - (percentage / 100) * circumference;
  }
}
