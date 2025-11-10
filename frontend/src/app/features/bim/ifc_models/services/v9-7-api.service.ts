//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

/**
 * V9.7 API Service
 *
 * Service layer for V9.7 UX/UI Polish backend API endpoints.
 * Provides methods for:
 * - Model Tree operations (3 view modes)
 * - Element Properties (CRUD + history)
 * - Visibility Controls (filters, isolation)
 * - Color Schemes (visual coding)
 */

// ==================== MODEL TREE INTERFACES ====================

export interface ModelTreeNode {
  id: string;
  type: 'root' | 'site' | 'building' | 'storey' | 'space' | 'element' | 'type_group' | 'discipline_group';
  name: string;
  ifc_type?: string;
  guid?: string;
  level?: string;
  discipline?: string;
  element_count?: number;
  children_count: number;
  has_children: boolean;
  icon?: string;
  _links: {
    self: { href: string };
    children?: { href: string };
  };
}

export interface ModelTreeSearchResult {
  query: string;
  total_results: number;
  results: Array<{
    guid: string;
    name: string;
    ifc_type: string;
    level?: string;
    discipline?: string;
    match_type: 'name' | 'guid' | 'type' | 'property';
    match_context?: string;
    _links: {
      properties: { href: string };
    };
  }>;
}

export type TreeViewMode = 'spatial' | 'type' | 'discipline' | 'custom';

// ==================== ELEMENT PROPERTIES INTERFACES ====================

export interface ElementProperties {
  element_guid: string;
  basic: {
    name: string;
    ifc_type: string;
    guid: string;
    level?: string;
    discipline?: string;
    description?: string;
  };
  geometry: {
    volume?: number;
    area?: number;
    height?: number;
    width?: number;
    length?: number;
    perimeter?: number;
  };
  materials: {
    material?: string;
    finish?: string;
    fire_rating?: string;
    acoustic_rating?: string;
  };
  status: {
    workflow_state?: string;
    approval_status?: string;
    review_status?: string;
    last_modified?: string;
    modified_by?: string;
  };
  custom: Record<string, any>;
  _links: {
    self: { href: string };
    related: { href: string };
    history: { href: string };
  };
}

export interface PropertyHistoryEntry {
  timestamp: string;
  user: string;
  action: 'create' | 'update' | 'delete';
  property_name: string;
  old_value?: any;
  new_value?: any;
  category: 'basic' | 'geometry' | 'materials' | 'status' | 'custom';
}

export interface RelatedElements {
  element_guid: string;
  parent?: {
    guid: string;
    name: string;
    ifc_type: string;
  };
  children: Array<{
    guid: string;
    name: string;
    ifc_type: string;
    count?: number;
  }>;
}

// ==================== VISIBILITY INTERFACES ====================

export interface VisibilityState {
  ifc_model_id: number;
  filters: {
    types?: string[];
    disciplines?: string[];
    levels?: string[];
    statuses?: string[];
    properties?: Array<{
      name: string;
      operator: 'equals' | 'not_equals' | 'contains' | 'not_contains' | 'greater_than' | 'less_than';
      value: any;
    }>;
  };
  overrides: Record<string, boolean>;
  isolation: {
    active: boolean;
    element_guids: string[];
  };
  visibility_map: Record<string, boolean>;
  statistics: {
    total_elements: number;
    visible_elements: number;
    hidden_elements: number;
    visible_percentage: number;
  };
  cached_at: string;
}

export interface VisibilityFilters {
  types?: string[];
  disciplines?: string[];
  levels?: string[];
  statuses?: string[];
  properties?: Array<{
    name: string;
    operator: string;
    value: any;
  }>;
}

// ==================== COLOR SCHEME INTERFACES ====================

export interface ColorSchemeDefinition {
  name: string;
  display_name: string;
  description: string;
  type: 'pre_defined' | 'property_based' | 'custom';
  color_map?: Record<string, string>;
}

export interface ColorSchemeState {
  ifc_model_id: number;
  active_scheme?: string;
  custom_colors: Record<string, string>;
  color_map: Record<string, string>; // guid -> hex color
  statistics: {
    total_elements: number;
    colored_elements: number;
    unique_colors: number;
  };
  cached_at: string;
}

