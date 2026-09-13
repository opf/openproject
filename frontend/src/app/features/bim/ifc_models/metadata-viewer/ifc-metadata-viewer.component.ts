/**
 * IFC Metadata Viewer Component
 *
 * Displays comprehensive metadata extracted from IFC files including:
 * - IFC version and schema information
 * - Entity and geometry counts
 * - Spatial structure hierarchy (tree view)
 * - Property sets (Psets)
 * - Quantities (QTO)
 * - Classifications
 * - Materials
 * - Types/Families
 * - Validation results
 *
 * Usage:
 *   <op-ifc-metadata-viewer
 *     [modelId]="123"
 *     (elementSelected)="onElementSelected($event)">
 *   </op-ifc-metadata-viewer>
 */

import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export interface IfcMetadata {
  ifc_model_id: number;
  ifc_version?: string;
  file_schema?: string;
  file_checksum?: string;
  entity_count?: number;
  geometry_count?: number;
  spatial_structure: any;
  property_sets: { [key: string]: any };
  quantities: { [key: string]: any };
  classifications: { [key: string]: any[] };
  materials: { materials?: any[] };
  types: { [key: string]: any };
  validation_result: {
    warnings?: string[];
    errors?: string[];
    complexity_score?: number;
  };
  estimated_conversion_time?: number;
  actual_conversion_time?: number;
  summary?: any;
  created_at?: string;
  updated_at?: string;
}

