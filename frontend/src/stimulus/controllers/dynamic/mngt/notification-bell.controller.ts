import { Controller } from '@hotwired/stimulus';

const BELL_DISPLAY_LIMIT = 99;
const FILTERS = encodeURIComponent(JSON.stringify([['readIAN', '=', ['f']]]));
const API_URL = `/api/v3/notifications?filters=${FILTERS}&pageSize=0`;

export default class extends Controller {
  static targets = ['badge'];
  static values = {
    interval: { type: Number, default: 50000 },
  };

  declare badgeTarget: HTMLElement;
  declare hasBadgeTarget: boolean;
  declare intervalValue: number;

  private timer: ReturnType<typeof setTimeout> | null = null;

  connect(): void {
    void this.fetchCount();
    this.scheduleNext();
    document.addEventListener('visibilitychange', this.onVisibilityChange);
    document.addEventListener('ian-update-immediate', this.onImmediateUpdate);
  }

  disconnect(): void {
    this.clearTimer();
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    document.removeEventListener('ian-update-immediate', this.onImmediateUpdate);
  }

  private readonly onVisibilityChange = (): void => {
    this.clearTimer();
    this.scheduleNext();
  };

  private readonly onImmediateUpdate = (): void => {
    this.clearTimer();
    void this.fetchCount();
    this.scheduleNext();
  };

  private scheduleNext(): void {
    const delay = document.hidden ? this.intervalValue * 10 : this.intervalValue;
    this.timer = setTimeout(() => {
      void this.fetchCount();
      this.scheduleNext();
    }, delay);
  }

  private clearTimer(): void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  private async fetchCount(): Promise<void> {
    try {
      const res = await fetch(API_URL, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin',
      });
      if (!res.ok) return;
      const data = await res.json() as { total?: number };
      this.updateBadge(data.total ?? 0);
    } catch {
      // Silently ignore network errors
    }
  }

  private updateBadge(count: number): void {
    if (!this.hasBadgeTarget) return;

    if (count <= 0) {
      this.badgeTarget.hidden = true;
      this.badgeTarget.textContent = '';
    } else {
      this.badgeTarget.hidden = false;
      this.badgeTarget.classList.toggle('op-ian-bell--indicator_max', count > BELL_DISPLAY_LIMIT);
      this.badgeTarget.textContent = count > BELL_DISPLAY_LIMIT ? '' : String(count);
    }
  }
}
