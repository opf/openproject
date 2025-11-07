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

export interface SectionBox {
  id: string;
  min: [number, number, number];
  max: [number, number, number];
  enabled: boolean;
}

export interface SectionPlane {
  id: string;
  pos: [number, number, number];
  dir: [number, number, number];
  enabled: boolean;
}

export interface SectionConfig {
  id?: number;
  name: string;
  description?: string;
  section_boxes: SectionBox[];
  section_planes: SectionPlane[];
  show_edges: boolean;
  edge_color: string;
  show_fills: boolean;
  fill_color: string;
  fill_opacity: number;
  is_public: boolean;
}

/**
 * Manages section boxes and section planes for the 3D viewer
 * Provides clipping functionality for better model visualization
 */
@Injectable()
export class SectionManagerService {
  private viewer:any; // xeokit Viewer instance
  private sectionBoxes:Map<string, any> = new Map();
  private sectionPlanes:Map<string, any> = new Map();
  private nextId = 0;

  initialize(viewer:any):void {
    this.viewer = viewer;
    this.sectionBoxes.clear();
    this.sectionPlanes.clear();
  }

  /**
   * Create a new section box that clips the model
   */
  createSectionBox(options?: {
    min?: [number, number, number];
    max?: [number, number, number];
    enabled?: boolean;
  }):SectionBox {
    const scene = this.viewer.scene;
    const aabb = scene.aabb; // Model bounding box

    const id = `section-box-${this.nextId++}`;
    const min = options?.min || aabb.slice(0, 3) as [number, number, number];
    const max = options?.max || aabb.slice(3, 6) as [number, number, number];
    const enabled = options?.enabled !== false;

    // Create 6 section planes for the box (top, bottom, left, right, front, back)
    const planes:any[] = [];

    // Bottom plane (Y-)
    planes.push(scene.createSectionPlane({
      id: `${id}-bottom`,
      pos: [0, min[1], 0],
      dir: [0, -1, 0],
      active: enabled,
    }));

    // Top plane (Y+)
    planes.push(scene.createSectionPlane({
      id: `${id}-top`,
      pos: [0, max[1], 0],
      dir: [0, 1, 0],
      active: enabled,
    }));

    // Left plane (X-)
    planes.push(scene.createSectionPlane({
      id: `${id}-left`,
      pos: [min[0], 0, 0],
      dir: [-1, 0, 0],
      active: enabled,
    }));

    // Right plane (X+)
    planes.push(scene.createSectionPlane({
      id: `${id}-right`,
      pos: [max[0], 0, 0],
      dir: [1, 0, 0],
      active: enabled,
    }));

    // Front plane (Z-)
    planes.push(scene.createSectionPlane({
      id: `${id}-front`,
      pos: [0, 0, min[2]],
      dir: [0, 0, -1],
      active: enabled,
    }));

    // Back plane (Z+)
    planes.push(scene.createSectionPlane({
      id: `${id}-back`,
      pos: [0, 0, max[2]],
      dir: [0, 0, 1],
      active: enabled,
    }));

    const sectionBox:SectionBox = {
      id,
      min,
      max,
      enabled,
    };

    this.sectionBoxes.set(id, { box: sectionBox, planes });

    return sectionBox;
  }

  /**
   * Update an existing section box
   */
  updateSectionBox(id:string, updates:Partial<Omit<SectionBox, 'id'>>):void {
    const boxData = this.sectionBoxes.get(id);
    if (!boxData) {
      console.warn(`Section box ${id} not found`);
      return;
    }

    const { box, planes } = boxData;

    if (updates.min !== undefined) {
      box.min = updates.min;
      planes[0].pos = [0, updates.min[1], 0]; // Bottom
      planes[2].pos = [updates.min[0], 0, 0]; // Left
      planes[4].pos = [0, 0, updates.min[2]]; // Front
    }

    if (updates.max !== undefined) {
      box.max = updates.max;
      planes[1].pos = [0, updates.max[1], 0]; // Top
      planes[3].pos = [updates.max[0], 0, 0]; // Right
      planes[5].pos = [0, 0, updates.max[2]]; // Back
    }

    if (updates.enabled !== undefined) {
      box.enabled = updates.enabled;
      planes.forEach((plane:any) => {
        plane.active = updates.enabled;
      });
    }
  }

