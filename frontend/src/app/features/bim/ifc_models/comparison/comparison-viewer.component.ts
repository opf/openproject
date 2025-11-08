/**
 * Model Comparison Viewer Component
 *
 * Displays IFC model comparison results with:
 * - Change summary statistics
 * - Element-level change details
 * - Visual diff in 3D viewer (color-coded)
 * - Approval/rejection workflow
 *
 * Usage:
 *   <op-comparison-viewer
 *     [comparison]="comparisonData"
 *     [viewer]="xeokitViewer"
 *     (approved)="onApproved($event)"
 *     (rejected)="onRejected($event)">
 *   </op-comparison-viewer>
 */

import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export interface ModelComparison {
  id: number;
  model1_id: number;
  model2_id: number;
  model1_title: string;
  model2_title: string;
  name?: string;
  added_count: number;
  deleted_count: number;
  modified_count: number;
  unchanged_count: number;
  total_changes: number;
  change_percentage: number;
  status: 'pending' | 'completed' | 'approved' | 'rejected';
  changes_data?: {
    added: Array<any>;
    deleted: Array<any>;
    modified: Array<any>;
  };
}

@Component({
  selector: 'op-comparison-viewer',
  template: `
    <div class="comparison-viewer">
      <div class="comparison-header">
        <h3>{{ comparison.name || (comparison.model1_title + ' vs ' + comparison.model2_title) }}</h3>
        <span class="status-badge" [class]="'status--' + comparison.status">
          {{ comparison.status }}
        </span>
      </div>

      <div class="comparison-summary">
        <div class="stat-card stat-card--added">
          <div class="stat-value">{{ comparison.added_count }}</div>
          <div class="stat-label">Added</div>
        </div>
        <div class="stat-card stat-card--deleted">
          <div class="stat-value">{{ comparison.deleted_count }}</div>
          <div class="stat-label">Deleted</div>
        </div>
        <div class="stat-card stat-card--modified">
          <div class="stat-value">{{ comparison.modified_count }}</div>
          <div class="stat-label">Modified</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ comparison.change_percentage }}%</div>
          <div class="stat-label">Changed</div>
        </div>
      </div>

      <div class="comparison-actions" *ngIf="comparison.status === 'completed'">
        <button class="button button--success" (click)="approveComparison()">
          Approve Changes
        </button>
        <button class="button button--danger" (click)="rejectComparison()">
          Reject Changes
        </button>
      </div>

      <div class="comparison-details" *ngIf="comparison.changes_data">
        <h4>Change Details</h4>

        <div class="change-section" *ngIf="comparison.changes_data.added?.length > 0">
          <h5>Added Elements ({{ comparison.added_count }})</h5>
          <ul class="element-list">
            <li *ngFor="let elem of comparison.changes_data.added.slice(0, 10)"
                (click)="highlightElement(elem.element_id, 'added')">
              {{ elem.element?.properties?.name || elem.element_id }}
              <span class="element-type">{{ elem.element?.properties?.type }}</span>
            </li>
          </ul>
        </div>

        <div class="change-section" *ngIf="comparison.changes_data.deleted?.length > 0">
          <h5>Deleted Elements ({{ comparison.deleted_count }})</h5>
          <ul class="element-list">
            <li *ngFor="let elem of comparison.changes_data.deleted.slice(0, 10)"
                (click)="highlightElement(elem.element_id, 'deleted')">
              {{ elem.element?.properties?.name || elem.element_id }}
              <span class="element-type">{{ elem.element?.properties?.type }}</span>
            </li>
          </ul>
        </div>

        <div class="change-section" *ngIf="comparison.changes_data.modified?.length > 0">
          <h5>Modified Elements ({{ comparison.modified_count }})</h5>
          <ul class="element-list">
            <li *ngFor="let elem of comparison.changes_data.modified.slice(0, 10)"
                (click)="highlightElement(elem.element_id, 'modified')">
              {{ elem.element_after?.properties?.name || elem.element_id }}
              <span class="change-count">{{ elem.changes?.length }} changes</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .comparison-viewer {
      padding: 16px;
      background: #fff;
    }

    .comparison-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      padding-bottom: 12px;
      border-bottom: 2px solid #e0e0e0;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status--completed { background: #e3f2fd; color: #1976d2; }
    .status--approved { background: #e8f5e9; color: #2e7d32; }
    .status--rejected { background: #ffebee; color: #c62828; }

    .comparison-summary {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      padding: 16px;
      text-align: center;
      border-radius: 4px;
      border: 1px solid #e0e0e0;
    }

    .stat-card--added { background: #e8f5e9; border-color: #4caf50; }
    .stat-card--deleted { background: #ffebee; border-color: #f44336; }
    .stat-card--modified { background: #fff3e0; border-color: #ff9800; }

    .stat-value {
      font-size: 32px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 14px;
      color: #666;
      text-transform: uppercase;
    }

    .comparison-actions {
      display: flex;
      gap: 12px;
      margin-bottom: 24px;
    }

    .change-section {
      margin-bottom: 20px;
    }

    .element-list {
      list-style: none;
      padding: 0;
    }

    .element-list li {
      padding: 8px 12px;
      margin-bottom: 4px;
      background: #f5f5f5;
      border-radius: 4px;
      cursor: pointer;
      transition: background 0.2s;
    }

    .element-list li:hover {
      background: #e0e0e0;
    }

    .element-type, .change-count {
      float: right;
      font-size: 12px;
      color: #666;
      padding: 2px 8px;
      background: #fff;
      border-radius: 8px;
    }
  `]
})
export class ComparisonViewerComponent implements OnInit {
  @Input() comparison!: ModelComparison;
  @Input() comparisonId?: number;
  @Input() viewer: any; // xeokit Viewer

