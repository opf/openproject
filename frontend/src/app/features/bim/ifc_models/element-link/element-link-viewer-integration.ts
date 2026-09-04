/**
 * ElementLinkViewerIntegration
 *
 * Integrates element linking functionality with xeokit-bim-viewer.
 * Handles:
 * - Element selection events
 * - Visual highlighting of linked elements
 * - 3D navigation to linked elements
 * - Link visualization overlays
 */

import { Viewer } from '@xeokit/xeokit-sdk/dist/xeokit-sdk.es.js';
import { ElementLinkManager, ElementLink, RelationshipType } from './element-link-manager.service';

export interface ViewerIntegrationConfig {
  viewer: Viewer;
  linkManager: ElementLinkManager;
  onElementSelected?: (elementId: string) => void;
  onElementDeselected?: (elementId: string) => void;
  onLinkVisualized?: (links: ElementLink[]) => void;
}

export class ElementLinkViewerIntegration {
  private viewer: Viewer;
  private linkManager: ElementLinkManager;
  private config: ViewerIntegrationConfig;
  private selectedElements: Set<string> = new Set();
  private visualizedLinks: Map<number, string[]> = new Map(); // linkId -> elementIds
  private originalColors: Map<string, [number, number, number, number]> = new Map();

  // Color mapping for relationship types
  private readonly relationshipColors: Record<RelationshipType, [number, number, number]> = {
    affected_by: [1.0, 0.0, 0.0],      // Red
    responsible_for: [0.0, 1.0, 0.0],  // Green
    depends_on: [0.0, 0.0, 1.0],       // Blue
    observes: [1.0, 1.0, 0.0],         // Yellow
    related_to: [0.5, 0.5, 0.5]        // Gray
  };

  constructor(config: ViewerIntegrationConfig) {
    this.config = config;
    this.viewer = config.viewer;
    this.linkManager = config.linkManager;
    this.initialize();
  }

  /**
   * Initialize viewer integration
   */
  private initialize(): void {
    // Listen for entity pick events
    this.viewer.scene.input.on('mouseclicked', (coords: number[]) => {
      const hit = this.viewer.scene.pick({
        canvasPos: coords,
        pickSurface: true
      });

      if (hit && hit.entity) {
        this.onEntityClicked(hit.entity.id);
      }
    });

    // Listen for entity hover events
    this.viewer.scene.input.on('mousemove', (coords: number[]) => {
      const hit = this.viewer.scene.pick({
        canvasPos: coords
      });

      if (hit && hit.entity) {
        this.onEntityHovered(hit.entity.id);
      }
    });
  }

  /**
   * Handle entity click
   */
  private onEntityClicked(entityId: string): void {
    if (this.selectedElements.has(entityId)) {
      this.deselectElement(entityId);
    } else {
      this.selectElement(entityId);
    }
  }

  /**
   * Handle entity hover
   */
  private onEntityHovered(entityId: string): void {
    // Show tooltip with element info and links
    const links = this.linkManager.getLinksForElement(entityId);
    if (links.length > 0) {
      this.showLinkTooltip(entityId, links);
    }
  }

  /**
   * Select an element
   */
  selectElement(elementId: string): void {
    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return;

    this.selectedElements.add(elementId);

    // Highlight selected element
    entity.selected = true;
    entity.highlighted = true;

    // Notify callback
    if (this.config.onElementSelected) {
      this.config.onElementSelected(elementId);
    }
  }

  /**
   * Deselect an element
   */
  deselectElement(elementId: string): void {
    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return;

    this.selectedElements.delete(elementId);

    // Remove highlight
    entity.selected = false;
    entity.highlighted = false;

    // Notify callback
    if (this.config.onElementDeselected) {
      this.config.onElementDeselected(elementId);
    }
  }

  /**
   * Clear all selections
   */
  clearSelection(): void {
    this.selectedElements.forEach(elementId => {
      this.deselectElement(elementId);
    });
    this.selectedElements.clear();
  }

  /**
   * Visualize links in the viewer
   */
  visualizeLinks(links: ElementLink[], highlightType?: RelationshipType): void {
    // Store original colors
    links.forEach(link => {
      const entity = this.viewer.scene.objects[link.element_id];
      if (entity && !this.originalColors.has(link.element_id)) {
        this.originalColors.set(link.element_id, entity.colorize || [1, 1, 1, 1]);
      }
    });

    // Apply colors based on relationship type
    links.forEach(link => {
      const entity = this.viewer.scene.objects[link.element_id];
      if (!entity) return;

      const color = this.relationshipColors[link.relationship_type];
      const alpha = (highlightType && link.relationship_type !== highlightType) ? 0.3 : 1.0;

      entity.colorize = [...color, alpha] as [number, number, number, number];
      entity.opacity = alpha;

      // Store visualization
      if (!this.visualizedLinks.has(link.id)) {
        this.visualizedLinks.set(link.id, []);
      }
      this.visualizedLinks.get(link.id)!.push(link.element_id);
    });

    // Notify callback
    if (this.config.onLinkVisualized) {
      this.config.onLinkVisualized(links);
    }
  }