  /**
   * Remove a section box
   */
  removeSectionBox(id:string):void {
    const boxData = this.sectionBoxes.get(id);
    if (!boxData) {
      return;
    }

    // Destroy all section planes for this box
    boxData.planes.forEach((plane:any) => {
      plane.destroy();
    });

    this.sectionBoxes.delete(id);
  }

  /**
   * Get all section boxes
   */
  getSectionBoxes():SectionBox[] {
    return Array.from(this.sectionBoxes.values()).map((data) => data.box);
  }

  /**
   * Create a new section plane
   */
  createSectionPlane(options: {
    pos: [number, number, number];
    dir: [number, number, number];
    enabled?: boolean;
  }):SectionPlane {
    const id = `section-plane-${this.nextId++}`;
    const enabled = options.enabled !== false;

    const plane = this.viewer.scene.createSectionPlane({
      id,
      pos: options.pos,
      dir: options.dir,
      active: enabled,
    });

    const sectionPlane:SectionPlane = {
      id,
      pos: options.pos,
      dir: options.dir,
      enabled,
    };

    this.sectionPlanes.set(id, { plane: sectionPlane, xeokitPlane: plane });

    return sectionPlane;
  }

  /**
   * Update an existing section plane
   */
  updateSectionPlane(id:string, updates:Partial<Omit<SectionPlane, 'id'>>):void {
    const planeData = this.sectionPlanes.get(id);
    if (!planeData) {
      console.warn(`Section plane ${id} not found`);
      return;
    }

    const { plane, xeokitPlane } = planeData;

    if (updates.pos !== undefined) {
      plane.pos = updates.pos;
      xeokitPlane.pos = updates.pos;
    }

    if (updates.dir !== undefined) {
      plane.dir = updates.dir;
      xeokitPlane.dir = updates.dir;
    }

    if (updates.enabled !== undefined) {
      plane.enabled = updates.enabled;
      xeokitPlane.active = updates.enabled;
    }
  }

  /**
   * Remove a section plane
   */
  removeSectionPlane(id:string):void {
    const planeData = this.sectionPlanes.get(id);
    if (!planeData) {
      return;
    }

    planeData.xeokitPlane.destroy();
    this.sectionPlanes.delete(id);
  }

  /**
   * Get all section planes
   */
  getSectionPlanes():SectionPlane[] {
    return Array.from(this.sectionPlanes.values()).map((data) => data.plane);
  }

  /**
   * Clear all section boxes and planes
   */
  clearAll():void {
    this.sectionBoxes.forEach((boxData) => {
      boxData.planes.forEach((plane:any) => plane.destroy());
    });
    this.sectionBoxes.clear();

    this.sectionPlanes.forEach((planeData) => {
      planeData.xeokitPlane.destroy();
    });
    this.sectionPlanes.clear();
  }

  /**
   * Load a section configuration
   */
  loadConfiguration(config:SectionConfig):void {
    this.clearAll();

    // Load section boxes
    config.section_boxes?.forEach((box) => {
      this.createSectionBox({
        min: box.min,
        max: box.max,
        enabled: box.enabled,
      });
    });

    // Load section planes
    config.section_planes?.forEach((plane) => {
      this.createSectionPlane({
        pos: plane.pos,
        dir: plane.dir,
        enabled: plane.enabled,
      });
    });
  }

  /**
   * Export current section configuration
   */
  exportConfiguration():SectionConfig {
    return {
      name: 'Untitled Configuration',
      section_boxes: this.getSectionBoxes(),
      section_planes: this.getSectionPlanes(),
      show_edges: true,
      edge_color: '#000000',
      show_fills: false,
      fill_color: '#FF0000',
      fill_opacity: 0.5,
      is_public: false,
    };
  }
}
