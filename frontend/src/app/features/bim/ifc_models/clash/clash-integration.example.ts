/**
 * Clash Detection Integration Example
 *
 * This file demonstrates how to integrate clash detection functionality
 * into an IFC viewer application. It shows:
 * - Component setup
 * - Clash visualization
 * - Event handling
 * - Viewer integration
 *
 * Usage: Copy and adapt this example to your IFC viewer component
 */

import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

// Import clash types
import { Clash } from './clash-management-panel.component';

/**
 * Example IFC Viewer Component with Clash Detection
 */
@Component({
  selector: 'op-ifc-viewer-with-clashes',
  template: `
    <div class="viewer-container">
      <!-- xeokit viewer canvas -->
      <div #viewerCanvas class="viewer-canvas"></div>

      <!-- Clash Management Panel (right sidebar) -->
      <op-clash-management-panel
        *ngIf="showClashPanel"
        class="clash-panel"
        [ifcModelId]="ifcModelId"
        [viewer]="viewer"
        (clashSelected)="onClashSelected($event)"
        (clashResolved)="onClashResolved($event)"
        (detectionCompleted)="onDetectionCompleted($event)">
      </op-clash-management-panel>

      <!-- Toolbar -->
      <div class="viewer-toolbar">
        <button (click)="toggleClashPanel()">
          {{ showClashPanel ? 'Hide' : 'Show' }} Clashes
        </button>
        <button (click)="runQuickDetection()">
          Quick Detection
        </button>
        <button (click)="showCriticalClashes()">
          Show Critical Only
        </button>
        <button (click)="clearHighlights()">
          Clear Highlights
        </button>
      </div>

      <!-- Status Bar -->
      <div class="status-bar">
        <span>Total Clashes: {{ totalClashes }}</span>
        <span>Critical: {{ criticalClashes }}</span>
        <span>Unresolved: {{ unresolvedClashes }}</span>
      </div>
    </div>
  `,
  styles: [`
    .viewer-container {
      position: relative;
      width: 100%;
      height: 100%;
      display: flex;
    }

    .viewer-canvas {
      flex: 1;
      position: relative;
    }

    .clash-panel {
      width: 450px;
      height: 100%;
      overflow-y: auto;
    }

    .viewer-toolbar {
      position: absolute;
      top: 16px;
      left: 16px;
      display: flex;
      gap: 8px;
      background: rgba(255, 255, 255, 0.95);
      padding: 8px;
      border-radius: 4px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    }

    .status-bar {
      position: absolute;
      bottom: 16px;
      left: 16px;
      right: 16px;
      display: flex;
      gap: 24px;
      background: rgba(255, 255, 255, 0.95);
      padding: 12px 16px;
      border-radius: 4px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      font-size: 14px;
      font-weight: 500;
    }
  `]
})
export class IfcViewerWithClashesExampleComponent implements OnInit, OnDestroy {
  @ViewChild('viewerCanvas', { static: true }) viewerCanvas!: ElementRef;

  // Required inputs (would come from route params or parent component)
  ifcModelId = 456;

  // Viewer instance
  viewer: any; // xeokit Viewer instance

  // UI state
  showClashPanel = true;
  totalClashes = 0;
  criticalClashes = 0;
  unresolvedClashes = 0;

  // Currently highlighted clashes
  highlightedClashes: Clash[] = [];

  private destroy$ = new Subject<void>();

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    // Initialize viewer
    this.initializeViewer();

    // Load clash statistics
    this.loadClashStatistics();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();