@Injectable({
  providedIn: 'root',
})
export class V97ApiService {
  private readonly API_BASE = '/api/v3/bim/ifc_models';

  constructor(private http: HttpClient) {}

  // ==================== MODEL TREE API ====================

  /**
   * Get root nodes of the model tree
   * @param ifcModelId - IFC model ID
   * @param viewMode - View mode (spatial, type, discipline, custom)
   * @returns Observable of root nodes array
   */
  getTreeRoot(ifcModelId: number, viewMode: TreeViewMode = 'spatial'): Observable<ModelTreeNode[]> {
    const params = new HttpParams().set('view_mode', viewMode);
    return this.http.get<ModelTreeNode[]>(`${this.API_BASE}/${ifcModelId}/tree`, { params });
  }

  /**
   * Get children nodes for a specific parent node (lazy loading)
   * @param ifcModelId - IFC model ID
   * @param nodeId - Parent node ID
   * @param viewMode - View mode
   * @returns Observable of children nodes array
   */
  getTreeChildren(
    ifcModelId: number,
    nodeId: string,
    viewMode: TreeViewMode = 'spatial',
  ): Observable<ModelTreeNode[]> {
    const params = new HttpParams().set('view_mode', viewMode);
    return this.http.get<ModelTreeNode[]>(
      `${this.API_BASE}/${ifcModelId}/tree/nodes/${nodeId}/children`,
      { params },
    );
  }

  /**
   * Search model tree with filters
   * @param ifcModelId - IFC model ID
   * @param query - Search query string
   * @param filters - Optional filters (types, levels, disciplines)
   * @returns Observable of search results
   */
  searchTree(
    ifcModelId: number,
    query: string,
    filters?: { types?: string[]; levels?: string[]; disciplines?: string[] },
  ): Observable<ModelTreeSearchResult> {
    return this.http.post<ModelTreeSearchResult>(`${this.API_BASE}/${ifcModelId}/tree/search`, {
      query,
      filters: filters || {},
    });
  }

  // ==================== ELEMENT PROPERTIES API ====================

  /**
   * Get all properties for an element
   * @param ifcModelId - IFC model ID
   * @param elementGuid - Element GUID
   * @returns Observable of element properties
   */
  getElementProperties(ifcModelId: number, elementGuid: string): Observable<ElementProperties> {
    return this.http.get<ElementProperties>(
      `${this.API_BASE}/${ifcModelId}/elements/${elementGuid}/properties`,
    );
  }

  /**
   * Update custom properties for an element
   * @param ifcModelId - IFC model ID
   * @param elementGuid - Element GUID
   * @param customProperties - Custom properties to update
   * @returns Observable of updated properties
   */
  updateElementProperties(
    ifcModelId: number,
    elementGuid: string,
    customProperties: Record<string, any>,
  ): Observable<ElementProperties> {
    return this.http.patch<ElementProperties>(
      `${this.API_BASE}/${ifcModelId}/elements/${elementGuid}/properties`,
      { properties: { custom: customProperties } },
    );
  }

  /**
   * Get related elements (parent + children)
   * @param ifcModelId - IFC model ID
   * @param elementGuid - Element GUID
   * @returns Observable of related elements
   */
  getRelatedElements(ifcModelId: number, elementGuid: string): Observable<RelatedElements> {
    return this.http.get<RelatedElements>(
      `${this.API_BASE}/${ifcModelId}/elements/${elementGuid}/related`,
    );
  }

  /**
   * Get property change history for an element
   * @param ifcModelId - IFC model ID
   * @param elementGuid - Element GUID
   * @returns Observable of property history entries
   */
  getPropertyHistory(ifcModelId: number, elementGuid: string): Observable<PropertyHistoryEntry[]> {
    return this.http.get<PropertyHistoryEntry[]>(
      `${this.API_BASE}/${ifcModelId}/elements/${elementGuid}/history`,
    );
  }

  // ==================== VISIBILITY API ====================

