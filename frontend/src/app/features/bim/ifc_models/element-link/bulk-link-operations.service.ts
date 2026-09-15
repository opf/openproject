/**
 * BulkLinkOperationsService
 *
 * Provides bulk operations for managing element-to-work-package links:
 * - Bulk link creation from element selections
 * - Template application with element filtering
 * - Bulk status changes
 * - Work package creation from element groups
 * - Element property refresh
 *
 * Used in conjunction with ElementLinkManager for interactive linking.
 */

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, forkJoin } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

export interface LinkTemplate {
  id: number;
  name: string;
  description?: string;
  relationship_type: RelationshipType;
  work_package_type?: string;
  element_filters: ElementFilters;
  template_data: Record<string, any>;
  auto_apply: boolean;
  public: boolean;
  project_id?: number;
  author_id: number;
  created_at: string;
  updated_at: string;
}

export interface ElementFilters {
  types?: string[]; // IfcWall, IfcDoor, etc.
  locations?: {
    building?: string[];
    storey?: string[];
    space?: string[];
  };
  classifications?: Array<{
    system: string;
    code: string;
  }>;
  properties?: Record<string, any>;
  tags?: string[];
}

export interface BulkLinkRequest {
  work_package_id: number;
  ifc_model_id: number;
  element_ids: string[];
  relationship_type: RelationshipType;
  template_id?: number;
}

export interface BulkLinkResponse {
  created: ElementLink[];
  failed: Array<{
    element_id: string;
    errors: string[];
  }>;
  success_count: number;
  failure_count: number;
}

export interface TemplateApplicationRequest {
  work_package_id: number;
  ifc_model_id: number;
  template_id: number;
  dry_run?: boolean;
}

export interface TemplateApplicationResponse {
  matching_elements?: string[];
  count?: number;
  created?: ElementLink[];
  failed?: Array<{
    element_id: string;
    errors: string[];
  }>;
  success_count?: number;
  failure_count?: number;
}

export interface BulkStatusChangeRequest {
  link_ids: number[];
  new_status: LinkStatus;
}

export interface WorkPackageCreationRequest {
  ifc_model_id: number;
  element_ids: string[];
  work_package_template: WorkPackageTemplate;
  relationship_type: RelationshipType;
  grouping_strategy: GroupingStrategy;
}

export interface WorkPackageTemplate {
  project_id: number;
  type_id: number;
  subject: string;
  description?: string;
  assigned_to_id?: number;
  priority_id?: number;
  due_date?: string;
  [key: string]: any;
}

export type GroupingStrategy = 'individual' | 'by_type' | 'by_location' | 'all_in_one';

export interface WorkPackageCreationResponse {
  work_packages: any[]; // WorkPackage type
  links: ElementLink[];
  failures: Array<{
    group_key: string;
    errors: string[];
  }>;
  work_package_count: number;
  link_count: number;
}

export interface ElementMatchingRequest {
  ifc_model_ids: number[];
  filters: ElementFilters;
}

export interface ElementMatchingResponse {
  results: Record<number, {
    model: any; // IfcModel type
    element_ids: string[];
    count: number;
  }>;
  total_count: number;
  model_count: number;
}

export interface RefreshPropertiesResponse {
  refreshed: ElementLink[];
  changed: ElementLink[];
  failed: Array<{
    link_id: number;
    reason: string;
  }>;
  refreshed_count: number;
  changed_count: number;
  failed_count: number;
}

export type RelationshipType = 'affected_by' | 'responsible_for' | 'depends_on' | 'observes' | 'related_to';
export type LinkStatus = 'active' | 'completed' | 'archived';

