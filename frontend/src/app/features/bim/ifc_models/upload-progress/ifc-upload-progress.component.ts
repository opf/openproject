/**
 * IFC Upload Progress Component
 *
 * Displays real-time IFC model upload and conversion progress with:
 * - Multi-stage conversion pipeline visualization (6 stages)
 * - Real-time progress updates via Turbo Streams/WebSockets
 * - Validation warnings and errors display
 * - Conversion logs viewer
 * - Stage-by-stage status indicators
 *
 * Usage:
 *   <op-ifc-upload-progress
 *     [modelId]="123"
 *     (conversionCompleted)="onCompleted($event)">
 *   </op-ifc-upload-progress>
 */

import { Component, Input, Output, EventEmitter, OnInit, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { interval, Subscription } from 'rxjs';
import { switchMap, filter } from 'rxjs/operators';

export interface ConversionStage {
  name: string;
  label: string;
  weight: number;
  status: 'pending' | 'active' | 'completed' | 'error';
  logs: ConversionLog[];
}

export interface ConversionLog {
  timestamp: string;
  stage: string;
  level: 'info' | 'warning' | 'error';
  message: string;
  details?: any;
}

export interface ModelStatus {
  id: number;
  conversion_status: string;
  conversion_stage: string;
  conversion_progress: number;
  conversion_started_at?: string;
  conversion_completed_at?: string;
  conversion_error_message?: string;
  conversion_logs: ConversionLog[];
  metadata_summary?: {
    ifc_version?: string;
    entity_count?: number;
    validation_passed?: boolean;
  };
}

@Component({
  selector: 'op-ifc-upload-progress',
  template: `
    <div class="ifc-upload-progress" *ngIf="modelStatus">
      <!-- Overall Progress Bar -->
      <div class="overall-progress">
        <h3>IFC Model Conversion Progress</h3>
        <div class="progress-header">
          <span class="status-badge" [class]="'status--' + modelStatus.conversion_status">
            {{ modelStatus.conversion_status }}
          </span>
          <span class="progress-percentage">{{ modelStatus.conversion_progress }}%</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill"
               [style.width.%]="modelStatus.conversion_progress"
               [class.error]="modelStatus.conversion_status === 'error'"
               [class.completed]="modelStatus.conversion_status === 'completed'">
          </div>
        </div>
        <div class="progress-info" *ngIf="estimatedTimeRemaining">
          <span>Estimated time remaining: {{ estimatedTimeRemaining }}</span>
        </div>
      </div>

      <!-- Stage Indicators -->
      <div class="stage-indicators">
        <div *ngFor="let stage of stages; let i = index"
             class="stage"
             [class.active]="stage.status === 'active'"
             [class.completed]="stage.status === 'completed'"
             [class.error]="stage.status === 'error'">

          <div class="stage-icon">
            <span *ngIf="stage.status === 'pending'">{{ i + 1 }}</span>
            <span *ngIf="stage.status === 'active'">⟳</span>
            <span *ngIf="stage.status === 'completed'">✓</span>
            <span *ngIf="stage.status === 'error'">✗</span>
          </div>

          <div class="stage-info">
            <div class="stage-name">{{ stage.label }}</div>
            <div class="stage-status">
              <span *ngIf="stage.status === 'active'">In Progress...</span>
              <span *ngIf="stage.status === 'completed'">Completed</span>
              <span *ngIf="stage.status === 'error'">Failed</span>
            </div>
          </div>

          <div class="stage-connector" *ngIf="i < stages.length - 1"></div>
        </div>
      </div>

      <!-- Validation Warnings -->
      <div class="warnings-section" *ngIf="validationWarnings.length > 0">
        <h4>⚠️ Validation Warnings</h4>
        <ul class="warnings-list">
          <li *ngFor="let warning of validationWarnings" class="warning-item">
            {{ warning }}
          </li>
        </ul>
      </div>

      <!-- Error Message -->
      <div class="error-section" *ngIf="modelStatus.conversion_error_message">
        <h4>❌ Conversion Error</h4>
        <div class="error-message">
          {{ modelStatus.conversion_error_message }}
        </div>
        <button class="button button--secondary" (click)="retryConversion()">
          Retry Conversion
        </button>
      </div>

      <!-- Metadata Summary (on completion) -->
      <div class="metadata-summary" *ngIf="modelStatus.conversion_status === 'completed' && modelStatus.metadata_summary">
        <h4>✅ Conversion Completed</h4>
        <div class="metadata-grid">
          <div class="metadata-item" *ngIf="modelStatus.metadata_summary.ifc_version">
            <span class="label">IFC Version:</span>
            <span class="value">{{ modelStatus.metadata_summary.ifc_version }}</span>
          </div>
          <div class="metadata-item" *ngIf="modelStatus.metadata_summary.entity_count">
            <span class="label">Entities:</span>
            <span class="value">{{ modelStatus.metadata_summary.entity_count | number }}</span>
          </div>
          <div class="metadata-item">
            <span class="label">Validation:</span>
            <span class="value" [class.success]="modelStatus.metadata_summary.validation_passed">
              {{ modelStatus.metadata_summary.validation_passed ? 'Passed' : 'Failed' }}
            </span>
          </div>
        </div>
        <div class="actions">
          <button class="button button--primary" (click)="viewModel()">
            View Model
          </button>
          <button class="button button--secondary" (click)="viewMetadata()">
            View Full Metadata
          </button>
        </div>
      </div>

      <!-- Conversion Logs -->
      <div class="logs-section" *ngIf="showLogs">
        <div class="logs-header">
          <h4>Conversion Logs</h4>
          <button class="button button--link" (click)="showLogs = !showLogs">
            {{ showLogs ? 'Hide' : 'Show' }} Logs
          </button>
        </div>
        <div class="logs-list">
          <div *ngFor="let log of filteredLogs"
               class="log-entry"
               [class]="'log--' + log.level">
            <span class="log-timestamp">{{ log.timestamp | date:'HH:mm:ss' }}</span>
            <span class="log-stage">[{{ log.stage }}]</span>
            <span class="log-message">{{ log.message }}</span>
          </div>
        </div>
      </div>

      <!-- Toggle Logs Button -->
      <div class="toggle-logs" *ngIf="!showLogs && modelStatus.conversion_logs.length > 0">
        <button class="button button--link" (click)="showLogs = true">
          Show Conversion Logs ({{ modelStatus.conversion_logs.length }})
        </button>
      </div>
    </div>
  `,
  styles: [`
    .ifc-upload-progress {
      padding: 24px;
      background: #fff;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .overall-progress {
      margin-bottom: 32px;
    }

    .overall-progress h3 {
      margin: 0 0 16px 0;
      font-size: 20px;
      font-weight: 600;
    }

    .progress-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status--pending { background: #e0e0e0; color: #666; }
    .status--processing { background: #fff3e0; color: #f57c00; }
    .status--completed { background: #e8f5e9; color: #2e7d32; }
    .status--error { background: #ffebee; color: #c62828; }

    .progress-percentage {
      font-size: 24px;
      font-weight: 700;
      color: #333;
    }

    .progress-bar {
      height: 12px;
      background: #e0e0e0;
      border-radius: 6px;
      overflow: hidden;
    }

    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #2196f3, #1976d2);
      transition: width 0.5s ease;
      position: relative;
    }

    .progress-fill::after {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: linear-gradient(
        90deg,
        transparent,
        rgba(255,255,255,0.3),
        transparent
      );
      animation: shimmer 2s infinite;
    }

    @keyframes shimmer {
      0% { transform: translateX(-100%); }
      100% { transform: translateX(100%); }
    }

    .progress-fill.completed {
      background: linear-gradient(90deg, #4caf50, #388e3c);
    }

    .progress-fill.error {
      background: linear-gradient(90deg, #f44336, #d32f2f);
    }

    .progress-info {
      margin-top: 8px;
      font-size: 14px;
      color: #666;
    }

    .stage-indicators {
      display: flex;
      justify-content: space-between;
      margin-bottom: 32px;
      position: relative;
    }

    .stage {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      position: relative;
    }

    .stage-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: #e0e0e0;
      color: #666;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 18px;
      margin-bottom: 12px;
      transition: all 0.3s;
      z-index: 1;
    }

    .stage.active .stage-icon {
      background: #2196f3;
      color: #fff;
      animation: pulse 2s infinite;
    }

    .stage.completed .stage-icon {
      background: #4caf50;
      color: #fff;
    }

    .stage.error .stage-icon {
      background: #f44336;
      color: #fff;
    }

    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.1); }
    }

    .stage-info {
      text-align: center;
    }

    .stage-name {
      font-size: 14px;
      font-weight: 600;
      color: #333;
      margin-bottom: 4px;
    }

    .stage-status {
      font-size: 12px;
      color: #666;
    }

    .stage-connector {
      position: absolute;
      top: 24px;
      left: 50%;
      right: -50%;
      height: 2px;
      background: #e0e0e0;
      z-index: 0;
    }

    .stage.completed + .stage .stage-connector {
      background: #4caf50;
    }

    .warnings-section,
    .error-section,
    .metadata-summary,
    .logs-section {
      margin-bottom: 24px;
      padding: 16px;
      border-radius: 4px;
    }

    .warnings-section {
      background: #fff3e0;
      border-left: 4px solid #f57c00;
    }

    .warnings-section h4 {
      margin: 0 0 12px 0;
      color: #f57c00;
      font-size: 16px;
    }

    .warnings-list {
      margin: 0;
      padding-left: 20px;
    }

    .warning-item {
      margin-bottom: 8px;
      color: #666;
    }

    .error-section {
      background: #ffebee;
      border-left: 4px solid #f44336;
    }

    .error-section h4 {
      margin: 0 0 12px 0;
      color: #c62828;
      font-size: 16px;
    }

    .error-message {
      padding: 12px;
      background: #fff;
      border-radius: 4px;
      font-family: monospace;
      font-size: 13px;
      color: #333;
      margin-bottom: 12px;
    }

    .metadata-summary {
      background: #e8f5e9;
      border-left: 4px solid #4caf50;
    }

    .metadata-summary h4 {
      margin: 0 0 16px 0;
      color: #2e7d32;
      font-size: 18px;
    }

    .metadata-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 16px;
    }

    .metadata-item {
      display: flex;
      justify-content: space-between;
      padding: 8px 12px;
      background: #fff;
      border-radius: 4px;
    }

    .metadata-item .label {
      font-weight: 600;
      color: #666;
    }

    .metadata-item .value {
      color: #333;
    }

    .metadata-item .value.success {
      color: #2e7d32;
      font-weight: 600;
    }

    .actions {
      display: flex;
      gap: 12px;
    }

    .logs-section {
      background: #fafafa;
      border: 1px solid #e0e0e0;
    }

    .logs-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .logs-header h4 {
      margin: 0;
      font-size: 16px;
    }

    .logs-list {
      max-height: 300px;
      overflow-y: auto;
      background: #fff;
      border-radius: 4px;
      padding: 12px;
    }

    .log-entry {
      padding: 8px;
      margin-bottom: 4px;
      font-size: 13px;
      font-family: monospace;
      border-radius: 2px;
    }

    .log--info {
      background: #f5f5f5;
      color: #333;
    }

    .log--warning {
      background: #fff3e0;
      color: #f57c00;
    }

    .log--error {
      background: #ffebee;
      color: #c62828;
    }

    .log-timestamp {
      color: #999;
      margin-right: 8px;
    }

    .log-stage {
      color: #666;
      font-weight: 600;
      margin-right: 8px;
    }

    .toggle-logs {
      text-align: center;
    }

    .button--link {
      background: none;
      border: none;
      color: #2196f3;
      cursor: pointer;
      text-decoration: underline;
    }

    .button--link:hover {
      color: #1976d2;
    }
  `]
})
export class IfcUploadProgressComponent implements OnInit, OnDestroy {
  @Input() modelId!: number;
  @Output() conversionCompleted = new EventEmitter<ModelStatus>();
  @Output() conversionError = new EventEmitter<string>();

  modelStatus: ModelStatus | null = null;
  validationWarnings: string[] = [];
  estimatedTimeRemaining: string | null = null;
  showLogs = false;

  stages: ConversionStage[] = [
    { name: 'validation', label: 'Validation', weight: 5, status: 'pending', logs: [] },
    { name: 'ifc_to_dae', label: 'IFC → DAE', weight: 20, status: 'pending', logs: [] },
    { name: 'dae_to_gltf', label: 'DAE → glTF', weight: 20, status: 'pending', logs: [] },
    { name: 'gltf_to_xkt', label: 'glTF → XKT', weight: 40, status: 'pending', logs: [] },
    { name: 'enhanced_metadata', label: 'Metadata', weight: 15, status: 'pending', logs: [] }
  ];

  filteredLogs: ConversionLog[] = [];
  private pollSubscription?: Subscription;
  private startTime?: Date;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadModelStatus();
    this.startPolling();
  }

  ngOnDestroy(): void {
    this.stopPolling();
  }

  loadModelStatus(): void {
    this.http.get<ModelStatus>(`/api/v3/bim/ifc_models/${this.modelId}`)
      .subscribe(status => {
        this.modelStatus = status;
        this.updateStageStatuses();
        this.loadConversionLogs();

        if (status.conversion_status === 'completed') {
          this.stopPolling();
          this.conversionCompleted.emit(status);
        } else if (status.conversion_status === 'error') {
          this.stopPolling();
          this.conversionError.emit(status.conversion_error_message || 'Unknown error');
        }

        if (status.conversion_started_at && !this.startTime) {
          this.startTime = new Date(status.conversion_started_at);
        }

        this.updateEstimatedTime();
      });
  }

  loadConversionLogs(): void {
    this.http.get<{logs: ConversionLog[]}>(`/api/v3/bim/ifc_models/${this.modelId}/conversion_logs`)
      .subscribe(response => {
        this.filteredLogs = response.logs;

        // Extract validation warnings
        this.validationWarnings = response.logs
          .filter(log => log.stage === 'validation' && log.level === 'warning')
          .map(log => log.message);

        // Group logs by stage
        this.stages.forEach(stage => {
          stage.logs = response.logs.filter(log => log.stage === stage.name);
        });
      });
  }

  updateStageStatuses(): void {
    if (!this.modelStatus) return;

    const currentStage = this.modelStatus.conversion_stage;
    const status = this.modelStatus.conversion_status;

    this.stages.forEach((stage, index) => {
      if (status === 'error' && stage.name === currentStage) {
        stage.status = 'error';
      } else if (stage.name === currentStage && status === 'processing') {
        stage.status = 'active';
      } else {
        // Mark previous stages as completed
        const currentIndex = this.stages.findIndex(s => s.name === currentStage);
        if (index < currentIndex) {
          stage.status = 'completed';
        } else if (index === currentIndex && status === 'completed') {
          stage.status = 'completed';
        } else {
          stage.status = 'pending';
        }
      }
    });

    // If conversion completed, mark all as completed
    if (status === 'completed') {
      this.stages.forEach(stage => stage.status = 'completed');
    }
  }

  updateEstimatedTime(): void {
    if (!this.modelStatus || !this.startTime) {
      this.estimatedTimeRemaining = null;
      return;
    }

    const progress = this.modelStatus.conversion_progress;
    if (progress === 0) {
      this.estimatedTimeRemaining = 'Calculating...';
      return;
    }

    const elapsed = Date.now() - this.startTime.getTime();
    const totalEstimated = (elapsed / progress) * 100;
    const remaining = totalEstimated - elapsed;

    const minutes = Math.floor(remaining / 60000);
    const seconds = Math.floor((remaining % 60000) / 1000);

    if (minutes > 0) {
      this.estimatedTimeRemaining = `${minutes}m ${seconds}s`;
    } else {
      this.estimatedTimeRemaining = `${seconds}s`;
    }
  }

  startPolling(): void {
    // Poll every 2 seconds while conversion is in progress
    this.pollSubscription = interval(2000)
      .pipe(
        filter(() => this.modelStatus?.conversion_status === 'processing'),
        switchMap(() => this.http.get<ModelStatus>(`/api/v3/bim/ifc_models/${this.modelId}`))
      )
      .subscribe(status => {
        this.modelStatus = status;
        this.updateStageStatuses();
        this.loadConversionLogs();
        this.updateEstimatedTime();

        if (status.conversion_status === 'completed') {
          this.conversionCompleted.emit(status);
        } else if (status.conversion_status === 'error') {
          this.conversionError.emit(status.conversion_error_message || 'Unknown error');
        }
      });
  }

  stopPolling(): void {
    if (this.pollSubscription) {
      this.pollSubscription.unsubscribe();
    }
  }

  retryConversion(): void {
    // TODO: Implement retry logic
    // This would trigger a new conversion job
    alert('Retry conversion - not yet implemented');
  }

  viewModel(): void {
    // TODO: Navigate to model viewer
    window.location.href = `/bcf/projects/${this.modelStatus!.id}/frontend`;
  }

  viewMetadata(): void {
    this.http.get(`/api/v3/bim/ifc_models/${this.modelId}/metadata`)
      .subscribe(metadata => {
        // TODO: Show metadata in modal/panel
        console.log('Metadata:', metadata);
      });
  }
}
