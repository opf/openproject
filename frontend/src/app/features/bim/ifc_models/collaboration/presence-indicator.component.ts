import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { PresenceService, ViewerPresence, CameraPosition } from './presence.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'op-presence-indicator',
  templateUrl: './presence-indicator.component.html',
  styleUrls: ['./presence-indicator.component.sass']
})
export class PresenceIndicatorComponent implements OnInit, OnDestroy {
  @Input() ifcModelId!: number;
  @Input() getCameraPosition?: () => CameraPosition | undefined;

  presence?: ViewerPresence;
  loading = true;
  error?: string;

  private destroy$ = new Subject<void>();
  private heartbeatSubscription?: any;

  constructor(private presenceService: PresenceService) {}

  ngOnInit(): void {
    if (!this.ifcModelId) {
      this.error = 'IFC Model ID is required';
      this.loading = false;
      return;
    }

    this.startPresenceTracking();
    this.startPresencePolling();
  }

  ngOnDestroy(): void {
    this.stopPresenceTracking();
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Start tracking user's presence
   */
  private startPresenceTracking(): void {
    const getCameraFn = this.getCameraPosition || (() => undefined);

    this.heartbeatSubscription = this.presenceService
      .startPresenceHeartbeat(this.ifcModelId, getCameraFn)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        error: (err) => {
          console.error('Presence heartbeat error:', err);
        }
      });
  }

  /**
   * Stop tracking user's presence
   */
  private stopPresenceTracking(): void {
    if (this.heartbeatSubscription) {
      this.heartbeatSubscription.unsubscribe();
    }

    this.presenceService.leaveViewing(this.ifcModelId).subscribe({
      error: (err) => console.error('Error leaving viewing session:', err)
    });
  }

  /**
   * Poll for presence updates from other users
   */
  private startPresencePolling(): void {
    this.presenceService
      .pollPresence(this.ifcModelId, 10000) // Poll every 10 seconds
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (presence) => {
          this.presence = presence;
          this.loading = false;
        },
        error: (err) => {
          this.error = `Failed to load presence: ${err.message}`;
          this.loading = false;
        }
      });
  }

  /**
   * Get viewer count text
   */
  getViewerText(): string {
    const count = this.presence?.active_viewers_count || 0;
    if (count === 0) return 'No one viewing';
    if (count === 1) return '1 viewer';
    return `${count} viewers`;
  }

  /**
   * Get color for user
   */
  getUserColor(userId: number): string {
    return this.presenceService.getUserColor(userId);
  }

  /**
   * Get initials for user
   */
  getUserInitials(user: { name: string }): string {
    return this.presenceService.getUserInitials(user.name);
  }
}
