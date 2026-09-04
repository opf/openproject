import { Component, Input, OnInit, OnDestroy, Output, EventEmitter } from '@angular/core';
import { FederationService, FederationViewerConfig, FederationModel } from './federation.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

export interface DisciplineToggle {
  discipline: string;
  name: string;
  color: string;
  icon: string;
  visible: boolean;
  opacity: number;
  models: FederationModel[];
}

@Component({
  selector: 'op-federated-viewer',
  templateUrl: './federated-viewer.component.html',
  styleUrls: ['./federated-viewer.component.sass']
})
export class FederatedViewerComponent implements OnInit, OnDestroy {
  @Input() projectId!: number;
  @Input() federationId!: number;
  @Input() viewer: any; // xeokit viewer instance

  @Output() loaded = new EventEmitter<FederationViewerConfig>();
  @Output() modelVisibilityChanged = new EventEmitter<{ discipl: string; visible: boolean }>();

  federationConfig?: FederationViewerConfig;
  disciplines: DisciplineToggle[] = [];
  visibleModels: FederationModel[] = [];
  loading = true;
  error?: string;

  private destroy$ = new Subject<void>();

  constructor(private federationService: FederationService) {}

  ngOnInit(): void {
    this.loadFederation();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Load federation configuration and initialize viewer
   */
  loadFederation(): void {
    if (!this.projectId || !this.federationId) {
      this.error = 'Project ID and Federation ID are required';
      this.loading = false;
      return;
    }

    this.loading = true;
    this.federationService
      .getViewerConfig(this.projectId, this.federationId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (config) => {
          this.federationConfig = config;
          this.initializeDisciplines(config);
          this.updateVisibleModels();
          this.loadModelsIntoViewer(config);
          this.loading = false;
          this.loaded.emit(config);
        },
        error: (err) => {
          this.error = `Failed to load federation: ${err.message}`;
          this.loading = false;
        }
      });
  }

  /**
   * Initialize discipline toggles from federation models
   */
  private initializeDisciplines(config: FederationViewerConfig): void {
    const disciplineMap = new Map<string, FederationModel[]>();

    // Group models by discipline
    config.models.forEach(model => {
      const discipline = model.discipline || 'other';
      if (!disciplineMap.has(discipline)) {
        disciplineMap.set(discipline, []);
      }
      disciplineMap.get(discipline)!.push(model as FederationModel);
    });

    // Create discipline toggles
    this.disciplines = Array.from(disciplineMap.entries()).map(([discipline, models]) => ({
      discipline,
      name: this.formatDisciplineName(discipline),
      color: this.federationService.getDisciplineColor(discipline),
      icon: this.federationService.getDisciplineIcon(discipline),
      visible: models[0]?.visible ?? true,
      opacity: models[0]?.opacity ?? 1.0,
      models
    }));

    // Sort by discipline name
    this.disciplines.sort((a, b) => a.name.localeCompare(b.name));
  }

  /**
   * Toggle discipline visibility
   */
  toggleDiscipline(discipline: DisciplineToggle): void {
    discipline.visible = !discipline.visible;
    this.updateVisibleModels();
    this.applyDisciplineVisibility(discipline);
    this.modelVisibilityChanged.emit({
      discipl: discipline.discipline,
      visible: discipline.visible
    });
  }

  /**
   * Update discipline opacity
   */
  updateOpacity(discipline: DisciplineToggle, value: number): void {
    discipline.opacity = value;
    this.applyDisciplineOpacity(discipline);
  }

  /**
   * Show all disciplines
   */
  showAll(): void {
    this.disciplines.forEach(d => {
      d.visible = true;
    });
    this.updateVisibleModels();
    this.disciplines.forEach(d => this.applyDisciplineVisibility(d));
  }

  /**
   * Hide all disciplines
   */
  hideAll(): void {
    this.disciplines.forEach(d => {
      d.visible = false;
    });
    this.updateVisibleModels();
    this.disciplines.forEach(d => this.applyDisciplineVisibility(d));
  }

  /**
   * Update list of visible models based on discipline toggles
   */
  private updateVisibleModels(): void {
    this.visibleModels = this.disciplines
      .filter(d => d.visible)
      .flatMap(d => d.models);
  }

  /**
   * Load all federation models into xeokit viewer
   */
  private loadModelsIntoViewer(config: FederationViewerConfig): void {
    if (!this.viewer) {
      console.warn('Viewer not initialized');
      return;
    }

    // Load each model with its transformation
    config.models.forEach((modelConfig, index) => {
      if (!modelConfig.visible) return;

      const xktUrl = `/api/v3/bim/ifc_models/${modelConfig.ifc_model_id}/xkt`;

      // Apply transformation matrix
      const position = modelConfig.transform.translation || [0, 0, 0];
      const rotation = modelConfig.transform.rotation || [0, 0, 0];
      const scale = modelConfig.transform.scale || [1, 1, 1];

      const modelId = `model_${modelConfig.ifc_model_id}`;

      this.viewer.loadModel({
        id: modelId,
        src: xktUrl,
        position,
        rotation,
        scale,
        edges: true,
        saoEnabled: true,
        opacity: modelConfig.opacity || 1.0
      });

      // Apply discipline color if specified
      if (modelConfig.color) {
        setTimeout(() => {
          this.applyModelColor(modelId, modelConfig.color);
        }, 1000 * (index + 1)); // Stagger color application
      }
    });
  }

  /**
   * Apply visibility to all models in a discipline
   */
  private applyDisciplineVisibility(discipline: DisciplineToggle): void {
    if (!this.viewer) return;

    discipline.models.forEach(model => {
      const modelId = `model_${model.ifc_model.id}`;
      const xktModel = this.viewer.scene.models[modelId];

      if (xktModel) {
        xktModel.visible = discipline.visible;
      }
    });
  }

  /**
   * Apply opacity to all models in a discipline
   */
  private applyDisciplineOpacity(discipline: DisciplineToggle): void {
    if (!this.viewer) return;

    discipline.models.forEach(model => {
      const modelId = `model_${model.ifc_model.id}`;
      const xktModel = this.viewer.scene.models[modelId];

      if (xktModel) {
        xktModel.opacity = discipline.opacity;
      }
    });
  }

  /**
   * Apply color to entire model
   */
  private applyModelColor(modelId: string, color: string): void {
    const xktModel = this.viewer?.scene.models[modelId];
    if (!xktModel) return;

    // Convert hex color to RGB array
    const rgb = this.hexToRgb(color);
    if (!rgb) return;

    // Apply color to all objects in model
    xktModel.objectIds.forEach((objectId: string) => {
      const entity = this.viewer.scene.objects[objectId];
      if (entity) {
        entity.colorize = [rgb.r / 255, rgb.g / 255, rgb.b / 255];
      }
    });
  }

  /**
   * Convert hex color to RGB
   */
  private hexToRgb(hex: string): { r: number; g: number; b: number } | null {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
      ? {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16)
        }
      : null;
  }

  /**
   * Format discipline name for display
   */
  private formatDisciplineName(discipline: string): string {
    return discipline.charAt(0).toUpperCase() + discipline.slice(1);
  }

  /**
   * Get total model count
   */
  getTotalModels(): number {
    return this.federationConfig?.models.length || 0;
  }

  /**
   * Get visible model count
   */
  getVisibleCount(): number {
    return this.visibleModels.length;
  }
}