@Component({
  selector: 'op-ifc-metadata-viewer',
  template: `
    <div class="ifc-metadata-viewer" *ngIf="metadata">
      <!-- Header Summary -->
      <div class="metadata-header">
        <h3>IFC Model Metadata</h3>
        <div class="header-stats">
          <div class="stat">
            <span class="label">Version:</span>
            <span class="value">{{ metadata.ifc_version || 'Unknown' }}</span>
          </div>
          <div class="stat">
            <span class="label">Entities:</span>
            <span class="value">{{ metadata.entity_count | number }}</span>
          </div>
          <div class="stat">
            <span class="label">Geometries:</span>
            <span class="value">{{ metadata.geometry_count | number }}</span>
          </div>
          <div class="stat" *ngIf="metadata.validation_result?.complexity_score">
            <span class="label">Complexity:</span>
            <span class="value">{{ (metadata.validation_result.complexity_score * 100).toFixed(0) }}%</span>
          </div>
        </div>
        <button class="button button--secondary" (click)="refreshMetadata()">
          Refresh Metadata
        </button>
      </div>

      <!-- Tabs -->
      <div class="metadata-tabs">
        <button class="tab" [class.active]="activeTab === 'overview'" (click)="activeTab = 'overview'">
          Overview
        </button>
        <button class="tab" [class.active]="activeTab === 'spatial'" (click)="activeTab = 'spatial'">
          Spatial Structure
        </button>
        <button class="tab" [class.active]="activeTab === 'properties'" (click)="activeTab = 'properties'">
          Properties
        </button>
        <button class="tab" [class.active]="activeTab === 'quantities'" (click)="activeTab = 'quantities'">
          Quantities
        </button>
        <button class="tab" [class.active]="activeTab === 'materials'" (click)="activeTab = 'materials'">
          Materials
        </button>
        <button class="tab" [class.active]="activeTab === 'validation'" (click)="activeTab = 'validation'">
          Validation
        </button>
      </div>

      <!-- Tab Content -->
      <div class="metadata-content">
        <!-- Overview Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'overview'">
          <h4>General Information</h4>
          <div class="info-grid">
            <div class="info-item">
              <span class="label">IFC Version:</span>
              <span class="value">{{ metadata.ifc_version }}</span>
            </div>
            <div class="info-item">
              <span class="label">File Schema:</span>
              <span class="value">{{ metadata.file_schema || 'N/A' }}</span>
            </div>
            <div class="info-item">
              <span class="label">File Checksum:</span>
              <span class="value code">{{ metadata.file_checksum?.substring(0, 16) }}...</span>
            </div>
            <div class="info-item">
              <span class="label">Entity Count:</span>
              <span class="value">{{ metadata.entity_count | number }}</span>
            </div>
            <div class="info-item">
              <span class="label">Geometry Count:</span>
              <span class="value">{{ metadata.geometry_count | number }}</span>
            </div>
            <div class="info-item" *ngIf="metadata.estimated_conversion_time">
              <span class="label">Est. Conversion Time:</span>
              <span class="value">{{ metadata.estimated_conversion_time }}s</span>
            </div>
            <div class="info-item" *ngIf="metadata.actual_conversion_time">
              <span class="label">Actual Conversion Time:</span>
              <span class="value">{{ metadata.actual_conversion_time }}s</span>
            </div>
          </div>

          <h4>Summary Statistics</h4>
          <div class="info-grid" *ngIf="metadata.summary">
            <div class="info-item">
              <span class="label">Total Area:</span>
              <span class="value">{{ metadata.summary.total_area | number }} m²</span>
            </div>
            <div class="info-item">
              <span class="label">Total Volume:</span>
              <span class="value">{{ metadata.summary.total_volume | number }} m³</span>
            </div>
            <div class="info-item">
              <span class="label">Building Storeys:</span>
              <span class="value">{{ metadata.summary.building_storey_count }}</span>
            </div>
            <div class="info-item">
              <span class="label">Spaces:</span>
              <span class="value">{{ metadata.summary.space_count }}</span>
            </div>
            <div class="info-item">
              <span class="label">Property Sets:</span>
              <span class="value">{{ metadata.summary.property_set_count }}</span>
            </div>
            <div class="info-item">
              <span class="label">Materials:</span>
              <span class="value">{{ metadata.summary.material_count }}</span>
            </div>
          </div>
        </div>

        <!-- Spatial Structure Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'spatial'">
          <h4>Spatial Hierarchy</h4>
          <div class="spatial-tree">
            <div class="tree-node" *ngFor="let node of getSpatialRoots()">
              <op-tree-node
                [node]="node"
                (nodeClicked)="onNodeClicked($event)">
              </op-tree-node>
            </div>
            <div class="no-data" *ngIf="!getSpatialRoots().length">
              No spatial structure data available
            </div>
          </div>
        </div>

        <!-- Properties Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'properties'">
          <h4>Property Sets</h4>
          <div class="search-box">
            <input type="text"
                   placeholder="Search property sets..."
                   [(ngModel)]="searchQuery"
                   (input)="filterPropertySets()">
          </div>
          <div class="property-sets">
            <div class="property-set" *ngFor="let pset of filteredPropertySets">
              <div class="pset-header" (click)="togglePset(pset.name)">
                <span class="pset-name">{{ pset.name }}</span>
                <span class="pset-count">{{ pset.properties?.length || 0 }} properties</span>
                <span class="toggle-icon">{{ expandedPsets.has(pset.name) ? '▼' : '▶' }}</span>
              </div>
              <div class="pset-content" *ngIf="expandedPsets.has(pset.name)">
                <div class="property" *ngFor="let prop of pset.properties">
                  <span class="prop-name">{{ prop.name }}:</span>
                  <span class="prop-value">{{ prop.value }} <em class="prop-unit" *ngIf="prop.unit">{{ prop.unit }}</em></span>
                </div>
              </div>
            </div>
            <div class="no-data" *ngIf="!filteredPropertySets.length">
              No property sets found
            </div>
          </div>
        </div>

        <!-- Quantities Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'quantities'">
          <h4>Quantities</h4>
          <div class="quantities-grid">
            <div class="quantity-card" *ngFor="let qty of getQuantitiesList()">
              <div class="qty-label">{{ qty.label }}</div>
              <div class="qty-value">{{ qty.value | number }}</div>
              <div class="qty-unit">{{ qty.unit }}</div>
            </div>
            <div class="no-data" *ngIf="!getQuantitiesList().length">
              No quantity data available
            </div>
          </div>
        </div>

        <!-- Materials Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'materials'">
          <h4>Materials</h4>
          <div class="materials-list">
            <div class="material-item" *ngFor="let material of getMaterialsList()">
              <div class="material-name">{{ material.name }}</div>
              <div class="material-details" *ngIf="material.layers">
                <span class="detail-label">Layers:</span>
                <span class="detail-value">{{ material.layers.length }}</span>
              </div>
              <div class="material-properties" *ngIf="material.properties">
                <div class="prop" *ngFor="let prop of Object.keys(material.properties)">
                  <span class="key">{{ prop }}:</span>
                  <span class="value">{{ material.properties[prop] }}</span>
                </div>
              </div>
            </div>
            <div class="no-data" *ngIf="!getMaterialsList().length">
              No material data available
            </div>
          </div>
        </div>

        <!-- Validation Tab -->
        <div class="tab-panel" *ngIf="activeTab === 'validation'">
          <h4>Validation Results</h4>

          <div class="validation-score">
            <div class="score-card" [class.warning]="metadata.validation_result?.complexity_score > 0.7">
              <div class="score-label">Complexity Score</div>
              <div class="score-value">
                {{ ((metadata.validation_result?.complexity_score || 0) * 100).toFixed(0) }}%
              </div>
              <div class="score-indicator">
                <div class="indicator-fill"
                     [style.width.%]="(metadata.validation_result?.complexity_score || 0) * 100">
                </div>
              </div>
            </div>
          </div>

          <div class="validation-warnings" *ngIf="metadata.validation_result?.warnings?.length">
            <h5>⚠️ Warnings ({{ metadata.validation_result.warnings.length }})</h5>
            <ul>
              <li *ngFor="let warning of metadata.validation_result.warnings">
                {{ warning }}
              </li>
            </ul>
          </div>

          <div class="validation-errors" *ngIf="metadata.validation_result?.errors?.length">
            <h5>❌ Errors ({{ metadata.validation_result.errors.length }})</h5>
            <ul>
              <li *ngFor="let error of metadata.validation_result.errors">
                {{ error }}
              </li>
            </ul>
          </div>

          <div class="validation-success" *ngIf="!metadata.validation_result?.errors?.length && !metadata.validation_result?.warnings?.length">
            <h5>✅ Validation Passed</h5>
            <p>No errors or warnings found in the IFC file.</p>
          </div>
        </div>
      </div>
    </div>

    <div class="loading" *ngIf="!metadata && !error">
      Loading metadata...
    </div>

    <div class="error" *ngIf="error">
      <h4>Error loading metadata</h4>
      <p>{{ error }}</p>
      <button class="button" (click)="loadMetadata()">Retry</button>
    </div>
  `,
  styles: [`
    .ifc-metadata-viewer {
      background: #fff;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .metadata-header {
      padding: 24px;
      border-bottom: 1px solid #e0e0e0;
    }

    .metadata-header h3 {
      margin: 0 0 16px 0;
      font-size: 20px;
      font-weight: 600;
    }

    .header-stats {
      display: flex;
      gap: 32px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }

    .header-stats .stat {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .header-stats .label {
      font-size: 12px;
      color: #666;
      text-transform: uppercase;
    }

    .header-stats .value {
      font-size: 18px;
      font-weight: 600;
      color: #333;
    }

    .metadata-tabs {
      display: flex;
      border-bottom: 2px solid #e0e0e0;
      background: #fafafa;
    }

    .tab {
      padding: 12px 24px;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      cursor: pointer;
      font-weight: 500;
      color: #666;
      transition: all 0.2s;
    }

    .tab:hover {
      background: #f5f5f5;
      color: #333;
    }

    .tab.active {
      color: #2196f3;
      border-bottom-color: #2196f3;
      background: #fff;
    }

    .metadata-content {
      padding: 24px;
    }

    .tab-panel h4 {
      margin: 0 0 16px 0;
      font-size: 16px;
      font-weight: 600;
      color: #333;
    }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }

    .info-item {
      display: flex;
      justify-content: space-between;
      padding: 12px;
      background: #fafafa;
      border-radius: 4px;
    }

    .info-item .label {
      font-weight: 600;
      color: #666;
    }

    .info-item .value {
      color: #333;
    }

    .info-item .value.code {
      font-family: monospace;
      font-size: 12px;
    }

    .search-box {
      margin-bottom: 16px;
    }

    .search-box input {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid #e0e0e0;
      border-radius: 4px;
      font-size: 14px;
    }

    .property-sets {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .property-set {
      border: 1px solid #e0e0e0;
      border-radius: 4px;
      overflow: hidden;
    }

    .pset-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      background: #fafafa;
      cursor: pointer;
      transition: background 0.2s;
    }

    .pset-header:hover {
      background: #f5f5f5;
    }

    .pset-name {
      font-weight: 600;
      color: #333;
    }

    .pset-count {
      font-size: 12px;
      color: #666;
    }

    .toggle-icon {
      color: #999;
    }

    .pset-content {
      padding: 16px;
      background: #fff;
      border-top: 1px solid #e0e0e0;
    }

    .property {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #f5f5f5;
    }

    .property:last-child {
      border-bottom: none;
    }

    .prop-name {
      font-weight: 500;
      color: #666;
    }

    .prop-value {
      color: #333;
    }

    .prop-unit {
      color: #999;
      font-size: 12px;
    }

    .quantities-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
    }

    .quantity-card {
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #fff;
      border-radius: 8px;
      text-align: center;
    }

    .qty-label {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 8px;
    }

    .qty-value {
      font-size: 32px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .qty-unit {
      font-size: 12px;
      opacity: 0.8;
    }

    .materials-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .material-item {
      padding: 16px;
      border: 1px solid #e0e0e0;
      border-radius: 4px;
      background: #fafafa;
    }

    .material-name {
      font-size: 16px;
      font-weight: 600;
      color: #333;
      margin-bottom: 8px;
    }

    .material-details {
      display: flex;
      gap: 8px;
      font-size: 14px;
      color: #666;
      margin-bottom: 8px;
    }

    .detail-label {
      font-weight: 500;
    }

    .material-properties {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 8px;
      margin-top: 12px;
      padding-top: 12px;
      border-top: 1px solid #e0e0e0;
    }

    .material-properties .prop {
      font-size: 13px;
      color: #666;
    }

    .material-properties .key {
      font-weight: 500;
    }

    .validation-score {
      margin-bottom: 24px;
    }

    .score-card {
      padding: 24px;
      background: #e8f5e9;
      border-radius: 8px;
      border-left: 4px solid #4caf50;
    }

    .score-card.warning {
      background: #fff3e0;
      border-left-color: #f57c00;
    }

    .score-label {
      font-size: 14px;
      color: #666;
      margin-bottom: 8px;
    }

    .score-value {
      font-size: 36px;
      font-weight: 700;
      color: #333;
      margin-bottom: 12px;
    }

    .score-indicator {
      height: 8px;
      background: #e0e0e0;
      border-radius: 4px;
      overflow: hidden;
    }

    .indicator-fill {
      height: 100%;
      background: linear-gradient(90deg, #4caf50, #66bb6a);
      transition: width 0.5s ease;
    }

    .validation-warnings,
    .validation-errors {
      margin-bottom: 24px;
      padding: 16px;
      border-radius: 4px;
    }

    .validation-warnings {
      background: #fff3e0;
      border-left: 4px solid #f57c00;
    }

    .validation-warnings h5 {
      margin: 0 0 12px 0;
      color: #f57c00;
    }

    .validation-errors {
      background: #ffebee;
      border-left: 4px solid #f44336;
    }

    .validation-errors h5 {
      margin: 0 0 12px 0;
      color: #c62828;
    }

    .validation-success {
      padding: 24px;
      background: #e8f5e9;
      border-radius: 8px;
      text-align: center;
    }

    .validation-success h5 {
      margin: 0 0 8px 0;
      color: #2e7d32;
      font-size: 18px;
    }

    .validation-success p {
      margin: 0;
      color: #666;
    }

    .no-data {
      padding: 24px;
      text-align: center;
      color: #999;
      font-style: italic;
    }

    .loading,
    .error {
      padding: 48px;
      text-align: center;
    }

    .error h4 {
      color: #f44336;
      margin-bottom: 8px;
    }

    .error p {
      color: #666;
      margin-bottom: 16px;
    }
  `]
})
export class IfcMetadataViewerComponent implements OnInit {
  @Input() modelId!: number;
  @Output() elementSelected = new EventEmitter<any>();