  @Output() approved = new EventEmitter<number>();
  @Output() rejected = new EventEmitter<number>();

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    if (this.comparisonId && !this.comparison) {
      this.loadComparison();
    } else if (this.comparison) {
      this.applyVisualDiff();
    }
  }

  loadComparison(): void {
    this.http.get<ModelComparison>(`/api/v3/bim/comparisons/${this.comparisonId}`)
      .subscribe(comparison => {
        this.comparison = comparison;
        this.applyVisualDiff();
      });
  }

  applyVisualDiff(): void {
    if (!this.viewer || !this.comparison.changes_data) return;

    // Color added elements green
    this.comparison.changes_data.added?.forEach(elem => {
      this.colorElement(elem.element_id, [0.0, 1.0, 0.0]);
    });

    // Color deleted elements red
    this.comparison.changes_data.deleted?.forEach(elem => {
      this.colorElement(elem.element_id, [1.0, 0.0, 0.0]);
    });

    // Color modified elements yellow
    this.comparison.changes_data.modified?.forEach(elem => {
      this.colorElement(elem.element_id, [1.0, 1.0, 0.0]);
    });
  }

  highlightElement(elementId: string, changeType: string): void {
    if (!this.viewer) return;

    // Clear previous selection
    this.viewer.scene.setObjectsSelected(this.viewer.scene.selectedObjectIds, false);

    // Select and highlight element
    const entity = this.viewer.scene.objects[elementId];
    if (entity) {
      entity.selected = true;
      entity.highlighted = true;

      // Fly to element
      this.viewer.cameraFlight.flyTo({
        aabb: entity.aabb,
        duration: 1.0
      });
    }
  }

  colorElement(elementId: string, color: [number, number, number]): void {
    const entity = this.viewer?.scene.objects[elementId];
    if (entity) {
      entity.colorize = color;
    }
  }

  approveComparison(): void {
    const comment = prompt('Add approval comment:');
    if (!comment) return;

    this.http.post(`/api/v3/bim/comparisons/${this.comparison.id}/approve`, { comment })
      .subscribe(() => {
        this.comparison.status = 'approved';
        this.approved.emit(this.comparison.id);
      });
  }

  rejectComparison(): void {
    const comment = prompt('Add rejection comment:');
    if (!comment) return;

    this.http.post(`/api/v3/bim/comparisons/${this.comparison.id}/reject`, { comment })
      .subscribe(() => {
        this.comparison.status = 'rejected';
        this.rejected.emit(this.comparison.id);
      });
  }
}