  /**
   * Clear link visualization
   */
  clearVisualization(): void {
    // Restore original colors
    this.originalColors.forEach((color, elementId) => {
      const entity = this.viewer.scene.objects[elementId];
      if (entity) {
        entity.colorize = color;
        entity.opacity = 1.0;
      }
    });

    this.originalColors.clear();
    this.visualizedLinks.clear();
  }

  /**
   * Fly to an element (navigate camera)
   */
  flyToElement(elementId: string, duration = 1.0): void {
    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return;

    this.viewer.cameraFlight.flyTo({
      aabb: entity.aabb,
      duration: duration
    });

    // Briefly highlight the element
    entity.highlighted = true;
    setTimeout(() => {
      entity.highlighted = false;
    }, 2000);
  }

  /**
   * Fly to multiple elements (fit all in view)
   */
  flyToElements(elementIds: string[], duration = 1.0): void {
    const entities = elementIds
      .map(id => this.viewer.scene.objects[id])
      .filter(entity => entity !== undefined);

    if (entities.length === 0) return;

    // Calculate combined AABB
    const aabb = this.calculateCombinedAABB(entities);

    this.viewer.cameraFlight.flyTo({
      aabb: aabb,
      duration: duration
    });
  }

  /**
   * Show tooltip for an element with link information
   */
  private showLinkTooltip(elementId: string, links: ElementLink[]): void {
    // This would integrate with your tooltip system
    // For now, just log to console
    console.log(`Element ${elementId} has ${links.length} links:`, links);
  }

  /**
   * Calculate combined AABB for multiple entities
   */
  private calculateCombinedAABB(entities: any[]): number[] {
    let xmin = Infinity, ymin = Infinity, zmin = Infinity;
    let xmax = -Infinity, ymax = -Infinity, zmax = -Infinity;

    entities.forEach(entity => {
      const aabb = entity.aabb;
      xmin = Math.min(xmin, aabb[0]);
      ymin = Math.min(ymin, aabb[1]);
      zmin = Math.min(zmin, aabb[2]);
      xmax = Math.max(xmax, aabb[3]);
      ymax = Math.max(ymax, aabb[4]);
      zmax = Math.max(zmax, aabb[5]);
    });

    return [xmin, ymin, zmin, xmax, ymax, zmax];
  }

  /**
   * Isolate elements (hide everything else)
   */
  isolateElements(elementIds: string[]): void {
    // Hide all objects
    Object.values(this.viewer.scene.objects).forEach((entity: any) => {
      entity.visible = false;
    });

    // Show only specified elements
    elementIds.forEach(elementId => {
      const entity = this.viewer.scene.objects[elementId];
      if (entity) {
        entity.visible = true;
      }
    });
  }

  /**
   * Show all elements (undo isolation)
   */
  showAllElements(): void {
    Object.values(this.viewer.scene.objects).forEach((entity: any) => {
      entity.visible = true;
    });
  }

  /**
   * Create visual connection lines between work package and elements
   */
  createLinkLines(links: ElementLink[], workPackagePosition?: [number, number, number]): void {
    // This would create actual 3D lines in the viewer
    // Implementation depends on your specific requirements
    // Could use xeokit's annotation system or custom geometries
    console.log('Creating visual link lines for', links.length, 'links');
  }

  /**
   * Get currently selected element IDs
   */
  getSelectedElementIds(): string[] {
    return Array.from(this.selectedElements);
  }

  /**
   * Check if an element is linked
   */
  isElementLinked(elementId: string): boolean {
    return this.linkManager.getLinksForElement(elementId).length > 0;
  }

  /**
   * Get link statistics for visible elements
   */
  getVisibleElementsStatistics(): {
    total: number;
    linked: number;
    unlinked: number;
    by_relationship: Record<RelationshipType, number>;
  } {
    const visibleEntities = Object.values(this.viewer.scene.objects)
      .filter((entity: any) => entity.visible);

    const stats = {
      total: visibleEntities.length,
      linked: 0,
      unlinked: 0,
      by_relationship: {
        affected_by: 0,
        responsible_for: 0,
        depends_on: 0,
        observes: 0,
        related_to: 0
      } as Record<RelationshipType, number>
    };

    visibleEntities.forEach((entity: any) => {
      const links = this.linkManager.getLinksForElement(entity.id);
      if (links.length > 0) {
        stats.linked++;
        links.forEach(link => {
          stats.by_relationship[link.relationship_type]++;
        });
      } else {
        stats.unlinked++;
      }
    });

    return stats;
  }

  /**
   * Destroy integration and clean up
   */
  destroy(): void {
    this.clearSelection();
    this.clearVisualization();
    this.originalColors.clear();
    this.visualizedLinks.clear();
  }
}

/**
 * Factory function to create viewer integration
 */
export function createViewerIntegration(
  viewer: any,
  linkManager: ElementLinkManager,
  callbacks?: {
    onElementSelected?: (elementId: string) => void;
    onElementDeselected?: (elementId: string) => void;
    onLinkVisualized?: (links: ElementLink[]) => void;
  }
): ElementLinkViewerIntegration {
  return new ElementLinkViewerIntegration({
    viewer,
    linkManager,
    ...callbacks
  });
}
