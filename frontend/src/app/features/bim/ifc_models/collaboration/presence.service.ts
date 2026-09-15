import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, timer } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';

export interface ViewerPresence {
  ifc_model_id: number;
  active_viewers_count: number;
  viewers: Array<{
    id: number;
    name: string;
    login: string;
    initials: string;
  }>;
}

export interface CameraPosition {
  eye: number[];
  look: number[];
  up: number[];
}

@Injectable({
  providedIn: 'root'
})
export class PresenceService {
  private updateInterval = 30000; // Update every 30 seconds

  constructor(private http: HttpClient) {}

  /**
   * Get current viewers for a model
   */
  getPresence(ifcModelId: number): Observable<ViewerPresence> {
    return this.http.get<ViewerPresence>(
      `/api/v3/bim/ifc_models/${ifcModelId}/presence`
    );
  }

  /**
   * Join viewing session (create presence)
   */
  joinViewing(ifcModelId: number, cameraPosition?: CameraPosition): Observable<any> {
    return this.http.post(
      `/api/v3/bim/ifc_models/${ifcModelId}/presence`,
      { camera_position: cameraPosition }
    );
  }

  /**
   * Update presence (heartbeat)
   */
  updatePresence(ifcModelId: number, cameraPosition?: CameraPosition): Observable<any> {
    return this.http.put(
      `/api/v3/bim/ifc_models/${ifcModelId}/presence`,
      { camera_position: cameraPosition }
    );
  }

  /**
   * Leave viewing session (remove presence)
   */
  leaveViewing(ifcModelId: number): Observable<void> {
    return this.http.delete<void>(
      `/api/v3/bim/ifc_models/${ifcModelId}/presence`
    );
  }

  /**
   * Start periodic presence updates
   * Returns an observable that emits on each update
   */
  startPresenceHeartbeat(
    ifcModelId: number,
    getCameraPosition: () => CameraPosition | undefined
  ): Observable<any> {
    // Initial join
    const initialCamera = getCameraPosition();
    return this.joinViewing(ifcModelId, initialCamera).pipe(
      switchMap(() =>
        // Then update periodically
        timer(this.updateInterval, this.updateInterval).pipe(
          switchMap(() => {
            const camera = getCameraPosition();
            return this.updatePresence(ifcModelId, camera);
          })
        )
      )
    );
  }

  /**
   * Poll for presence updates
   */
  pollPresence(ifcModelId: number, interval = 10000): Observable<ViewerPresence> {
    return timer(0, interval).pipe(
      switchMap(() => this.getPresence(ifcModelId))
    );
  }

  /**
   * Get user initials from name
   */
  getUserInitials(name: string): string {
    const parts = name.trim().split(' ');
    if (parts.length === 0) return '?';
    if (parts.length === 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /**
   * Get color for user (deterministic based on user ID)
   */
  getUserColor(userId: number): string {
    const colors = [
      '#3498DB', // Blue
      '#E74C3C', // Red
      '#2ECC71', // Green
      '#F39C12', // Orange
      '#9B59B6', // Purple
      '#1ABC9C', // Turquoise
      '#E67E22', // Carrot
      '#95A5A6'  // Gray
    ];

    return colors[userId % colors.length];
  }
}