export interface ElementLink {
  id: number;
  work_package_id: number;
  ifc_model_id: number;
  element_id: string;
  relationship_type: RelationshipType;
  status: LinkStatus;
  element_properties: Record<string, any>;
  template_id?: number;
  user_id?: number;
  created_at: string;
  updated_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class BulkLinkOperationsService {
  private readonly apiBasePath = '/api/v3/bim/element_links';
  private readonly templatesBasePath = '/api/v3/bim/link_templates';

  constructor(private http: HttpClient) {}

  /**
   * Create multiple links at once
   */
  createBulkLinks(request: BulkLinkRequest): Observable<BulkLinkResponse> {
    return this.http.post<BulkLinkResponse>(
      `${this.apiBasePath}/bulk_create`,
      request
    ).pipe(
      catchError(error => {
        console.error('Bulk link creation failed:', error);
        throw error;
      })
    );
  }

  /**
   * Apply a template to create links for matching elements
   */
  applyTemplate(request: TemplateApplicationRequest): Observable<TemplateApplicationResponse> {
    return this.http.post<TemplateApplicationResponse>(
      `${this.apiBasePath}/apply_template`,
      request
    ).pipe(
      catchError(error => {
        console.error('Template application failed:', error);
        throw error;
      })
    );
  }

  /**
   * Preview which elements would match a template (dry run)
   */
  previewTemplateApplication(
    workPackageId: number,
    ifcModelId: number,
    templateId: number
  ): Observable<TemplateApplicationResponse> {
    return this.applyTemplate({
      work_package_id: workPackageId,
      ifc_model_id: ifcModelId,
      template_id: templateId,
      dry_run: true
    });
  }

  /**
   * Update multiple links at once
   */
  updateBulkLinks(linkIds: number[], attributes: Partial<ElementLink>): Observable<BulkLinkResponse> {
    return this.http.patch<BulkLinkResponse>(
      `${this.apiBasePath}/bulk_update`,
      { link_ids: linkIds, attributes }
    ).pipe(
      catchError(error => {
        console.error('Bulk link update failed:', error);
        throw error;
      })
    );
  }

  /**
   * Delete or archive multiple links at once
   */
  deleteBulkLinks(linkIds: number[], softDelete: boolean = true): Observable<{ archived_count?: number; deleted_count?: number }> {
    return this.http.post<{ archived_count?: number; deleted_count?: number }>(
      `${this.apiBasePath}/bulk_delete`,
      { link_ids: linkIds, soft_delete: softDelete }
    ).pipe(
      catchError(error => {
        console.error('Bulk link deletion failed:', error);
        throw error;
      })
    );
  }

  /**
   * Change status for multiple links
   */
  bulkStatusChange(request: BulkStatusChangeRequest): Observable<{ updated_count: number }> {
    return this.http.post<{ updated_count: number }>(
      `${this.apiBasePath}/bulk_status_change`,
      request
    ).pipe(
      catchError(error => {
        console.error('Bulk status change failed:', error);
        throw error;
      })
    );
  }

  /**
   * Create work packages from element selections
   */
  createWorkPackagesFromElements(request: WorkPackageCreationRequest): Observable<WorkPackageCreationResponse> {
    return this.http.post<WorkPackageCreationResponse>(
      `${this.apiBasePath}/create_work_packages`,
      request
    ).pipe(
      catchError(error => {
        console.error('Work package creation from elements failed:', error);
        throw error;
      })
    );
  }

  /**
   * Refresh element properties for multiple links
   */
  refreshElementProperties(linkIds: number[]): Observable<RefreshPropertiesResponse> {
    return this.http.post<RefreshPropertiesResponse>(
      `${this.apiBasePath}/refresh_properties`,
      { link_ids: linkIds }
    ).pipe(
      catchError(error => {
        console.error('Property refresh failed:', error);
        throw error;
      })
    );
  }

  /**
   * Find elements matching filters across models
   */
  findMatchingElements(request: ElementMatchingRequest): Observable<ElementMatchingResponse> {
    return this.http.post<ElementMatchingResponse>(
      `${this.apiBasePath}/find_matching`,
      request
    ).pipe(
      catchError(error => {
        console.error('Element matching failed:', error);
        throw error;
      })
    );
  }

  /**
   * Get all templates available for a project
   */
  getTemplates(projectId?: number): Observable<LinkTemplate[]> {
    const params = projectId ? { project_id: projectId.toString() } : {};
    return this.http.get<{ templates: LinkTemplate[] }>(
      this.templatesBasePath,
      { params }
    ).pipe(
      map(response => response.templates),
      catchError(error => {
        console.error('Failed to fetch templates:', error);
        return of([]);
      })
    );
  }

  /**
   * Get a specific template by ID
   */
  getTemplate(templateId: number): Observable<LinkTemplate> {
    return this.http.get<LinkTemplate>(
      `${this.templatesBasePath}/${templateId}`
    ).pipe(
      catchError(error => {
        console.error('Failed to fetch template:', error);
        throw error;
      })
    );
  }

  /**
   * Create a new template
   */
  createTemplate(template: Partial<LinkTemplate>): Observable<LinkTemplate> {
    return this.http.post<LinkTemplate>(
      this.templatesBasePath,
      template
    ).pipe(
      catchError(error => {
        console.error('Template creation failed:', error);
        throw error;
      })
    );
  }

  /**
   * Update an existing template
   */
  updateTemplate(templateId: number, updates: Partial<LinkTemplate>): Observable<LinkTemplate> {
    return this.http.patch<LinkTemplate>(
      `${this.templatesBasePath}/${templateId}`,
      updates
    ).pipe(
      catchError(error => {
        console.error('Template update failed:', error);
        throw error;
      })
    );
  }

  /**
   * Delete a template
   */
  deleteTemplate(templateId: number): Observable<void> {
    return this.http.delete<void>(
      `${this.templatesBasePath}/${templateId}`
    ).pipe(
      catchError(error => {
        console.error('Template deletion failed:', error);
        throw error;
      })
    );
  }

  /**
   * Clone a template with modifications
   */
  cloneTemplate(
    templateId: number,
    newName: string,
    modifications?: Partial<LinkTemplate>
  ): Observable<LinkTemplate> {
    return this.http.post<LinkTemplate>(
      `${this.templatesBasePath}/${templateId}/clone`,
      { new_name: newName, modifications }
    ).pipe(
      catchError(error => {
        console.error('Template cloning failed:', error);
        throw error;
      })
    );
  }

  /**
   * Get statistics for a template
   */
  getTemplateStatistics(templateId: number): Observable<{
    total_links: number;
    active_links: number;
    completed_links: number;
    archived_links: number;
    work_packages: number;
    ifc_models: number;
  }> {
    return this.http.get<any>(
      `${this.templatesBasePath}/${templateId}/statistics`
    ).pipe(
      catchError(error => {
        console.error('Failed to fetch template statistics:', error);
        throw error;
      })
    );
  }

  /**
   * Helper: Complete all active links for a work package
   */
  completeAllLinksForWorkPackage(workPackageId: number): Observable<{ updated_count: number }> {
    return this.http.get<{ link_ids: number[] }>(
      `${this.apiBasePath}?work_package_id=${workPackageId}&status=active`
    ).pipe(
      map(response => response.link_ids),
      switchMap(linkIds => {
        if (linkIds.length === 0) {
          return of({ updated_count: 0 });
        }
        return this.bulkStatusChange({
          link_ids: linkIds,
          new_status: 'completed'
        });
      }),
      catchError(error => {
        console.error('Failed to complete links:', error);
        throw error;
      })
    );
  }

  /**
   * Helper: Archive all links for an IFC model
   */
  archiveAllLinksForModel(ifcModelId: number): Observable<{ updated_count: number }> {
    return this.http.get<{ link_ids: number[] }>(
      `${this.apiBasePath}?ifc_model_id=${ifcModelId}`
    ).pipe(
      map(response => response.link_ids),
      switchMap(linkIds => {
        if (linkIds.length === 0) {
          return of({ updated_count: 0 });
        }
        return this.bulkStatusChange({
          link_ids: linkIds,
          new_status: 'archived'
        });
      }),
      catchError(error => {
        console.error('Failed to archive links:', error);
        throw error;
      })
    );
  }

  /**
   * Helper: Refresh all links that may have changed
   */
  refreshAllChangedLinks(linkIds: number[]): Observable<RefreshPropertiesResponse> {
    if (linkIds.length === 0) {
      return of({
        refreshed: [],
        changed: [],
        failed: [],
        refreshed_count: 0,
        changed_count: 0,
        failed_count: 0
      });
    }

    return this.refreshElementProperties(linkIds);
  }

  /**
   * Helper: Batch create links with progress tracking
   */
  createLinksWithProgress(
    requests: BulkLinkRequest[],
    onProgress?: (completed: number, total: number) => void
  ): Observable<BulkLinkResponse[]> {
    const total = requests.length;
    let completed = 0;

    const requestObservables = requests.map(request =>
      this.createBulkLinks(request).pipe(
        map(response => {
          completed++;
          if (onProgress) {
            onProgress(completed, total);
          }
          return response;
        })
      )
    );

    return forkJoin(requestObservables);
  }

  /**
   * Helper: Apply multiple templates at once
   */
  applyMultipleTemplates(
    workPackageId: number,
    ifcModelId: number,
    templateIds: number[]
  ): Observable<TemplateApplicationResponse[]> {
    const requests = templateIds.map(templateId =>
      this.applyTemplate({
        work_package_id: workPackageId,
        ifc_model_id: ifcModelId,
        template_id: templateId
      })
    );

    return forkJoin(requests);
  }

  /**
   * Helper: Create template from current selection
   */
  createTemplateFromSelection(
    name: string,
    description: string,
    relationshipType: RelationshipType,
    elementIds: string[],
    ifcModel: any, // IfcModel type
    projectId?: number
  ): Observable<LinkTemplate> {
    // Extract common properties from selected elements to build filters
    const filters = this.extractFiltersFromElements(elementIds, ifcModel);

    return this.createTemplate({
      name,
      description,
      relationship_type: relationshipType,
      element_filters: filters,
      project_id: projectId,
      auto_apply: false,
      public: false
    });
  }

  /**
   * Extract element filters from selected elements
   */
  private extractFiltersFromElements(elementIds: string[], ifcModel: any): ElementFilters {
    // This would analyze the selected elements and create appropriate filters
    // For now, return a basic type-based filter
    const types = new Set<string>();
    const storeys = new Set<string>();

    elementIds.forEach(elementId => {
      const element = ifcModel.metadata?.elements?.[elementId];
      if (element) {
        const type = element.properties?.type;
        if (type) types.add(type);

        const storey = element.spatial_structure?.storey;
        if (storey) storeys.add(storey);
      }
    });

    return {
      types: Array.from(types),
      locations: {
        storey: Array.from(storeys)
      }
    };
  }
}

// Missing import for switchMap
import { switchMap } from 'rxjs/operators';