  /**
   * Get current visibility state
   * @param ifcModelId - IFC model ID
   * @returns Observable of visibility state
   */
  getVisibilityState(ifcModelId: number): Observable<VisibilityState> {
    return this.http.get<VisibilityState>(`${this.API_BASE}/${ifcModelId}/visibility`);
  }

  /**
   * Apply visibility filters
   * @param ifcModelId - IFC model ID
   * @param filters - Visibility filters
   * @param overrides - Optional element-specific overrides
   * @returns Observable of updated visibility state
   */
  applyVisibilityFilters(
    ifcModelId: number,
    filters: VisibilityFilters,
    overrides?: Record<string, boolean>,
  ): Observable<VisibilityState> {
    return this.http.post<VisibilityState>(`${this.API_BASE}/${ifcModelId}/visibility`, {
      filters,
      overrides: overrides || {},
    });
  }

  /**
   * Isolate specific elements (hide all others)
   * @param ifcModelId - IFC model ID
   * @param elementGuids - Array of element GUIDs to isolate
   * @returns Observable of updated visibility state
   */
  isolateElements(ifcModelId: number, elementGuids: string[]): Observable<VisibilityState> {
    return this.http.post<VisibilityState>(`${this.API_BASE}/${ifcModelId}/visibility/isolate`, {
      element_guids: elementGuids,
    });
  }

  /**
   * Reset visibility to default (show all)
   * @param ifcModelId - IFC model ID
   * @returns Observable of reset visibility state
   */
  resetVisibility(ifcModelId: number): Observable<VisibilityState> {
    return this.http.post<VisibilityState>(`${this.API_BASE}/${ifcModelId}/visibility/reset`, {});
  }

  /**
   * Toggle visibility for specific elements
   * @param ifcModelId - IFC model ID
   * @param elementGuids - Array of element GUIDs
   * @param visible - true to show, false to hide
   * @returns Observable of updated visibility state
   */
  toggleVisibility(
    ifcModelId: number,
    elementGuids: string[],
    visible: boolean,
  ): Observable<VisibilityState> {
    return this.http.post<VisibilityState>(`${this.API_BASE}/${ifcModelId}/visibility/toggle`, {
      element_guids: elementGuids,
      visible,
    });
  }

  // ==================== COLOR SCHEME API ====================

  /**
   * Get available color schemes
   * @param ifcModelId - IFC model ID
   * @returns Observable of color scheme definitions
   */
  getColorSchemes(ifcModelId: number): Observable<ColorSchemeDefinition[]> {
    return this.http.get<ColorSchemeDefinition[]>(`${this.API_BASE}/${ifcModelId}/colors/schemes`);
  }

  /**
   * Apply a color scheme
   * @param ifcModelId - IFC model ID
   * @param schemeName - Scheme name (by_status, by_discipline, by_type, by_clash_status)
   * @param customColors - Optional custom color overrides
   * @returns Observable of color scheme state
   */
  applyColorScheme(
    ifcModelId: number,
    schemeName: string,
    customColors?: Record<string, string>,
  ): Observable<ColorSchemeState> {
    return this.http.post<ColorSchemeState>(`${this.API_BASE}/${ifcModelId}/colors`, {
      scheme: schemeName,
      custom_colors: customColors || {},
    });
  }

  /**
   * Apply color scheme based on property values
   * @param ifcModelId - IFC model ID
   * @param propertyName - Property name to color by
   * @param colorMapping - Map of property values to hex colors
   * @param defaultColor - Default color for unmapped values
   * @returns Observable of color scheme state
   */
  applyColorByProperty(
    ifcModelId: number,
    propertyName: string,
    colorMapping: Record<string, string>,
    defaultColor?: string,
  ): Observable<ColorSchemeState> {
    return this.http.post<ColorSchemeState>(`${this.API_BASE}/${ifcModelId}/colors/by_property`, {
      property_name: propertyName,
      color_mapping: colorMapping,
      default_color: defaultColor,
    });
  }

  /**
   * Reset colors to original model colors
   * @param ifcModelId - IFC model ID
   * @returns Observable of reset color state
   */
  resetColors(ifcModelId: number): Observable<ColorSchemeState> {
    return this.http.post<ColorSchemeState>(`${this.API_BASE}/${ifcModelId}/colors/reset`, {});
  }
}
