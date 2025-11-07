/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Injectable } from '@angular/core';

export type RelationshipType = 'affected_by' | 'responsible_for' | 'depends_on' | 'observes' | 'related_to';
export type LinkStatus = 'active' | 'completed' | 'archived';

export interface ElementLink {
  id?: number;
  work_package_id: number;
  ifc_model_id: number;
  element_id: string;
  element_type?: string;
  element_name?: string;
  relationship_type: RelationshipType;
  status: LinkStatus;
  element_properties?: Record<string, any>;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

export interface ElementMetadata {
  id: string;
  type: string;
  name?: string;
  properties?: Record<string, any>;
  quantities?: Record<string, number>;
  geometry?: {
    hash?: string;
    boundingBox?: {
      min: [number, number, number];
      max: [number, number, number];
    };
  };
  spatial_structure?: {
    building?: string;
    storey?: string;
    space?: string;
  };
  classification?: {
    system?: string;
    code?: string;
  };
}

export interface BulkLinkRequest {
  element_ids: string[];
  work_package_id?: number;
  relationship_type: RelationshipType;
  description?: string;
}

/**
 * Manages links between work packages and BIM elements
 * Supports many-to-many relationships with typed associations
 */
@Injectable()
export class ElementLinkManagerService {
  private viewer:any; // xeokit Viewer instance
  private links:Map<string, ElementLink> = new Map();
  private selectedElements:Set<string> = new Set();
  private linkMode:RelationshipType | null = null;
  private currentWorkPackage:number | null = null;

  initialize(viewer:any):void {
    this.viewer = viewer;
    this.links.clear();
    this.selectedElements.clear();
  }

  /**
   * Start element selection mode for linking
   */
  startLinkingMode(workPackageId:number, relationshipType:RelationshipType):void {
    this.currentWorkPackage = workPackageId;
    this.linkMode = relationshipType;
    this.selectedElements.clear();
    this.enableElementSelection();
  }

  /**
   * Stop element selection mode
   */
  stopLinkingMode():void {
    this.linkMode = null;
    this.currentWorkPackage = null;
    this.selectedElements.clear();
    this.disableElementSelection();
  }

  /**
   * Add element to selection
   */
  selectElement(elementId:string):void {
    if (!this.linkMode) {
      console.warn('Not in linking mode');
      return;
    }

    this.selectedElements.add(elementId);
    this.highlightElement(elementId, true);
  }

  /**
   * Remove element from selection
   */
  deselectElement(elementId:string):void {
    this.selectedElements.delete(elementId);
    this.highlightElement(elementId, false);
  }

  /**
   * Toggle element selection
   */
  toggleElementSelection(elementId:string):void {
    if (this.selectedElements.has(elementId)) {
      this.deselectElement(elementId);
    } else {
      this.selectElement(elementId);
    }
  }

  /**
   * Get currently selected elements
   */
  getSelectedElements():string[] {
    return Array.from(this.selectedElements);
  }

  /**
   * Clear all selected elements
   */
  clearSelection():void {
    this.selectedElements.forEach((elementId) => {
      this.highlightElement(elementId, false);
    });
    this.selectedElements.clear();
  }

  /**
   * Create link between work package and element
   */
  async createLink(linkData:Omit<ElementLink, 'id'>):Promise<ElementLink> {
    // This would call the backend API
    // For now, store locally
    const link:ElementLink = {
      ...linkData,
      id: Date.now(), // Temporary ID
      created_at: new Date().toISOString(),
    };

    this.links.set(`${linkData.work_package_id}-${linkData.element_id}`, link);
    return link;
  }

  /**
   * Create multiple links from selected elements
   */
  async createLinksFromSelection(
    workPackageId:number,
    relationshipType:RelationshipType,
    description?:string,
  ):Promise<ElementLink[]> {
    const elementIds = this.getSelectedElements();

    if (elementIds.length === 0) {
      throw new Error('No elements selected');
    }

    const links:ElementLink[] = [];

    for (const elementId of elementIds) {
      const metadata = await this.getElementMetadata(elementId);

      const link = await this.createLink({
        work_package_id: workPackageId,
        ifc_model_id: this.getCurrentModelId(),
        element_id: elementId,
        element_type: metadata?.type,
        element_name: metadata?.name,
        relationship_type: relationshipType,
        status: 'active',
        element_properties: metadata,
        description,
      });

      links.push(link);
    }

    this.clearSelection();
    return links;
  }

  /**
   * Remove link
   */
  async removeLink(linkId:number):Promise<void> {
    // Find and remove link
    for (const [key, link] of this.links.entries()) {
      if (link.id === linkId) {
        this.links.delete(key);
        break;
      }
    }
  }

  /**
   * Update link status
   */
  async updateLinkStatus(linkId:number, status:LinkStatus):Promise<ElementLink | undefined> {
    for (const link of this.links.values()) {
      if (link.id === linkId) {
        link.status = status;
        link.updated_at = new Date().toISOString();
        return link;
      }
    }
    return undefined;
  }

