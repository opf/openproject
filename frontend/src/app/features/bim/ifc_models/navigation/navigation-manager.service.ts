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

export type NavigationMode = 'orbit' | 'walk' | 'fly' | 'plan';
export type PredefinedView = 'north' | 'south' | 'east' | 'west' | 'top' | 'bottom' | 'isometric';
export type ProjectionType = 'perspective' | 'orthogonal';

export interface SavedView {
  id?: number;
  name: string;
  description?: string;
  eye: [number, number, number];
  look: [number, number, number];
  up: [number, number, number];
  projection: ProjectionType;
  is_public?: boolean;
}

export interface CameraAnimation {
  duration: number; // milliseconds
  easing?: 'linear' | 'easeInOut' | 'easeIn' | 'easeOut';
}

/**
 * Manages camera navigation and saved views for the 3D viewer
 * Provides orbit, walk, fly, and plan navigation modes
 * Supports saved camera positions and predefined views
 */
@Injectable()
export class NavigationManagerService {
  private viewer:any; // xeokit Viewer instance
  private currentMode:NavigationMode = 'orbit';
  private savedViews:Map<string, SavedView> = new Map();
  private collisionEnabled = false;
  private walkSpeed = 5.0; // meters per second
  private flySpeed = 10.0; // meters per second

  initialize(viewer:any):void {
    this.viewer = viewer;
    this.savedViews.clear();
    this.setNavigationMode('orbit');
  }

  /**
   * Set the navigation mode
   */
  setNavigationMode(mode:NavigationMode):void {
    if (!this.viewer) {
      console.warn('Viewer not initialized');
      return;
    }

    this.currentMode = mode;
    const cameraControl = this.viewer.cameraControl;

    switch (mode) {
      case 'orbit':
        cameraControl.navMode = 'orbit';
        cameraControl.followPointer = false;
        cameraControl.doublePickFlyTo = true;
        this.collisionEnabled = false;
        break;

      case 'walk':
        cameraControl.navMode = 'firstPerson';
        cameraControl.followPointer = true;
        cameraControl.doublePickFlyTo = false;
        cameraControl.keyboardLayout = 'qwerty';
        this.collisionEnabled = true;
        this.setWalkSpeed(this.walkSpeed);
        break;

      case 'fly':
        cameraControl.navMode = 'firstPerson';
        cameraControl.followPointer = true;
        cameraControl.doublePickFlyTo = false;
        this.collisionEnabled = false;
        this.setFlySpeed(this.flySpeed);
        break;

      case 'plan':
        cameraControl.navMode = 'planView';
        cameraControl.followPointer = false;
        this.setPlanView();
        break;
    }
  }

  /**
   * Get current navigation mode
   */
  getCurrentMode():NavigationMode {
    return this.currentMode;
  }

  /**
   * Set walk speed (meters per second)
   */
  setWalkSpeed(speed:number):void {
    this.walkSpeed = speed;
    if (this.viewer && this.currentMode === 'walk') {
      this.viewer.cameraControl.walkSpeed = speed;
    }
  }

  /**
   * Set fly speed (meters per second)
   */
  setFlySpeed(speed:number):void {
    this.flySpeed = speed;
    if (this.viewer && this.currentMode === 'fly') {
      this.viewer.cameraControl.panSpeed = speed;
    }
  }

  /**
   * Save current camera view
   */
  saveCurrentView(name:string, description?:string):SavedView {
    const camera = this.viewer.camera;
    const view:SavedView = {
      name,
      description,
      eye: camera.eye.slice() as [number, number, number],
      look: camera.look.slice() as [number, number, number],
      up: camera.up.slice() as [number, number, number],
      projection: camera.projection as ProjectionType,
      is_public: false,
    };

    this.savedViews.set(name, view);
    return view;
  }

  /**
   * Restore a saved view with optional animation
   */
  restoreView(nameOrView:string | SavedView, animation?:CameraAnimation):void {
    const view = typeof nameOrView === 'string'
      ? this.savedViews.get(nameOrView)
      : nameOrView;

    if (!view) {
      console.warn(`View not found: ${nameOrView}`);
      return;
    }

    if (animation) {
      this.animateToView(view, animation);
    } else {
      this.setViewImmediate(view);
    }
  }

  /**
   * Set view immediately without animation
   */
  private setViewImmediate(view:SavedView):void {
    const camera = this.viewer.camera;
    camera.eye = view.eye;
    camera.look = view.look;
    camera.up = view.up;
    camera.projection = view.projection;
  }

  /**
   * Animate camera to view
   */
  private animateToView(view:SavedView, animation:CameraAnimation):void {
    const camera = this.viewer.camera;
    const startEye = camera.eye.slice();
    const startLook = camera.look.slice();
    const startUp = camera.up.slice();
    const duration = animation.duration || 1000;
    const easing = animation.easing || 'easeInOut';

    const startTime = Date.now();

    const animate = () => {
      const elapsed = Date.now() - startTime;
      const t = Math.min(elapsed / duration, 1.0);
      const easedT = this.applyEasing(t, easing);

      camera.eye = this.interpolateVec3(startEye, view.eye, easedT);
      camera.look = this.interpolateVec3(startLook, view.look, easedT);
      camera.up = this.interpolateVec3(startUp, view.up, easedT);

      if (t < 1.0) {
        requestAnimationFrame(animate);
      } else {
        camera.projection = view.projection;
      }
    };

    animate();
  }

