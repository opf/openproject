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

export type QualityPreset = 'low' | 'medium' | 'high' | 'ultra';
export type ShadowQuality = 'low' | 'medium' | 'high';

export interface RenderingConfig {
  // Ambient Occlusion
  sao: boolean;
  saoEnabled?: boolean;
  saoScale?: number;
  saoIntensity?: number;
  saoBlur?: boolean;
  saoNumSamples?: number;

  // Edge Rendering
  edges: boolean;
  edgesEnabled?: boolean;
  edgeColor?: [number, number, number];
  edgeAlpha?: number;
  edgeWidth?: number;

  // Physically-Based Rendering
  pbr: boolean;
  pbrEnabled?: boolean;

  // Shadows
  shadows: boolean;
  shadowsEnabled?: boolean;
  shadowQuality?: ShadowQuality;
  shadowMapSize?: number;
  shadowIntensity?: number;

  // Anti-aliasing
  antialias: boolean;

  // Transparency
  transparencyEnabled?: boolean;

  // Performance
  targetFps?: number;
}

export interface PerformanceMetrics {
  fps: number;
  frameTime: number;
  renderTime: number;
  numDrawCalls: number;
  numTriangles: number;
  numObjects: number;
  memoryUsage?: number;
}

/**
 * Manages rendering quality and visual effects for the 3D viewer
 * Provides quality presets, shadows, ambient occlusion, PBR, and performance monitoring
 */
@Injectable()
export class RenderingManagerService {
  private viewer:any; // xeokit Viewer instance
  private currentQuality:QualityPreset = 'medium';
  private currentConfig:RenderingConfig | null = null;
  private performanceMonitoring = false;
  private performanceInterval:any = null;
  private frameCount = 0;
  private lastTime = 0;
  private currentFps = 0;

  // Quality presets
  private readonly qualityPresets:Record<QualityPreset, RenderingConfig> = {
    low: {
      sao: false,
      edges: false,
      pbr: false,
      shadows: false,
      antialias: false,
      transparencyEnabled: false,
      targetFps: 60,
    },
    medium: {
      sao: true,
      saoEnabled: true,
      saoScale: 0.5,
      saoIntensity: 0.15,
      saoBlur: false,
      edges: true,
      edgesEnabled: true,
      edgeAlpha: 0.4,
      edgeWidth: 1,
      pbr: false,
      shadows: false,
      antialias: true,
      transparencyEnabled: true,
      targetFps: 60,
    },
    high: {
      sao: true,
      saoEnabled: true,
      saoScale: 1.0,
      saoIntensity: 0.25,
      saoBlur: true,
      saoNumSamples: 16,
      edges: true,
      edgesEnabled: true,
      edgeAlpha: 0.6,
      edgeWidth: 1,
      pbr: true,
      pbrEnabled: true,
      shadows: true,
      shadowsEnabled: true,
      shadowQuality: 'medium',
      shadowMapSize: 1024,
      shadowIntensity: 0.7,
      antialias: true,
      transparencyEnabled: true,
      targetFps: 30,
    },
    ultra: {
      sao: true,
      saoEnabled: true,
      saoScale: 1.5,
      saoIntensity: 0.35,
      saoBlur: true,
      saoNumSamples: 32,
      edges: true,
      edgesEnabled: true,
      edgeAlpha: 0.8,
      edgeWidth: 2,
      pbr: true,
      pbrEnabled: true,
      shadows: true,
      shadowsEnabled: true,
      shadowQuality: 'high',
      shadowMapSize: 2048,
      shadowIntensity: 0.9,
      antialias: true,
      transparencyEnabled: true,
      targetFps: 30,
    },
  };

  initialize(viewer:any):void {
    this.viewer = viewer;
    this.setQualityPreset('medium');
  }

  /**
   * Set quality preset (low, medium, high, ultra)
   */
  setQualityPreset(preset:QualityPreset):void {
    this.currentQuality = preset;
    const config = this.qualityPresets[preset];
    this.applyRenderingConfig(config);
    this.currentConfig = config;
  }

  /**
   * Get current quality preset
   */
  getCurrentQuality():QualityPreset {
    return this.currentQuality;
  }

  /**
   * Apply rendering configuration
   */
  applyRenderingConfig(config:RenderingConfig):void {
    if (!this.viewer) {
      console.warn('Viewer not initialized');
      return;
    }

    const scene = this.viewer.scene;

    // Apply SAO (Screen-space Ambient Occlusion)
    if (config.sao !== undefined) {
      this.setSAO(config.sao, {
        scale: config.saoScale,
        intensity: config.saoIntensity,
        blur: config.saoBlur,
        numSamples: config.saoNumSamples,
      });
    }

    // Apply edge rendering
    if (config.edges !== undefined) {
      this.setEdges(config.edges, {
        color: config.edgeColor,
        alpha: config.edgeAlpha,
        width: config.edgeWidth,
      });
    }

    // Apply PBR
    if (config.pbr !== undefined) {
      this.setPBR(config.pbr);
    }

    // Apply shadows
    if (config.shadows !== undefined) {
      this.setShadows(config.shadows, {
        quality: config.shadowQuality,
        mapSize: config.shadowMapSize,
        intensity: config.shadowIntensity,
      });
    }

    // Apply transparency
    if (config.transparencyEnabled !== undefined) {
      scene.transparencyEnabled = config.transparencyEnabled;
    }
  }

