/**
 * Element Link Integration Example
 *
 * This file demonstrates how to integrate element linking functionality
 * into an IFC viewer application. It shows:
 * - Component setup
 * - Service initialization
 * - Event handling
 * - Viewer integration
 *
 * Usage: Copy and adapt this example to your IFC viewer component
 */

import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

// Import services
import { ElementLinkManager } from './element-link-manager.service';
import { BulkLinkOperationsService } from './bulk-link-operations.service';
import { HttpClient } from '@angular/common/http';

// Import viewer integration
import { createViewerIntegration, ElementLinkViewerIntegration } from './element-link-viewer-integration';

/**
 * Example IFC Viewer Component with Element Linking
 */
@Component({
  selector: 'op-ifc-viewer-with-links',
  template: `
    <div class="viewer-container">
      <!-- xeokit viewer canvas -->
      <div #viewerCanvas class="viewer-canvas"></div>

      <!-- Link Management Panel (right sidebar) -->
      <op-link-management-panel
        *ngIf="showLinkPanel"
        class="link-panel"
        [workPackageId]="workPackageId"
        [ifcModelId]="ifcModelId"
        [viewer]="viewer"
        (linkCreated)="onLinkCreated($event)"
        (linkDeleted)="onLinkDeleted($event)"
        (selectionModeChanged)="onSelectionModeChanged($event)">
      </op-link-management-panel>

      <!-- Toolbar -->
      <div class="viewer-toolbar">
        <button (click)="toggleLinkPanel()">
          {{ showLinkPanel ? 'Hide' : 'Show' }} Links
        </button>
        <button (click)="showLinkedElementsOnly()">
          Show Linked Only
        </button>
        <button (click)="showAllElements()">
          Show All
        </button>
      </div>

      <!-- Status Bar -->
      <div class="status-bar">
        <span>Total Elements: {{ totalElements }}</span>
        <span>Linked: {{ linkedElements }}</span>
        <span>Selected: {{ selectedElements }}</span>
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

    .link-panel {
      width: 400px;
      height: 100%;
      overflow-y: auto;
    }

    .viewer-toolbar {
      position: absolute;
      top: 16px;
      left: 16px;
      display: flex;
      gap: 8px;
      background: rgba(255, 255, 255, 0.9);
      padding: 8px;
      border-radius: 4px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .status-bar {
      position: absolute;
      bottom: 16px;
      left: 16px;
      right: 16px;
      display: flex;
      gap: 16px;
      background: rgba(255, 255, 255, 0.9);
      padding: 8px 16px;
      border-radius: 4px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      font-size: 14px;
    }
  `]
})
export class IfcViewerWithLinksExampleComponent implements OnInit, OnDestroy {
  @ViewChild('viewerCanvas', { static: true }) viewerCanvas!: ElementRef;

  // Required inputs (would come from route params or parent component)
  workPackageId = 123;
  ifcModelId = 456;

  // Viewer and integration
  viewer: any; // xeokit Viewer instance
  viewerIntegration!: ElementLinkViewerIntegration;

  // Services
  linkManager!: ElementLinkManager;
  bulkOperations!: BulkLinkOperationsService;

  // UI state
  showLinkPanel = true;
  totalElements = 0;
  linkedElements = 0;
  selectedElements = 0;

  private destroy$ = new Subject<void>();

  constructor(
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    // Initialize services
    this.initializeServices();

    // Initialize viewer
    this.initializeViewer();

    // Setup viewer integration
    this.setupViewerIntegration();

    // Load initial data
    this.loadInitialData();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();

    if (this.viewerIntegration) {
      this.viewerIntegration.destroy();
    }

    if (this.viewer) {
      this.viewer.destroy();
    }
  }

