/**
 * Clash Management Panel Component
 *
 * Provides comprehensive UI for managing clash detection and resolution:
 * - View and filter clashes
 * - Run clash detection
 * - Approve/resolve clashes
 * - Assign clashes to work packages
 * - Visualize clashes in 3D viewer
 * - Group and analyze clashes
 *
 * Usage:
 *   <op-clash-management-panel
 *     [ifcModelId]="modelId"
 *     [viewer]="xeokitViewer"
 *     (clashSelected)="onClashSelected($event)">
 *   </op-clash-management-panel>
 */

import { Component, Input, Output, EventEmitter, OnInit, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

export interface Clash {
  id: number;
  element_a_id: string;
  element_b_id: string;
  clash_type: 'hard' | 'soft' | 'clearance' | 'workflow';
  severity: 'critical' | 'major' | 'minor';
  status: 'new' | 'active' | 'approved' | 'resolved' | 'closed';
  distance?: number;
  overlap_volume?: number;
  clash_point?: { x: number; y: number; z: number };
  detected_at: string;
  work_package_id?: number;
  assigned_to_id?: number;
  resolution_type?: string;
  resolution_comment?: string;
}

export interface ClashStatistics {
  total_clashes: number;
  by_type: Record<string, number>;
  by_severity: Record<string, number>;
  by_status: Record<string, number>;
}

export interface DetectionOptions {
  clearance_distance: number;
  soft_clash_distance: number;
  detect_hard_clashes: boolean;
  detect_soft_clashes: boolean;
  element_types?: string[];
}

@Component({
  selector: 'op-clash-management-panel',
  templateUrl: './clash-management-panel.component.html',
  styleUrls: ['./clash-management-panel.component.scss']
})
export class ClashManagementPanelComponent implements OnInit, OnDestroy {
  @Input() ifcModelId!: number;
  @Input() viewer: any; // xeokit Viewer instance

  @Output() clashSelected = new EventEmitter<Clash>();
  @Output() clashResolved = new EventEmitter<number>();
  @Output() detectionCompleted = new EventEmitter<number>();

  // Component state
  clashes: Clash[] = [];
  filteredClashes: Clash[] = [];
  selectedClash: Clash | null = null;
  statistics: ClashStatistics | null = null;

  // Active tab
  activeTab: 'clashes' | 'detection' | 'groups' | 'statistics' = 'clashes';

  // Filters
  filters = {
    status: 'all',
    severity: 'all',
    clashType: 'all',
    search: ''
  };

  // Detection options
  detectionOptions: DetectionOptions = {
    clearance_distance: 50.0,
    soft_clash_distance: 100.0,
    detect_hard_clashes: true,
    detect_soft_clashes: true,
    element_types: []
  };

  // Detection state
  isDetecting = false;
  detectionProgress = 0;
  lastDetectionResults: any = null;

  // Grouping
  groupingMode: 'element' | 'spatial' | 'type' | 'location' | null = null;
  clashGroups: any[] = [];

  // Loading states
  isLoading = false;
  isLoadingStatistics = false;

  // Pagination
  currentPage = 1;
  perPage = 20;
  totalClashes = 0;

  private destroy$ = new Subject<void>();

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadClashes();
    this.loadStatistics();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Load clashes from API
   */
  loadClashes(): void {
    this.isLoading = true;

    const params: any = {
      ifc_model_id: this.ifcModelId,
      page: this.currentPage,
      per_page: this.perPage
    };

    if (this.filters.status !== 'all') {
      params.status = this.filters.status;
    }
    if (this.filters.severity !== 'all') {
      params.severity = this.filters.severity;
    }
    if (this.filters.clashType !== 'all') {
      params.clash_type = this.filters.clashType;
    }

    this.http.get<any>('/api/v3/bim/clashes', { params })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.clashes = response.clashes || [];
          this.totalClashes = response.total || 0;
          this.applyFilters();
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Failed to load clashes:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Load clash statistics
   */
  loadStatistics(): void {
    this.isLoadingStatistics = true;

    this.http.get<ClashStatistics>(`/api/v3/bim/clashes/statistics`, {
      params: { ifc_model_id: this.ifcModelId.toString() }
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (stats) => {
          this.statistics = stats;
          this.isLoadingStatistics = false;
        },
        error: (error) => {
          console.error('Failed to load statistics:', error);
          this.isLoadingStatistics = false;
        }
      });
  }

  /**
   * Apply filters to clash list
   */
  applyFilters(): void {
    this.filteredClashes = this.clashes.filter(clash => {
      // Search filter
      if (this.filters.search) {
        const search = this.filters.search.toLowerCase();
        const matches = clash.element_a_id.toLowerCase().includes(search) ||
                       clash.element_b_id.toLowerCase().includes(search);
        if (!matches) return false;
      }

      return true;
    });
  }

  /**
   * Handle filter change
   */
  onFilterChange(): void {
    this.currentPage = 1;
    this.loadClashes();
  }

  /**
   * Select a clash
   */
  selectClash(clash: Clash): void {
    this.selectedClash = clash;
    this.clashSelected.emit(clash);

    // Visualize in viewer if available
    if (this.viewer && clash.clash_point) {
      this.flyToClash(clash);
      this.highlightClashElements(clash);
    }
  }

  /**
   * Run clash detection
   */
  runDetection(): void {
    this.isDetecting = true;
    this.detectionProgress = 0;

    const params = {
      ifc_model_id: this.ifcModelId,
      ...this.detectionOptions
    };

    this.http.post<any>('/api/v3/bim/clashes/detect', params)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          this.lastDetectionResults = result;
          this.detectionProgress = 100;
          this.isDetecting = false;

          // Reload clashes
          this.loadClashes();
          this.loadStatistics();

          this.detectionCompleted.emit(result.count);
        },
        error: (error) => {
          console.error('Detection failed:', error);
          this.isDetecting = false;
          this.detectionProgress = 0;
        }
      });
  }

  /**
   * Approve clash as acceptable
   */
  approveClash(clash: Clash): void {
    const comment = prompt('Add approval comment (optional):');

    this.http.post(`/api/v3/bim/clashes/${clash.id}/approve`, { comment })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          clash.status = 'approved';
          this.loadStatistics();
        },
        error: (error) => {
          console.error('Failed to approve clash:', error);
        }
      });
  }

  /**
   * Resolve clash
   */
  resolveClash(clash: Clash): void {
    const resolutionType = prompt('Resolution type (redesign/relocated/removed/phased/false_positive):');
    if (!resolutionType) return;

    const comment = prompt('Add resolution comment (optional):');

    this.http.post(`/api/v3/bim/clashes/${clash.id}/resolve`, {
      resolution_type: resolutionType,
      comment
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          clash.status = 'resolved';
          this.clashResolved.emit(clash.id);
          this.loadStatistics();
        },
        error: (error) => {
          console.error('Failed to resolve clash:', error);
        }
      });
  }

  /**
   * Delete clash
   */
  deleteClash(clash: Clash): void {
    if (!confirm('Are you sure you want to delete this clash?')) return;

    this.http.delete(`/api/v3/bim/clashes/${clash.id}`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.clashes = this.clashes.filter(c => c.id !== clash.id);
          this.applyFilters();
          this.loadStatistics();
        },
        error: (error) => {
          console.error('Failed to delete clash:', error);
        }
      });
  }

  /**
   * Group clashes by strategy
   */
  groupClashes(strategy: 'element' | 'spatial' | 'type' | 'location'): void {
    this.groupingMode = strategy;
    this.clashGroups = [];

    // This would call a grouping service endpoint
    // For now, we'll do basic client-side grouping

    switch (strategy) {
      case 'element':
        this.groupByElement();
        break;
      case 'type':
        this.groupByType();
        break;
      case 'location':
        this.groupByStatus(); // Placeholder
        break;
    }
  }

  /**
   * Group clashes by element (client-side simplified)
   */
  private groupByElement(): void {
    const elementMap = new Map<string, Clash[]>();

    this.clashes.forEach(clash => {
      [clash.element_a_id, clash.element_b_id].forEach(elementId => {
        if (!elementMap.has(elementId)) {
          elementMap.set(elementId, []);
        }
        elementMap.get(elementId)!.push(clash);
      });
    });

    this.clashGroups = Array.from(elementMap.entries())
      .map(([elementId, clashes]) => ({
        key: elementId,
        clashes: clashes,
        count: clashes.length
      }))
      .filter(group => group.count >= 2)
      .sort((a, b) => b.count - a.count);
  }

  /**
   * Group clashes by type
   */
  private groupByType(): void {
    const typeMap = new Map<string, Clash[]>();

    this.clashes.forEach(clash => {
      const key = clash.clash_type;
      if (!typeMap.has(key)) {
        typeMap.set(key, []);
      }
      typeMap.get(key)!.push(clash);
    });

    this.clashGroups = Array.from(typeMap.entries())
      .map(([type, clashes]) => ({
        key: type,
        clashes: clashes,
        count: clashes.length
      }))
      .sort((a, b) => b.count - a.count);
  }

  /**
   * Group clashes by status
   */
  private groupByStatus(): void {
    const statusMap = new Map<string, Clash[]>();

    this.clashes.forEach(clash => {
      const key = clash.status;
      if (!statusMap.has(key)) {
        statusMap.set(key, []);
      }
      statusMap.get(key)!.push(clash);
    });

    this.clashGroups = Array.from(statusMap.entries())
      .map(([status, clashes]) => ({
        key: status,
        clashes: clashes,
        count: clashes.length
      }))
      .sort((a, b) => b.count - a.count);
  }

  /**
   * Fly camera to clash location in 3D viewer
   */
  private flyToClash(clash: Clash): void {
    if (!this.viewer || !clash.clash_point) return;

    const camera = this.viewer.camera;
    camera.flyTo({
      eye: [
        clash.clash_point.x + 3000,
        clash.clash_point.y + 3000,
        clash.clash_point.z + 2000
      ],
      look: [
        clash.clash_point.x,
        clash.clash_point.y,
        clash.clash_point.z
      ],
      up: [0, 0, 1],
      duration: 1.0
    });
  }

  /**
   * Highlight clash elements in 3D viewer
   */
  private highlightClashElements(clash: Clash): void {
    if (!this.viewer) return;

    // Clear previous highlighting
    this.viewer.scene.setObjectsSelected(this.viewer.scene.selectedObjectIds, false);
    this.viewer.scene.setObjectsHighlighted(this.viewer.scene.highlightedObjectIds, false);

    // Highlight clash elements
    const elementIds = [clash.element_a_id, clash.element_b_id];
    elementIds.forEach(elementId => {
      const entity = this.viewer.scene.objects[elementId];
      if (entity) {
        entity.highlighted = true;
        entity.selected = true;
      }
    });

    // Color code by severity
    const color = this.getSeverityColor(clash.severity);
    elementIds.forEach(elementId => {
      const entity = this.viewer.scene.objects[elementId];
      if (entity) {
        entity.colorize = color;
      }
    });
  }

  /**
   * Get color for severity level
   */
  private getSeverityColor(severity: string): [number, number, number] {
    switch (severity) {
      case 'critical':
        return [1.0, 0.0, 0.0]; // Red
      case 'major':
        return [1.0, 0.5, 0.0]; // Orange
      case 'minor':
        return [1.0, 1.0, 0.0]; // Yellow
      default:
        return [0.5, 0.5, 0.5]; // Gray
    }
  }

  /**
   * Change page
   */
  changePage(page: number): void {
    this.currentPage = page;
    this.loadClashes();
  }

  /**
   * Get severity badge class
   */
  getSeverityClass(severity: string): string {
    return `clash-severity--${severity}`;
  }

  /**
   * Get status badge class
   */
  getStatusClass(status: string): string {
    return `clash-status--${status}`;
  }

  /**
   * Get clash type display name
   */
  getClashTypeName(type: string): string {
    const names: Record<string, string> = {
      hard: 'Hard Clash',
      soft: 'Soft Clash',
      clearance: 'Clearance',
      workflow: 'Workflow'
    };
    return names[type] || type;
  }

  /**
   * Helper to get object keys for template iteration
   */
  objectKeys(obj: any): string[] {
    return obj ? Object.keys(obj) : [];
  }

  /**
   * Expose Math to template
   */
  Math = Math;
}
