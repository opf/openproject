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

export type MeasurementType = 'distance' | 'area' | 'volume' | 'angle' | 'elevation';

export interface Point3D {
  x: number;
  y: number;
  z: number;
}

export interface Measurement {
  id: string;
  type: MeasurementType;
  value: number;
  unit: string;
  points: Point3D[];
  label?: string;
  color?: string;
  visible: boolean;
  metadata?: Record<string, any>;
}

/**
 * Manages measurements in the 3D viewer
 * Provides distance, area, volume, angle, and elevation measurement tools
 */
@Injectable()
export class MeasurementManagerService {
  private viewer:any; // xeokit Viewer instance
  private measurements:Map<string, Measurement> = new Map();
  private activeMeasurement:Measurement | null = null;
  private measurementMode:MeasurementType | null = null;
  private nextId = 0;

  initialize(viewer:any):void {
    this.viewer = viewer;
    this.measurements.clear();
    this.activeMeasurement = null;
    this.measurementMode = null;
  }

  /**
   * Start a new measurement of the specified type
   */
  startMeasurement(type:MeasurementType):void {
    this.measurementMode = type;
    this.activeMeasurement = {
      id: `measurement-${this.nextId++}`,
      type,
      value: 0,
      unit: this.getDefaultUnit(type),
      points: [],
      visible: true,
      color: '#FF0000',
    };
  }

  /**
   * Add a point to the active measurement
   */
  addPoint(worldPos:Point3D):void {
    if (!this.activeMeasurement) {
      console.warn('No active measurement');
      return;
    }

    this.activeMeasurement.points.push(worldPos);

    // Auto-calculate value when we have enough points
    if (this.hasEnoughPoints(this.activeMeasurement)) {
      this.calculateValue(this.activeMeasurement);
    }
  }

  /**
   * Complete the active measurement and save it
   */
  completeMeasurement():Measurement | null {
    if (!this.activeMeasurement) {
      return null;
    }

    if (!this.hasEnoughPoints(this.activeMeasurement)) {
      console.warn('Not enough points for measurement');
      return null;
    }

    this.calculateValue(this.activeMeasurement);
    this.measurements.set(this.activeMeasurement.id, this.activeMeasurement);

    const completed = this.activeMeasurement;
    this.activeMeasurement = null;
    this.measurementMode = null;

    return completed;
  }

  /**
   * Cancel the active measurement
   */
  cancelMeasurement():void {
    this.activeMeasurement = null;
    this.measurementMode = null;
  }

  /**
   * Remove a measurement
   */
  removeMeasurement(id:string):void {
    this.measurements.delete(id);
  }

  /**
   * Get all measurements
   */
  getAllMeasurements():Measurement[] {
    return Array.from(this.measurements.values());
  }

  /**
   * Get measurement by ID
   */
  getMeasurement(id:string):Measurement | undefined {
    return this.measurements.get(id);
  }

  /**
   * Get measurements by type
   */
  getMeasurementsByType(type:MeasurementType):Measurement[] {
    return this.getAllMeasurements().filter((m) => m.type === type);
  }

  /**
   * Toggle measurement visibility
   */
  setMeasurementVisibility(id:string, visible:boolean):void {
    const measurement = this.measurements.get(id);
    if (measurement) {
      measurement.visible = visible;
    }
  }

  /**
   * Clear all measurements
   */
  clearAll():void {
    this.measurements.clear();
    this.activeMeasurement = null;
    this.measurementMode = null;
  }

  /**
   * Calculate distance between points
   */
  private calculateDistance(points:Point3D[]):number {
    if (points.length < 2) return 0;

    let totalDistance = 0;
    for (let i = 0; i < points.length - 1; i++) {
      const p1 = points[i];
      const p2 = points[i + 1];
      const dx = p2.x - p1.x;
      const dy = p2.y - p1.y;
      const dz = p2.z - p1.z;
      totalDistance += Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    return totalDistance;
  }

  /**
   * Calculate area from polygon points (2D projection to XZ plane)
   */
  private calculateArea(points:Point3D[]):number {
    if (points.length < 3) return 0;

    // Shoelace formula for polygon area (XZ plane projection)
    let area = 0;
    const n = points.length;

    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      area += points[i].x * points[j].z;
      area -= points[j].x * points[i].z;
    }

    return Math.abs(area / 2.0);
  }