  /**
   * Initialize linking services
   */
  private initializeServices(): void {
    this.linkManager = new ElementLinkManager(this.http);
    this.bulkOperations = new BulkLinkOperationsService(this.http);
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

    // Update element count
    this.totalElements = Object.keys(this.viewer.scene.objects).length;
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
      this.totalElements = Object.keys(this.viewer.scene.objects).length;
      this.updateLinkedElementsCount();
    });
  }

  /**
   * Setup viewer integration for element linking
   */
  private setupViewerIntegration(): void {
    this.viewerIntegration = createViewerIntegration(
      this.viewer,
      this.linkManager,
      {
        onElementSelected: (elementId: string) => {
          console.log('Element selected:', elementId);
          this.selectedElements++;
        },
        onElementDeselected: (elementId: string) => {
          console.log('Element deselected:', elementId);
          this.selectedElements--;
        },
        onLinkVisualized: (links) => {
          console.log('Links visualized:', links.length);
        }
      }
    );
  }

  /**
   * Load initial data (existing links)
   */
  private loadInitialData(): void {
    this.linkManager.getLinksForWorkPackage(this.workPackageId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (links) => {
          console.log('Loaded existing links:', links.length);
          this.updateLinkedElementsCount();

          // Optionally visualize existing links
          // this.viewerIntegration.visualizeLinks(links);
        },
        error: (error) => {
          console.error('Failed to load links:', error);
        }
      });
  }

  /**
   * Update count of linked elements
   */
  private updateLinkedElementsCount(): void {
    const stats = this.linkManager.getElementStatistics(this.workPackageId);
    this.linkedElements = stats.total;
  }

  /**
   * Handle link creation
   */
  onLinkCreated(link: any): void {
    console.log('Link created:', link);
    this.updateLinkedElementsCount();

    // Visualize the new link
    this.viewerIntegration.visualizeLinks([link]);

    // Optionally fly to the linked element
    this.viewerIntegration.flyToElement(link.element_id);
  }

  /**
   * Handle link deletion
   */
  onLinkDeleted(linkId: number): void {
    console.log('Link deleted:', linkId);
    this.updateLinkedElementsCount();

    // Clear and refresh visualization
    this.viewerIntegration.clearVisualization();
  }

  /**
   * Handle selection mode change
   */
  onSelectionModeChanged(isActive: boolean): void {
    console.log('Selection mode:', isActive ? 'active' : 'inactive');

    if (!isActive) {
      // Clear viewer selection
      this.viewerIntegration.clearSelection();
      this.selectedElements = 0;
    }
  }

  /**
   * Toggle link panel visibility
   */
  toggleLinkPanel(): void {
    this.showLinkPanel = !this.showLinkPanel;
  }

  /**
   * Show only linked elements
   */
  showLinkedElementsOnly(): void {
    const links = this.linkManager.getLinksForWorkPackage(this.workPackageId);
    links.subscribe(linkList => {
      const elementIds = linkList.map(link => link.element_id);
      this.viewerIntegration.isolateElements(elementIds);
    });
  }

  /**
   * Show all elements
   */
  showAllElements(): void {
    this.viewerIntegration.showAllElements();
  }
}

/**
 * Angular Module for Element Linking Feature
 */
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';

import { LinkManagementPanelComponent } from './link-management-panel.component';

@NgModule({
  declarations: [
    LinkManagementPanelComponent,
    // Add other components here
  ],
  imports: [
    CommonModule,
    FormsModule,
    HttpClientModule
  ],
  exports: [
    LinkManagementPanelComponent
  ],
  providers: [
    ElementLinkManager,
    BulkLinkOperationsService
  ]
})
export class ElementLinkModule {}

/**
 * Quick Start Guide
 *
 * 1. Import ElementLinkModule in your IFC viewer module:
 *    ```typescript
 *    import { ElementLinkModule } from './element-link/element-link.module';
 *
 *    @NgModule({
 *      imports: [
 *        ElementLinkModule,
 *        // ...other imports
 *      ]
 *    })
 *    export class IfcViewerModule {}
 *    ```
 *
 * 2. Add link management panel to your viewer template:
 *    ```html
 *    <op-link-management-panel
 *      [workPackageId]="workPackageId"
 *      [ifcModelId]="ifcModelId"
 *      [viewer]="viewer"
 *      (linkCreated)="onLinkCreated($event)"
 *      (linkDeleted)="onLinkDeleted($event)">
 *    </op-link-management-panel>
 *    ```
 *
 * 3. Initialize viewer integration in your component:
 *    ```typescript
 *    this.viewerIntegration = createViewerIntegration(
 *      this.viewer,
 *      this.linkManager
 *    );
 *    ```
 *
 * 4. Handle link events:
 *    ```typescript
 *    onLinkCreated(link: ElementLink): void {
 *      this.viewerIntegration.visualizeLinks([link]);
 *      this.viewerIntegration.flyToElement(link.element_id);
 *    }
 *    ```
 *
 * That's it! You now have full element linking functionality in your IFC viewer.
 */