  metadata: IfcMetadata | null = null;
  error: string | null = null;
  activeTab = 'overview';
  searchQuery = '';
  filteredPropertySets: any[] = [];
  expandedPsets = new Set<string>();

  Object = Object; // Make Object available in template

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadMetadata();
  }

  loadMetadata(): void {
    this.error = null;
    this.http.get<IfcMetadata>(`/api/v3/bim/ifc_models/${this.modelId}/metadata`)
      .subscribe({
        next: (metadata) => {
          this.metadata = metadata;
          this.filterPropertySets();
        },
        error: (err) => {
          this.error = err.error?.message || 'Failed to load metadata';
        }
      });
  }

  refreshMetadata(): void {
    this.http.post(`/api/v3/bim/ifc_models/${this.modelId}/refresh_metadata`, {})
      .subscribe(() => {
        setTimeout(() => this.loadMetadata(), 2000);
      });
  }

  getSpatialRoots(): any[] {
    if (!this.metadata?.spatial_structure) return [];

    // The spatial_structure is typically the root node itself
    return [this.metadata.spatial_structure];
  }

  filterPropertySets(): void {
    if (!this.metadata) {
      this.filteredPropertySets = [];
      return;
    }

    const psets = this.metadata.property_sets || {};
    const query = this.searchQuery.toLowerCase();

    this.filteredPropertySets = Object.keys(psets)
      .filter(name => !query || name.toLowerCase().includes(query))
      .map(name => ({
        name,
        properties: this.formatProperties(psets[name])
      }));
  }

  formatProperties(psetData: any): any[] {
    if (!psetData || !psetData.properties) return [];

    return Object.keys(psetData.properties).map(key => ({
      name: key,
      value: psetData.properties[key].value,
      unit: psetData.properties[key].unit
    }));
  }

  togglePset(name: string): void {
    if (this.expandedPsets.has(name)) {
      this.expandedPsets.delete(name);
    } else {
      this.expandedPsets.add(name);
    }
  }

  getQuantitiesList(): any[] {
    if (!this.metadata?.quantities) return [];

    const quantities = this.metadata.quantities;
    const list = [];

    if (quantities.total_area) {
      list.push({ label: 'Total Area', value: quantities.total_area, unit: 'm²' });
    }
    if (quantities.total_volume) {
      list.push({ label: 'Total Volume', value: quantities.total_volume, unit: 'm³' });
    }

    // Add other quantities from the by_type object
    if (quantities.by_type) {
      Object.keys(quantities.by_type).forEach(type => {
        const qty = quantities.by_type[type];
        list.push({
          label: type,
          value: qty.count || qty.total || qty,
          unit: qty.unit || ''
        });
      });
    }

    return list;
  }

  getMaterialsList(): any[] {
    if (!this.metadata?.materials?.materials) return [];
    return this.metadata.materials.materials;
  }

  onNodeClicked(node: any): void {
    this.elementSelected.emit(node);
  }
}
