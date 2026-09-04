import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface FederationModel {
  id: number;
  discipline: string;
  discipline_name: string;
  transform: {
    translation: number[];
    rotation: number[];
    scale: number[];
  };
  visible: boolean;
  color: string;
  opacity: number;
  display_order: number;
  ifc_model: {
    id: number;
    title: string;
  };
}

export interface ModelFederation {
  id: number;
  name: string;
  description: string;
  base_point: { x: number; y: number; z: number };
  rotation: { x: number; y: number; z: number };
  units: string;
  created_at: string;
  updated_at: string;
  _embedded: {
    models: FederationModel[];
  };
  statistics: {
    model_count: number;
    disciplines: Record<string, number>;
    total_elements: number;
    visible_models: number;
  };
}

export interface FederationViewerConfig {
  federation_id: number;
  name: string;
  base_point: { x: number; y: number; z: number };
  rotation: { x: number; y: number; z: number };
  units: string;
  models: Array<{
    id: number;
    ifc_model_id: number;
    model_name: string;
    discipline: string;
    transform: {
      translation: number[];
      rotation: number[];
      scale: number[];
    };
    visible: boolean;
    color: string;
    opacity: number;
    display_order: number;
  }>;
}

export interface CreateFederationParams {
  name: string;
  description?: string;
  model_ids: number[];
  units?: string;
  auto_align?: boolean;
  base_point?: { x: number; y: number; z: number };
  rotation?: { x: number; y: number; z: number };
}

@Injectable({
  providedIn: 'root'
})
export class FederationService {
  constructor(private http: HttpClient) {}

  /**
   * List all federations for a project
   */
  list(projectId: number): Observable<ModelFederation[]> {
    return this.http
      .get<{ _embedded: { elements: ModelFederation[] } }>(
        `/api/v3/projects/${projectId}/bim/federations`
      )
      .pipe(map(response => response._embedded.elements));
  }

  /**
   * Get a specific federation
   */
  get(projectId: number, federationId: number): Observable<ModelFederation> {
    return this.http.get<ModelFederation>(
      `/api/v3/projects/${projectId}/bim/federations/${federationId}`
    );
  }

  /**
   * Create a new federation
   */
  create(projectId: number, params: CreateFederationParams): Observable<ModelFederation> {
    return this.http.post<ModelFederation>(
      `/api/v3/projects/${projectId}/bim/federations`,
      params
    );
  }

  /**
   * Update a federation
   */
  update(
    projectId: number,
    federationId: number,
    params: Partial<CreateFederationParams>
  ): Observable<ModelFederation> {
    return this.http.put<ModelFederation>(
      `/api/v3/projects/${projectId}/bim/federations/${federationId}`,
      params
    );
  }

  /**
   * Delete a federation
   */
  delete(projectId: number, federationId: number): Observable<void> {
    return this.http.delete<void>(
      `/api/v3/projects/${projectId}/bim/federations/${federationId}`
    );
  }

  /**
   * Auto-align models in a federation
   */
  align(projectId: number, federationId: number): Observable<any> {
    return this.http.post(
      `/api/v3/projects/${projectId}/bim/federations/${federationId}/align`,
      {}
    );
  }

  /**
   * Get viewer configuration for multi-model loading
   */
  getViewerConfig(projectId: number, federationId: number): Observable<FederationViewerConfig> {
    return this.http.get<FederationViewerConfig>(
      `/api/v3/projects/${projectId}/bim/federations/${federationId}/viewer_config`
    );
  }

  /**
   * Group federation models by discipline
   */
  groupByDiscipline(models: FederationModel[]): Map<string, FederationModel[]> {
    const grouped = new Map<string, FederationModel[]>();

    models.forEach(model => {
      const discipline = model.discipline || 'other';
      if (!grouped.has(discipline)) {
        grouped.set(discipline, []);
      }
      grouped.get(discipline)!.push(model);
    });

    return grouped;
  }

  /**
   * Get discipline color
   */
  getDisciplineColor(discipline: string): string {
    const colors: Record<string, string> = {
      architectural: '#3498DB',
      structural: '#E74C3C',
      mechanical: '#2ECC71',
      electrical: '#F39C12',
      plumbing: '#9B59B6',
      civil: '#95A5A6',
      landscape: '#1ABC9C',
      other: '#34495E'
    };

    return colors[discipline] || colors['other'];
  }

  /**
   * Get discipline icon name
   */
  getDisciplineIcon(discipline: string): string {
    const icons: Record<string, string> = {
      architectural: 'building',
      structural: 'columns',
      mechanical: 'gear',
      electrical: 'bolt',
      plumbing: 'faucet',
      civil: 'road',
      landscape: 'tree',
      other: 'cube'
    };

    return icons[discipline] || icons['other'];
  }
}