  /**
   * Enable/disable Screen-space Ambient Occlusion (SAO)
   */
  setSAO(enabled:boolean, options?:{
    scale?: number;
    intensity?: number;
    blur?: boolean;
    numSamples?: number;
  }):void {
    const sao = this.viewer.scene.sao;

    sao.enabled = enabled;

    if (enabled && options) {
      if (options.scale !== undefined) sao.scale = options.scale;
      if (options.intensity !== undefined) sao.intensity = options.intensity;
      if (options.blur !== undefined) sao.blur = options.blur;
      if (options.numSamples !== undefined) sao.numSamples = options.numSamples;
    }
  }

  /**
   * Get current SAO settings
   */
  getSAO():{enabled:boolean; scale:number; intensity:number; blur:boolean} {
    const sao = this.viewer.scene.sao;
    return {
      enabled: sao.enabled,
      scale: sao.scale,
      intensity: sao.intensity,
      blur: sao.blur,
    };
  }

  /**
   * Enable/disable edge rendering
   */
  setEdges(enabled:boolean, options?:{
    color?: [number, number, number];
    alpha?: number;
    width?: number;
  }):void {
    const edgeMaterial = this.viewer.scene.edgeMaterial;

    edgeMaterial.edges = enabled;

    if (enabled && options) {
      if (options.color) edgeMaterial.edgeColor = options.color;
      if (options.alpha !== undefined) edgeMaterial.edgeAlpha = options.alpha;
      if (options.width !== undefined) edgeMaterial.edgeWidth = options.width;
    }
  }

  /**
   * Get current edge settings
   */
  getEdges():{enabled:boolean; color:[number, number, number]; alpha:number; width:number} {
    const edgeMaterial = this.viewer.scene.edgeMaterial;
    return {
      enabled: edgeMaterial.edges,
      color: edgeMaterial.edgeColor,
      alpha: edgeMaterial.edgeAlpha,
      width: edgeMaterial.edgeWidth,
    };
  }

  /**
   * Enable/disable Physically-Based Rendering (PBR)
   */
  setPBR(enabled:boolean):void {
    this.viewer.scene.pbrEnabled = enabled;
  }

  /**
   * Get PBR status
   */
  getPBR():boolean {
    return this.viewer.scene.pbrEnabled;
  }

  /**
   * Enable/disable shadows
   * Note: xeokit has limited shadow support, this is a framework for future enhancement
   */
  setShadows(enabled:boolean, options?:{
    quality?: ShadowQuality;
    mapSize?: number;
    intensity?: number;
  }):void {
    // Store shadow settings for future use
    // xeokit doesn't have built-in shadow support in all versions
    // This provides an interface for when it's available or for custom implementation

    if (this.currentConfig) {
      this.currentConfig.shadowsEnabled = enabled;
      if (options) {
        if (options.quality) this.currentConfig.shadowQuality = options.quality;
        if (options.mapSize) this.currentConfig.shadowMapSize = options.mapSize;
        if (options.intensity) this.currentConfig.shadowIntensity = options.intensity;
      }
    }
  }

  /**
   * Get shadow settings
   */
  getShadows():{enabled:boolean; quality?:ShadowQuality; mapSize?:number; intensity?:number} {
    return {
      enabled: this.currentConfig?.shadowsEnabled || false,
      quality: this.currentConfig?.shadowQuality,
      mapSize: this.currentConfig?.shadowMapSize,
      intensity: this.currentConfig?.shadowIntensity,
    };
  }

  /**
   * Set anti-aliasing
   */
  setAntialiasing(enabled:boolean):void {
    // Note: Anti-aliasing is typically set at viewer initialization
    // This provides an interface for dynamic toggling if supported
    if (this.viewer.scene.canvas) {
      // Store setting for next viewer recreation
      if (this.currentConfig) {
        this.currentConfig.antialias = enabled;
      }
    }
  }

  /**
   * Enable/disable transparency
   */
  setTransparency(enabled:boolean):void {
    this.viewer.scene.transparencyEnabled = enabled;
  }

  /**
   * Get transparency status
   */
  getTransparency():boolean {
    return this.viewer.scene.transparencyEnabled;
  }

  /**
   * Set edge color
   */
  setEdgeColor(color:[number, number, number]):void {
    this.viewer.scene.edgeMaterial.edgeColor = color;
  }

  /**
   * Set edge alpha (transparency)
   */
  setEdgeAlpha(alpha:number):void {
    this.viewer.scene.edgeMaterial.edgeAlpha = Math.max(0, Math.min(1, alpha));
  }