  /**
   * Set a predefined view
   */
  setPredefinedView(view:PredefinedView, animation?:CameraAnimation):void {
    const scene = this.viewer.scene;
    const aabb = scene.aabb;

    // Calculate model center
    const center:[number, number, number] = [
      (aabb[0] + aabb[3]) / 2,
      (aabb[1] + aabb[4]) / 2,
      (aabb[2] + aabb[5]) / 2,
    ];

    // Calculate appropriate distance based on model size
    const distance = Math.max(
      aabb[3] - aabb[0],
      aabb[4] - aabb[1],
      aabb[5] - aabb[2],
    ) * 1.5;

    const viewConfig = this.getPredefinedViewConfig(view, center, distance);

    if (animation) {
      this.animateToView(viewConfig, animation);
    } else {
      this.setViewImmediate(viewConfig);
    }
  }

  /**
   * Get predefined view configuration
   */
  private getPredefinedViewConfig(
    view:PredefinedView,
    center:[number, number, number],
    distance:number,
  ):SavedView {
    const configs:Record<PredefinedView, Partial<SavedView>> = {
      north: {
        name: 'North',
        eye: [center[0], center[1] - distance, center[2]],
        up: [0, 0, 1],
        projection: 'orthogonal',
      },
      south: {
        name: 'South',
        eye: [center[0], center[1] + distance, center[2]],
        up: [0, 0, 1],
        projection: 'orthogonal',
      },
      east: {
        name: 'East',
        eye: [center[0] + distance, center[1], center[2]],
        up: [0, 0, 1],
        projection: 'orthogonal',
      },
      west: {
        name: 'West',
        eye: [center[0] - distance, center[1], center[2]],
        up: [0, 0, 1],
        projection: 'orthogonal',
      },
      top: {
        name: 'Top',
        eye: [center[0], center[1], center[2] + distance],
        up: [0, 1, 0],
        projection: 'orthogonal',
      },
      bottom: {
        name: 'Bottom',
        eye: [center[0], center[1], center[2] - distance],
        up: [0, -1, 0],
        projection: 'orthogonal',
      },
      isometric: {
        name: 'Isometric',
        eye: [
          center[0] + distance * 0.7,
          center[1] - distance * 0.7,
          center[2] + distance * 0.7,
        ],
        up: [0, 0, 1],
        projection: 'perspective',
      },
    };

    const config = configs[view];
    return {
      name: config.name!,
      eye: config.eye as [number, number, number],
      look: center,
      up: config.up as [number, number, number],
      projection: config.projection as ProjectionType,
    };
  }

  /**
   * Set plan view (top-down orthogonal)
   */
  private setPlanView():void {
    this.setPredefinedView('top');
  }

  /**
   * Fit camera to view all objects
   */
  fitToView(animation?:CameraAnimation):void {
    const scene = this.viewer.scene;
    const aabb = scene.aabb;

    if (animation) {
      this.viewer.cameraFlight.flyTo({
        aabb,
        duration: animation.duration / 1000, // xeokit uses seconds
      });
    } else {
      this.viewer.camera.viewFitEntities(scene.visibleObjectIds);
    }
  }

  /**
   * Fit camera to specific entities
   */
  fitToEntities(entityIds:string[], animation?:CameraAnimation):void {
    if (entityIds.length === 0) return;

    if (animation) {
      this.viewer.cameraFlight.flyTo({
        entities: entityIds,
        duration: animation.duration / 1000,
      });
    } else {
      this.viewer.camera.viewFitEntities(entityIds);
    }
  }

  /**
   * Get all saved views
   */
  getAllSavedViews():SavedView[] {
    return Array.from(this.savedViews.values());
  }

  /**
   * Get saved view by name
   */
  getSavedView(name:string):SavedView | undefined {
    return this.savedViews.get(name);
  }

  /**
   * Delete saved view
   */
  deleteSavedView(name:string):void {
    this.savedViews.delete(name);
  }

  /**
   * Load saved views from backend
   */
  loadSavedViews(views:SavedView[]):void {
    views.forEach((view) => {
      this.savedViews.set(view.name, view);
    });
  }

  /**
   * Clear all saved views
   */
  clearSavedViews():void {
    this.savedViews.clear();
  }

  /**
   * Enable/disable collision detection for walk mode
   */
  setCollisionDetection(enabled:boolean):void {
    this.collisionEnabled = enabled;
    // Note: xeokit doesn't have built-in collision detection
    // This would need custom implementation or third-party library
  }

  /**
   * Interpolate between two 3D vectors
   */
  private interpolateVec3(
    start:number[],
    end:[number, number, number],
    t:number,
  ):[number, number, number] {
    return [
      start[0] + (end[0] - start[0]) * t,
      start[1] + (end[1] - start[1]) * t,
      start[2] + (end[2] - start[2]) * t,
    ];
  }

  /**
   * Apply easing function to t (0-1)
   */
  private applyEasing(t:number, easing:string):number {
    switch (easing) {
      case 'linear':
        return t;
      case 'easeIn':
        return t * t;
      case 'easeOut':
        return t * (2 - t);
      case 'easeInOut':
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
      default:
        return t;
    }
  }

  /**
   * Get current camera position
   */
  getCurrentCameraPosition():SavedView {
    const camera = this.viewer.camera;
    return {
      name: 'Current',
      eye: camera.eye.slice() as [number, number, number],
      look: camera.look.slice() as [number, number, number],
      up: camera.up.slice() as [number, number, number],
      projection: camera.projection as ProjectionType,
    };
  }

  /**
   * Set camera projection (perspective or orthogonal)
   */
  setProjection(projection:ProjectionType):void {
    this.viewer.camera.projection = projection;
  }

  /**
   * Get all available predefined views
   */
  getPredefinedViews():PredefinedView[] {
    return ['north', 'south', 'east', 'west', 'top', 'bottom', 'isometric'];
  }
}