  /**
   * Get all links for a work package
   */
  getLinksForWorkPackage(workPackageId:number):ElementLink[] {
    return Array.from(this.links.values()).filter(
      (link) => link.work_package_id === workPackageId,
    );
  }

  /**
   * Get all links for an element
   */
  getLinksForElement(elementId:string):ElementLink[] {
    return Array.from(this.links.values()).filter(
      (link) => link.element_id === elementId,
    );
  }

  /**
   * Get links by relationship type
   */
  getLinksByRelationship(relationshipType:RelationshipType):ElementLink[] {
    return Array.from(this.links.values()).filter(
      (link) => link.relationship_type === relationshipType,
    );
  }

  /**
   * Get links by status
   */
  getLinksByStatus(status:LinkStatus):ElementLink[] {
    return Array.from(this.links.values()).filter(
      (link) => link.status === status,
    );
  }

  /**
   * Check if element is linked to work package
   */
  isElementLinked(elementId:string, workPackageId:number):boolean {
    return this.links.has(`${workPackageId}-${elementId}`);
  }

  /**
   * Get element metadata from viewer
   */
  private async getElementMetadata(elementId:string):Promise<ElementMetadata | null> {
    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return null;

    // Extract metadata from xeokit entity
    const metadata:ElementMetadata = {
      id: elementId,
      type: entity.type || 'Unknown',
      name: entity.name,
    };

    // Get properties if available
    if (entity.properties) {
      metadata.properties = entity.properties;
    }

    // Get bounding box
    if (entity.aabb) {
      metadata.geometry = {
        boundingBox: {
          min: entity.aabb.slice(0, 3) as [number, number, number],
          max: entity.aabb.slice(3, 6) as [number, number, number],
        },
      };
    }

    return metadata;
  }

  /**
   * Get current IFC model ID
   */
  private getCurrentModelId():number {
    // This should be obtained from the current context
    // For now, return a placeholder
    return 1;
  }

  /**
   * Highlight element in viewer
   */
  private highlightElement(elementId:string, selected:boolean):void {
    const entity = this.viewer.scene.objects[elementId];
    if (!entity) return;

    if (selected) {
      entity.selected = true;
      entity.highlighted = true;
    } else {
      entity.selected = false;
      entity.highlighted = false;
    }
  }

  /**
   * Enable element selection in viewer
   */
  private enableElementSelection():void {
    // Configure viewer for element selection mode
    if (this.viewer) {
      this.viewer.scene.input.setEnabled(true);
      // Additional selection mode configuration
    }
  }

  /**
   * Disable element selection in viewer
   */
  private disableElementSelection():void {
    if (this.viewer) {
      // Restore normal viewer mode
    }
  }

  /**
   * Visualize links in viewer
   */
  visualizeLinks(links:ElementLink[], highlightType?:RelationshipType):void {
    const colorMap:Record<RelationshipType, [number, number, number]> = {
      affected_by: [1.0, 0.0, 0.0],     // Red
      responsible_for: [0.0, 1.0, 0.0], // Green
      depends_on: [0.0, 0.0, 1.0],      // Blue
      observes: [1.0, 1.0, 0.0],        // Yellow
      related_to: [0.5, 0.5, 0.5],      // Gray
    };

    links.forEach((link) => {
      if (link.status !== 'active') return;
      if (highlightType && link.relationship_type !== highlightType) return;

      const entity = this.viewer.scene.objects[link.element_id];
      if (!entity) return;

      const color = colorMap[link.relationship_type];
      entity.colorize = color;
    });
  }

  /**
   * Clear link visualization
   */
  clearLinkVisualization():void {
    const scene = this.viewer.scene;
    Object.values(scene.objects).forEach((entity:any) => {
      entity.colorize = null;
    });
  }

  /**
   * Get element statistics for work package
   */
  getElementStatistics(workPackageId:number):{
    total: number;
    by_type: Record<string, number>;
    by_relationship: Record<RelationshipType, number>;
    by_status: Record<LinkStatus, number>;
  } {
    const links = this.getLinksForWorkPackage(workPackageId);

    const stats = {
      total: links.length,
      by_type: {} as Record<string, number>,
      by_relationship: {} as Record<RelationshipType, number>,
      by_status: {} as Record<LinkStatus, number>,
    };

    links.forEach((link) => {
      // Count by type
      const type = link.element_type || 'Unknown';
      stats.by_type[type] = (stats.by_type[type] || 0) + 1;

      // Count by relationship
      stats.by_relationship[link.relationship_type] =
        (stats.by_relationship[link.relationship_type] || 0) + 1;

      // Count by status
      stats.by_status[link.status] = (stats.by_status[link.status] || 0) + 1;
    });

    return stats;
  }

  /**
   * Load links from backend
   */
  loadLinks(links:ElementLink[]):void {
    links.forEach((link) => {
      this.links.set(`${link.work_package_id}-${link.element_id}`, link);
    });
  }

  /**
   * Get all links
   */
  getAllLinks():ElementLink[] {
    return Array.from(this.links.values());
  }
}
