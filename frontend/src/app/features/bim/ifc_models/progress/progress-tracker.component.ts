/**
 * Progress Tracker Component
 *
 * Displays and manages BIM element progress tracking with:
 * - Progress overview statistics
 * - Element-level progress list
 * - Baseline comparison
 * - Bulk progress updates
 * - Work package synchronization
 * - Visual progress indicators
 *
 * Usage:
 *   <op-progress-tracker
 *     [modelId]="123"
 *     [viewer]="xeokitViewer"
 *     (progressUpdated)="onProgressUpdated($event)">
 *   </op-progress-tracker>
 */

import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export interface ElementProgress {
  id: number;
  element_id: string;
  element_name: string;
  element_type: string;
  display_name: string;
  status: 'planned' | 'in_progress' | 'completed' | 'on_hold';
  percent_complete: number;
  work_package_id?: number;
  planned_start?: string;
  planned_finish?: string;
  actual_start?: string;
  actual_finish?: string;
  schedule_variance_days?: number;
  delayed?: boolean;
  ahead_of_schedule?: boolean;
  progress_color: string;
}

export interface ProgressStatistics {
  total_elements: number;
  completed_elements: number;
  in_progress_elements: number;
  planned_elements: number;
  on_hold_elements: number;
  average_progress: number;
  overall_progress: number;
  delayed_count: number;
  ahead_count: number;
  on_schedule_count: number;
}

export interface ProgressBaseline {
  id: number;
  name: string;
  snapshot_date: string;
  is_current: boolean;
  total_elements: number;
  completed_elements: number;
  overall_progress: number;
}