  /**
   * Start performance monitoring
   */
  startPerformanceMonitoring(interval:number = 1000):void {
    if (this.performanceMonitoring) return;

    this.performanceMonitoring = true;
    this.lastTime = performance.now();
    this.frameCount = 0;

    this.performanceInterval = setInterval(() => {
      const currentTime = performance.now();
      const elapsed = currentTime - this.lastTime;
      this.currentFps = Math.round((this.frameCount * 1000) / elapsed);
      this.frameCount = 0;
      this.lastTime = currentTime;
    }, interval);

    // Count frames
    const countFrame = () => {
      if (this.performanceMonitoring) {
        this.frameCount++;
        requestAnimationFrame(countFrame);
      }
    };
    countFrame();
  }

  /**
   * Stop performance monitoring
   */
  stopPerformanceMonitoring():void {
    if (this.performanceInterval) {
      clearInterval(this.performanceInterval);
      this.performanceInterval = null;
    }
    this.performanceMonitoring = false;
  }

  /**
   * Get current performance metrics
   */
  getPerformanceMetrics():PerformanceMetrics {
    const scene = this.viewer.scene;
    const stats = scene.canvas.gl ? this.getWebGLStats() : {};

    return {
      fps: this.currentFps,
      frameTime: this.currentFps > 0 ? 1000 / this.currentFps : 0,
      renderTime: stats.renderTime || 0,
      numDrawCalls: stats.drawCalls || 0,
      numTriangles: this.getTriangleCount(),
      numObjects: Object.keys(scene.objects).length,
      memoryUsage: this.getMemoryUsage(),
    };
  }

  /**
   * Get WebGL rendering statistics
   */
  private getWebGLStats():{renderTime:number; drawCalls:number} {
    // This would require WebGL query extensions
    // Placeholder for actual implementation
    return {
      renderTime: 0,
      drawCalls: 0,
    };
  }

  /**
   * Get total triangle count in scene
   */
  private getTriangleCount():number {
    let totalTriangles = 0;
    const scene = this.viewer.scene;

    // Estimate based on scene complexity
    // Actual implementation would traverse scene geometry
    const numObjects = Object.keys(scene.objects).length;
    const avgTrianglesPerObject = 100; // Rough estimate
    totalTriangles = numObjects * avgTrianglesPerObject;

    return totalTriangles;
  }

  /**
   * Get memory usage estimate
   */
  private getMemoryUsage():number | undefined {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      return memory.usedJSHeapSize;
    }
    return undefined;
  }

  /**
   * Auto-adjust quality based on performance
   */
  autoAdjustQuality(targetFps:number = 30):void {
    const metrics = this.getPerformanceMetrics();

    if (metrics.fps < targetFps * 0.8) {
      // Performance is poor, reduce quality
      switch (this.currentQuality) {
        case 'ultra':
          this.setQualityPreset('high');
          break;
        case 'high':
          this.setQualityPreset('medium');
          break;
        case 'medium':
          this.setQualityPreset('low');
          break;
      }
      console.log(`Auto-adjusted quality to ${this.currentQuality} (FPS: ${metrics.fps})`);
    } else if (metrics.fps > targetFps * 1.5 && this.currentQuality !== 'ultra') {
      // Performance is good, try increasing quality
      switch (this.currentQuality) {
        case 'low':
          this.setQualityPreset('medium');
          break;
        case 'medium':
          this.setQualityPreset('high');
          break;
        case 'high':
          this.setQualityPreset('ultra');
          break;
      }
      console.log(`Auto-adjusted quality to ${this.currentQuality} (FPS: ${metrics.fps})`);
    }
  }

  /**
   * Get all available quality presets
   */
  getQualityPresets():QualityPreset[] {
    return ['low', 'medium', 'high', 'ultra'];
  }

  /**
   * Get configuration for specific quality preset
   */
  getQualityPresetConfig(preset:QualityPreset):RenderingConfig {
    return { ...this.qualityPresets[preset] };
  }

  /**
   * Get current rendering configuration
   */
  getCurrentConfig():RenderingConfig | null {
    return this.currentConfig ? { ...this.currentConfig } : null;
  }

  /**
   * Apply custom rendering configuration
   */
  setCustomConfig(config:Partial<RenderingConfig>):void {
    const fullConfig:RenderingConfig = {
      ...this.currentConfig,
      ...config,
    } as RenderingConfig;

    this.applyRenderingConfig(fullConfig);
    this.currentConfig = fullConfig;
  }

  /**
   * Reset to default quality (medium)
   */
  resetToDefault():void {
    this.setQualityPreset('medium');
  }

  /**
   * Check if feature is supported
   */
  isFeatureSupported(feature:'sao' | 'pbr' | 'shadows' | 'edges'):boolean {
    // Check viewer capabilities
    switch (feature) {
      case 'sao':
        return !!this.viewer.scene.sao;
      case 'pbr':
        return 'pbrEnabled' in this.viewer.scene;
      case 'edges':
        return !!this.viewer.scene.edgeMaterial;
      case 'shadows':
        // Shadows are framework-ready but may need custom implementation
        return false;
      default:
        return false;
    }
  }
}