    if (this.viewer) {
      this.viewer.destroy();
    }
  }

  /**
   * Initialize xeokit viewer
   */
  private initializeViewer(): void {
    // Import and initialize xeokit viewer
    // This is a simplified example - actual implementation would be more complex
    const Viewer = (window as any).xeokit.Viewer;

    this.viewer = new Viewer({
      canvasElement: this.viewerCanvas.nativeElement,
      transparent: true
    });

    // Load IFC model
    this.loadIfcModel();
  }

  /**
   * Load IFC model into viewer
   */
  private loadIfcModel(): void {
    // This would load your actual IFC model
    // Example using XKT format:
    const XKTLoaderPlugin = (window as any).xeokit.XKTLoaderPlugin;
    const xktLoader = new XKTLoaderPlugin(this.viewer);

    const model = xktLoader.load({
      id: `model-${this.ifcModelId}`,
      src: `/api/v3/bim/ifc_models/${this.ifcModelId}/xkt`,
      edges: true
    });

    model.on('loaded', () => {
      console.log('IFC model loaded');

      // Fit model in view
      this.viewer.cameraFlight.flyTo({
        aabb: this.viewer.scene.aabb
      });
    });
  }

  /**
   * Load clash statistics
   */
  private loadClashStatistics(): void {
    this.http.get<any>(`/api/v3/bim/clashes/statistics`, {
      params: { ifc_model_id: this.ifcModelId.toString() }
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (stats) => {
          this.totalClashes = stats.total_clashes || 0;
          this.criticalClashes = stats.by_severity?.critical || 0;
          this.unresolvedClashes = (stats.by_status?.new || 0) + (stats.by_status?.active || 0);
        },
        error: (error) => {
          console.error('Failed to load statistics:', error);
        }
      });
  }

  /**
   * Handle clash selection from panel
   */
  onClashSelected(clash: Clash): void {
    console.log('Clash selected:', clash);

    // Fly to clash location
    if (clash.clash_point) {
      this.viewer.cameraFlight.flyTo({
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

    // Highlight involved elements
    this.highlightClashElements(clash);

    // Add clash point marker (optional)
    if (clash.clash_point) {
      this.addClashMarker(clash);
    }
  }

  /**
   * Handle clash resolution
   */
  onClashResolved(clashId: number): void {
    console.log('Clash resolved:', clashId);

    // Reload statistics
    this.loadClashStatistics();

    // Clear highlights
    this.clearHighlights();
  }

  /**
   * Handle detection completion
   */
  onDetectionCompleted(clashCount: number): void {
    console.log('Detection completed, found clashes:', clashCount);

    // Reload statistics
    this.loadClashStatistics();

    // Optionally visualize all clashes
    this.visualizeAllClashes();
  }

  /**
   * Highlight clash elements in viewer
   */
  private highlightClashElements(clash: Clash): void {
    // Clear previous highlights
    this.clearHighlights();

    // Get severity color
    const color = this.getSeverityColor(clash.severity);

    // Highlight elements
    const elementIds = [clash.element_a_id, clash.element_b_id];
    elementIds.forEach(elementId => {
      const entity = this.viewer.scene.objects[elementId];
      if (entity) {
        entity.highlighted = true;
        entity.selected = true;
        entity.colorize = color;
      }
    });

    this.highlightedClashes = [clash];
  }

  /**
   * Add marker at clash point
   */
  private addClashMarker(clash: Clash): void {
    if (!clash.clash_point) return;

    // This would use a xeokit marker plugin or custom geometry
    // Simplified example:
    console.log('Adding clash marker at:', clash.clash_point);

    // Example: Create a small sphere at clash point
    // const marker = new Mesh(this.viewer.scene, {
    //   geometry: new SphereGeometry(...),
    //   material: new PhongMaterial(...),
    //   position: [clash.clash_point.x, clash.clash_point.y, clash.clash_point.z]
    // });
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
   * Clear all highlights
   */
  clearHighlights(): void {
    // Clear all highlighting
    const scene = this.viewer.scene;
    scene.setObjectsHighlighted(scene.highlightedObjectIds, false);
    scene.setObjectsSelected(scene.selectedObjectIds, false);

    // Reset colorization
    scene.setObjectsColorized(scene.colorizedObjectIds, null);

    this.highlightedClashes = [];
  }

  /**
   * Toggle clash panel visibility
   */
  toggleClashPanel(): void {
    this.showClashPanel = !this.showClashPanel;
  }

  /**
   * Run quick detection with default settings
   */
  runQuickDetection(): void {
    this.http.post<any>('/api/v3/bim/clashes/detect', {
      ifc_model_id: this.ifcModelId,
      clearance_distance: 50.0,
      detect_hard_clashes: true,
      detect_soft_clashes: true
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          console.log('Detection completed:', result);
          this.onDetectionCompleted(result.count);
        },
        error: (error) => {
          console.error('Detection failed:', error);
        }
      });
  }

  /**
   * Show only critical clashes
   */
  showCriticalClashes(): void {
    this.http.get<any>('/api/v3/bim/clashes', {
      params: {
        ifc_model_id: this.ifcModelId.toString(),
        severity: 'critical'
      }
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const clashes = response.clashes || [];
          console.log('Found critical clashes:', clashes.length);

          // Visualize critical clashes
          this.visualizeClashes(clashes);
        },
        error: (error) => {
          console.error('Failed to load critical clashes:', error);
        }
      });
  }

  /**
   * Visualize multiple clashes
   */
  private visualizeClashes(clashes: Clash[]): void {
    this.clearHighlights();

    clashes.forEach(clash => {
      const color = this.getSeverityColor(clash.severity);
      const elementIds = [clash.element_a_id, clash.element_b_id];

      elementIds.forEach(elementId => {
        const entity = this.viewer.scene.objects[elementId];
        if (entity) {
          entity.colorize = color;
          entity.highlighted = true;
        }
      });
    });

    this.highlightedClashes = clashes;
  }

  /**
   * Visualize all clashes in model
   */
  private visualizeAllClashes(): void {
    this.http.get<any>('/api/v3/bim/clashes', {
      params: {
        ifc_model_id: this.ifcModelId.toString(),
        per_page: '1000'
      }
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const clashes = response.clashes || [];
          this.visualizeClashes(clashes);
        },
        error: (error) => {
          console.error('Failed to load clashes:', error);
        }
      });
  }
}

/**
 * Quick Start Guide
 *
 * 1. Import ClashManagementPanelComponent in your module
 * 2. Add clash panel to your viewer template:
 *    ```html
 *    <op-clash-management-panel
 *      [ifcModelId]="modelId"
 *      [viewer]="xeokitViewer"
 *      (clashSelected)="onClashSelected($event)">
 *    </op-clash-management-panel>
 *    ```
 *
 * 3. Handle clash events in your component:
 *    ```typescript
 *    onClashSelected(clash: Clash): void {
 *      // Fly to clash location
 *      // Highlight elements
 *      // Show clash details
 *    }
 *    ```
 *
 * That's it! You now have full clash detection functionality.
 */