@Component({
  selector: 'op-progress-tracker',
  template: `
    <div class="progress-tracker">
      <!-- Statistics Overview -->
      <div class="progress-overview">
        <h3>Progress Overview</h3>

        <div class="stats-grid" *ngIf="statistics">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.overall_progress }}%</div>
            <div class="stat-label">Overall Progress</div>
            <div class="progress-bar">
              <div class="progress-fill" [style.width.%]="statistics.overall_progress"></div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-value">{{ statistics.completed_elements }}</div>
            <div class="stat-label">Completed</div>
            <div class="stat-sublabel">of {{ statistics.total_elements }} elements</div>
          </div>

          <div class="stat-card">
            <div class="stat-value">{{ statistics.in_progress_elements }}</div>
            <div class="stat-label">In Progress</div>
          </div>

          <div class="stat-card stat-card--warning" *ngIf="statistics.delayed_count > 0">
            <div class="stat-value">{{ statistics.delayed_count }}</div>
            <div class="stat-label">Delayed</div>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="progress-actions">
        <button class="button" (click)="syncFromWorkPackages()">
          Sync from Work Packages
        </button>
        <button class="button" (click)="showBaselineDialog()">
          Create Baseline
        </button>
        <button class="button" (click)="loadBaselines()">
          Compare Baselines
        </button>
        <button class="button button--secondary" (click)="toggleBulkEdit()">
          Bulk Edit
        </button>
      </div>

      <!-- Baseline Comparison -->
      <div class="baseline-comparison" *ngIf="baselineComparison">
        <h4>Baseline Comparison: {{ baselineComparison.baseline_name }}</h4>
        <div class="comparison-stats">
          <div class="comparison-stat">
            <span class="label">Baseline:</span>
            <span class="value">{{ baselineComparison.baseline_progress }}%</span>
          </div>
          <div class="comparison-stat">
            <span class="label">Current:</span>
            <span class="value">{{ baselineComparison.current_progress }}%</span>
          </div>
          <div class="comparison-stat" [class.positive]="baselineComparison.variance > 0"
               [class.negative]="baselineComparison.variance < 0">
            <span class="label">Variance:</span>
            <span class="value">{{ baselineComparison.variance > 0 ? '+' : '' }}{{ baselineComparison.variance }}%</span>
          </div>
        </div>
      </div>

      <!-- Element Progress List -->
      <div class="progress-list">
        <div class="list-header">
          <h4>Element Progress</h4>
          <div class="filters">
            <select [(ngModel)]="filterStatus" (change)="loadProgress()">
              <option value="">All Statuses</option>
              <option value="planned">Planned</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="on_hold">On Hold</option>
            </select>
            <input type="text" placeholder="Search elements..."
                   [(ngModel)]="searchQuery" (input)="filterElements()">
          </div>
        </div>

        <div class="progress-items">
          <div *ngFor="let element of filteredElements"
               class="progress-item"
               [class.selected]="selectedElements.has(element.id)"
               (click)="toggleSelection(element)">

            <div class="item-header">
              <input type="checkbox" *ngIf="bulkEditMode"
                     [checked]="selectedElements.has(element.id)"
                     (click)="$event.stopPropagation()">

              <div class="element-info" (click)="highlightElement(element.element_id)">
                <span class="element-name">{{ element.display_name }}</span>
                <span class="element-type">{{ element.element_type }}</span>
              </div>

              <div class="status-badge" [class]="'status--' + element.status">
                {{ element.status }}
              </div>
            </div>

            <div class="item-progress">
              <div class="progress-bar">
                <div class="progress-fill"
                     [style.width.%]="element.percent_complete"
                     [style.background-color]="element.progress_color"></div>
              </div>
              <span class="progress-value">{{ element.percent_complete }}%</span>
            </div>

            <div class="item-details" *ngIf="element.planned_start">
              <span class="detail" *ngIf="element.schedule_variance_days">
                <span class="label">Schedule:</span>
                <span [class.warning]="element.delayed"
                      [class.success]="element.ahead_of_schedule">
                  {{ element.schedule_variance_days > 0 ? '+' : '' }}{{ element.schedule_variance_days }} days
                </span>
              </span>
            </div>

            <div class="item-actions" *ngIf="!bulkEditMode">
              <input type="range" min="0" max="100" step="5"
                     [value]="element.percent_complete"
                     (change)="updateProgress(element, $event)">
            </div>
          </div>
        </div>
      </div>

      <!-- Bulk Edit Panel -->
      <div class="bulk-edit-panel" *ngIf="bulkEditMode && selectedElements.size > 0">
        <div class="panel-header">
          <span>{{ selectedElements.size }} elements selected</span>
          <button (click)="clearSelection()">Clear</button>
        </div>
        <div class="panel-actions">
          <label>
            Set Progress:
            <input type="number" min="0" max="100" [(ngModel)]="bulkProgress">
          </label>
          <button class="button button--primary" (click)="applyBulkUpdate()">
            Apply to Selected
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .progress-tracker {
      padding: 20px;
      background: #fff;
    }

    .progress-overview {
      margin-bottom: 24px;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-top: 16px;
    }

    .stat-card {
      padding: 20px;
      background: #f5f5f5;
      border-radius: 8px;
      border-left: 4px solid #2196f3;
    }

    .stat-card--warning {
      border-left-color: #f44336;
    }

    .stat-value {
      font-size: 32px;
      font-weight: 700;
      color: #333;
    }

    .stat-label {
      font-size: 14px;
      color: #666;
      margin-top: 4px;
    }

    .stat-sublabel {
      font-size: 12px;
      color: #999;
    }

    .progress-bar {
      height: 8px;
      background: #e0e0e0;
      border-radius: 4px;
      margin-top: 12px;
      overflow: hidden;
    }

    .progress-fill {
      height: 100%;
      background: #2196f3;
      transition: width 0.3s ease;
    }

    .progress-actions {
      display: flex;
      gap: 12px;
      margin-bottom: 24px;
      flex-wrap: wrap;
    }

    .baseline-comparison {
      padding: 16px;
      background: #e3f2fd;
      border-radius: 4px;
      margin-bottom: 24px;
    }

    .comparison-stats {
      display: flex;
      gap: 24px;
      margin-top: 12px;
    }

    .comparison-stat {
      display: flex;
      gap: 8px;
    }

    .comparison-stat .value {
      font-weight: 600;
    }

    .comparison-stat.positive .value {
      color: #4caf50;
    }

    .comparison-stat.negative .value {
      color: #f44336;
    }

    .list-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .filters {
      display: flex;
      gap: 12px;
    }

    .progress-items {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .progress-item {
      padding: 16px;
      background: #fafafa;
      border-radius: 4px;
      border: 1px solid #e0e0e0;
      cursor: pointer;
      transition: all 0.2s;
    }

    .progress-item:hover {
      background: #f5f5f5;
      border-color: #2196f3;
    }

    .progress-item.selected {
      background: #e3f2fd;
      border-color: #2196f3;
    }

    .item-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 12px;
    }

    .element-info {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .element-name {
      font-weight: 600;
      color: #333;
    }

    .element-type {
      font-size: 12px;
      color: #666;
      padding: 2px 8px;
      background: #fff;
      border-radius: 8px;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status--planned { background: #e0e0e0; color: #666; }
    .status--in_progress { background: #fff3e0; color: #f57c00; }
    .status--completed { background: #e8f5e9; color: #2e7d32; }
    .status--on_hold { background: #fafafa; color: #9e9e9e; }

    .item-progress {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
    }

    .item-progress .progress-bar {
      flex: 1;
      margin: 0;
    }

    .progress-value {
      font-weight: 600;
      min-width: 45px;
      text-align: right;
    }

    .item-details {
      display: flex;
      gap: 16px;
      font-size: 12px;
      color: #666;
    }

    .item-details .label {
      color: #999;
    }

    .item-details .warning {
      color: #f44336;
      font-weight: 600;
    }

    .item-details .success {
      color: #4caf50;
      font-weight: 600;
    }

    .item-actions {
      margin-top: 12px;
    }

    .item-actions input[type="range"] {
      width: 100%;
    }

    .bulk-edit-panel {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: #fff;
      border-top: 2px solid #2196f3;
      padding: 16px 24px;
      box-shadow: 0 -2px 8px rgba(0,0,0,0.1);
      z-index: 1000;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 12px;
      font-weight: 600;
    }

    .panel-actions {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .panel-actions label {
      display: flex;
      align-items: center;
      gap: 8px;
    }
  `]
})
export class ProgressTrackerComponent implements OnInit {
  @Input() modelId!: number;
  @Input() viewer: any; // xeokit Viewer