  /**
   * Calculate volume from bounding box (first 2 points = min, max)
   */
  private calculateVolume(points:Point3D[]):number {
    if (points.length < 2) return 0;

    const min = points[0];
    const max = points[1];

    const width = Math.abs(max.x - min.x);
    const height = Math.abs(max.y - min.y);
    const depth = Math.abs(max.z - min.z);

    return width * height * depth;
  }

  /**
   * Calculate angle between three points (in degrees)
   * points[0] = vertex, points[1] and points[2] = directions
   */
  private calculateAngle(points:Point3D[]):number {
    if (points.length < 3) return 0;

    const vertex = points[0];
    const p1 = points[1];
    const p2 = points[2];

    // Vectors from vertex
    const v1 = {
      x: p1.x - vertex.x,
      y: p1.y - vertex.y,
      z: p1.z - vertex.z,
    };

    const v2 = {
      x: p2.x - vertex.x,
      y: p2.y - vertex.y,
      z: p2.z - vertex.z,
    };

    // Dot product
    const dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;

    // Magnitudes
    const mag1 = Math.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z);
    const mag2 = Math.sqrt(v2.x * v2.x + v2.y * v2.y + v2.z * v2.z);

    if (mag1 === 0 || mag2 === 0) return 0;

    // Angle in radians, then convert to degrees
    const cosAngle = Math.max(-1, Math.min(1, dot / (mag1 * mag2)));
    const angleRad = Math.acos(cosAngle);
    return (angleRad * 180) / Math.PI;
  }

  /**
   * Calculate elevation (Y coordinate) from reference
   */
  private calculateElevation(points:Point3D[], referenceY:number = 0):number {
    if (points.length === 0) return 0;

    const point = points[0];
    return Math.abs(point.y - referenceY);
  }

  /**
   * Calculate the value for a measurement
   */
  private calculateValue(measurement:Measurement):void {
    const { type, points } = measurement;

    switch (type) {
      case 'distance':
        measurement.value = this.calculateDistance(points);
        break;
      case 'area':
        measurement.value = this.calculateArea(points);
        break;
      case 'volume':
        measurement.value = this.calculateVolume(points);
        break;
      case 'angle':
        measurement.value = this.calculateAngle(points);
        break;
      case 'elevation':
        measurement.value = this.calculateElevation(points);
        break;
    }
  }

  /**
   * Check if measurement has enough points
   */
  private hasEnoughPoints(measurement:Measurement):boolean {
    const { type, points } = measurement;

    switch (type) {
      case 'distance':
        return points.length >= 2;
      case 'area':
        return points.length >= 3;
      case 'volume':
        return points.length >= 2;
      case 'angle':
        return points.length >= 3;
      case 'elevation':
        return points.length >= 1;
      default:
        return false;
    }
  }

  /**
   * Get default unit for measurement type
   */
  private getDefaultUnit(type:MeasurementType):string {
    switch (type) {
      case 'distance':
      case 'elevation':
        return 'm';
      case 'area':
        return 'm²';
      case 'volume':
        return 'm³';
      case 'angle':
        return 'degrees';
      default:
        return '';
    }
  }

  /**
   * Format measurement value with unit
   */
  formatMeasurement(measurement:Measurement):string {
    const value = measurement.value.toFixed(2);
    switch (measurement.type) {
      case 'distance':
      case 'elevation':
        return `${value} ${measurement.unit}`;
      case 'area':
        return `${value} ${measurement.unit}`;
      case 'volume':
        return `${value} ${measurement.unit}`;
      case 'angle':
        return `${parseFloat(value).toFixed(1)}°`;
      default:
        return `${value} ${measurement.unit}`;
    }
  }

  /**
   * Export measurements to CSV format
   */
  exportToCSV():string {
    const headers = ['ID', 'Type', 'Value', 'Unit', 'Label', 'Points Count'];
    const rows = this.getAllMeasurements().map((m) => [
      m.id,
      m.type,
      m.value.toFixed(4),
      m.unit,
      m.label || '',
      m.points.length.toString(),
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map((row) => row.join(',')),
    ].join('\n');

    return csvContent;
  }

  /**
   * Import measurements from saved data
   */
  importMeasurements(data:Measurement[]):void {
    data.forEach((measurement) => {
      this.measurements.set(measurement.id, measurement);
    });
  }
}