  @Output() progressUpdated = new EventEmitter<ElementProgress>();

  statistics: ProgressStatistics | null = null;
  elements: ElementProgress[] = [];
  filteredElements: ElementProgress[] = [];
  baselines: ProgressBaseline[] = [];
  baselineComparison: any = null;

  filterStatus = '';
  searchQuery = '';
  bulkEditMode = false;
  bulkProgress = 0;
  selectedElements = new Set<number>();

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadStatistics();
    this.loadProgress();
  }

  loadStatistics(): void {
    this.http.get<ProgressStatistics>(`/api/v3/bim/progress/statistics?model_id=${this.modelId}`)
      .subscribe(stats => {
        this.statistics = stats;
      });
  }

  loadProgress(): void {
    let url = `/api/v3/bim/progress?model_id=${this.modelId}&per_page=200`;
    if (this.filterStatus) {
      url += `&status=${this.filterStatus}`;
    }

    this.http.get<{progress: ElementProgress[]}>url)
      .subscribe(response => {
        this.elements = response.progress;
        this.filteredElements = this.elements;
        this.applyVisualization();
      });
  }

  filterElements(): void {
    if (!this.searchQuery) {
      this.filteredElements = this.elements;
      return;
    }

    const query = this.searchQuery.toLowerCase();
    this.filteredElements = this.elements.filter(elem =>
      elem.display_name.toLowerCase().includes(query) ||
      elem.element_id.toLowerCase().includes(query) ||
      elem.element_type.toLowerCase().includes(query)
    );
  }

  updateProgress(element: ElementProgress, event: any): void {
    const newProgress = parseInt(event.target.value);

    this.http.patch(`/api/v3/bim/progress/${element.id}`, {
      percent_complete: newProgress
    }).subscribe(() => {
      element.percent_complete = newProgress;
      this.loadStatistics();
      this.progressUpdated.emit(element);
    });
  }

  syncFromWorkPackages(): void {
    this.http.post(`/api/v3/bim/progress/sync_work_packages`, {
      model_id: this.modelId
    }).subscribe(() => {
      this.loadProgress();
      this.loadStatistics();
      alert('Progress synced from work packages');
    });
  }

  loadBaselines(): void {
    this.http.get<{baselines: ProgressBaseline[]}>(`/api/v3/bim/baselines?model_id=${this.modelId}`)
      .subscribe(response => {
        this.baselines = response.baselines;
        if (this.baselines.length > 0) {
          this.compareToBaseline(this.baselines[0]);
        }
      });
  }

  compareToBaseline(baseline: ProgressBaseline): void {
    this.http.get(`/api/v3/bim/baselines/${baseline.id}/compare`)
      .subscribe(comparison => {
        this.baselineComparison = comparison;
      });
  }

  showBaselineDialog(): void {
    const name = prompt('Enter baseline name:');
    if (!name) return;

    this.http.post('/api/v3/bim/baselines', {
      ifc_model_id: this.modelId,
      name: name,
      snapshot_date: new Date().toISOString().split('T')[0],
      create_snapshot: true
    }).subscribe(() => {
      alert('Baseline created successfully');
      this.loadBaselines();
    });
  }

  toggleBulkEdit(): void {
    this.bulkEditMode = !this.bulkEditMode;
    if (!this.bulkEditMode) {
      this.clearSelection();
    }
  }

  toggleSelection(element: ElementProgress): void {
    if (!this.bulkEditMode) return;

    if (this.selectedElements.has(element.id)) {
      this.selectedElements.delete(element.id);
    } else {
      this.selectedElements.add(element.id);
    }
  }

  clearSelection(): void {
    this.selectedElements.clear();
  }

  applyBulkUpdate(): void {
    const updates = Array.from(this.selectedElements).map(id => {
      const element = this.elements.find(e => e.id === id);
      return {
        element_id: element!.element_id,
        percent_complete: this.bulkProgress
      };
    });

    this.http.post('/api/v3/bim/progress/bulk_update', {
      model_id: this.modelId,
      updates: updates
    }).subscribe(() => {
      this.loadProgress();
      this.loadStatistics();
      this.clearSelection();
      this.bulkEditMode = false;
      alert(`Updated ${updates.length} elements`);
    });
  }

  highlightElement(elementId: string): void {
    if (!this.viewer) return;

    const entity = this.viewer.scene.objects[elementId];
    if (entity) {
      entity.selected = true;
      this.viewer.cameraFlight.flyTo({
        aabb: entity.aabb,
        duration: 1.0
      });
    }
  }

  applyVisualization(): void {
    if (!this.viewer) return;

    this.elements.forEach(elem => {
      const entity = this.viewer.scene.objects[elem.element_id];
      if (entity) {
        const color = this.hexToRgb(elem.progress_color);
        entity.colorize = color;
      }
    });
  }

  hexToRgb(hex: string): [number, number, number] {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? [
      parseInt(result[1], 16) / 255,
      parseInt(result[2], 16) / 255,
      parseInt(result[3], 16) / 255
    ] : [0.5, 0.5, 0.5];
  }
}
