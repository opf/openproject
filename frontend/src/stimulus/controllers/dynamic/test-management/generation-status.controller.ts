//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { useMeta } from 'stimulus-use';
import type { FrameElement } from '@hotwired/turbo';

type GenerationState = 'queued' | 'running' | 'succeeded' | 'failed' | 'cancelled';

interface Progress {
  done:number;
  total:number;
}

interface StatusPayload {
  state:GenerationState;
  step?:string;
  step_index?:number;
  step_count?:number;
  progress:{ done:number; total:number } | null;
  message:string;
  started_at:string | null;
  updated_at:string | null;
  error:string | null;
}

export default class GenerationStatusController extends Controller<HTMLElement> {
  static metaNames = ['csrf-token'];

  static targets = [
    'banner',
    'message',
    'elapsed',
    'activity',
    'steps',
    'progressContainer',
    'progressBar',
    'cancelButton',
    'checkAgainButton',
    'tryAgainButton',
  ];


  static values = {
    url: String,
    cancelUrl: String,
    retryUrl: String,
    interval: { type: Number, default: 2500 },
    timeout: { type: Number, default: 300_000 },
    frameId: { type: String, default: 'tm-draft-results' },
    frameUrl: String,
    pendingMessage: String,
    progressMessage: String,
    succeededMessage: String,
    failedMessage: String,
    cancelledMessage: String,
    timeoutMessage: String,
    reconnectMessage: String,
    workingMessage: String,
    lastUpdateMessage: String,
    checkAgain: String,
    tryAgain: String,
    cancelLabel: String,
  };

  declare readonly csrfToken:string;
  declare readonly urlValue:string;
  declare readonly cancelUrlValue:string;
  declare readonly retryUrlValue:string;
  declare readonly intervalValue:number;
  declare readonly timeoutValue:number;
  declare readonly frameIdValue:string;
  declare readonly frameUrlValue:string;
  declare readonly pendingMessageValue:string;
  declare readonly progressMessageValue:string;
  declare readonly succeededMessageValue:string;
  declare readonly failedMessageValue:string;
  declare readonly cancelledMessageValue:string;
  declare readonly timeoutMessageValue:string;
  declare readonly reconnectMessageValue:string;
  declare readonly workingMessageValue:string;
  declare readonly lastUpdateMessageValue:string;

  declare readonly hasBannerTarget:boolean;
  declare readonly hasMessageTarget:boolean;
  declare readonly hasElapsedTarget:boolean;
  declare readonly hasActivityTarget:boolean;
  declare readonly hasStepsTarget:boolean;
  declare readonly hasProgressContainerTarget:boolean;
  declare readonly hasProgressBarTarget:boolean;
  declare readonly hasCancelButtonTarget:boolean;
  declare readonly hasCheckAgainButtonTarget:boolean;
  declare readonly hasTryAgainButtonTarget:boolean;
  declare readonly bannerTarget:HTMLElement;
  declare readonly messageTarget:HTMLElement;
  declare readonly elapsedTarget:HTMLElement;
  declare readonly activityTarget:HTMLElement;
  declare readonly stepsTarget:HTMLElement;
  declare readonly progressContainerTarget:HTMLElement;
  declare readonly progressBarTarget:HTMLElement;
  declare readonly cancelButtonTarget:HTMLButtonElement;
  declare readonly checkAgainButtonTarget:HTMLButtonElement;
  declare readonly tryAgainButtonTarget:HTMLButtonElement;

  private pollTimer:ReturnType<typeof setTimeout> | null = null;
  private elapsedTimer:ReturnType<typeof setInterval> | null = null;
  private abortController:AbortController | null = null;
  private startedAt = Date.now();
  private lastServerUpdateAt:number | null = null;
  private consecutiveFailures = 0;
  private stopped = false;
  private paused = false;
  private currentInterval = 0;
  private boundVisibility = () => this.onVisibilityChange();

  connect():void {
    useMeta(this, { suffix: false });
    this.currentInterval = this.intervalValue;
    this.startedAt = Date.now();
    document.addEventListener('visibilitychange', this.boundVisibility);
    this.startElapsed();
    if (!document.hidden) {
      void this.poll();
    } else {
      this.paused = true;
    }
  }

  disconnect():void {
    this.stopAll();
    document.removeEventListener('visibilitychange', this.boundVisibility);
  }

  checkAgain(event?:Event):void {
    event?.preventDefault();
    this.stopped = false;
    this.consecutiveFailures = 0;
    this.currentInterval = this.intervalValue;
    this.startedAt = Date.now();
    this.hide(this.hasCheckAgainButtonTarget ? this.checkAgainButtonTarget : null);
    this.show(this.hasCancelButtonTarget ? this.cancelButtonTarget : null);
    void this.poll();
  }

  async cancel(event?:Event):Promise<void> {
    event?.preventDefault();
    if (!this.cancelUrlValue) return;

    this.stopPolling();
    try {
      const response = await fetch(this.cancelUrlValue, {
        method: 'POST',
        credentials: 'same-origin',
        headers: this.jsonHeaders(),
        signal: this.freshAbortSignal(),
      });
      if (!response.ok) {
        throw new Error(`cancel failed: ${response.status}`);
      }
      const payload = await response.json() as StatusPayload;
      this.handleTerminal(payload);
    } catch {
      this.setMessage(this.cancelledMessageValue || 'Cancelled');
      this.stopAll();
    }
  }

  async retry(event?:Event):Promise<void> {
    event?.preventDefault();
    if (!this.retryUrlValue) return;

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = this.retryUrlValue;
    form.style.display = 'none';

    const csrf = document.createElement('input');
    csrf.type = 'hidden';
    csrf.name = 'authenticity_token';
    csrf.value = this.csrfToken;
    form.appendChild(csrf);
    document.body.appendChild(form);
    form.submit();
  }

  private onVisibilityChange():void {
    if (document.hidden) {
      this.paused = true;
      this.stopPolling();
      return;
    }

    this.paused = false;
    if (!this.stopped) {
      void this.poll();
    }
  }

  private async poll():Promise<void> {
    if (this.stopped || this.paused) return;

    if (Date.now() - this.startedAt >= this.timeoutValue) {
      this.onTimeout();
      return;
    }

    try {
      const response = await fetch(this.urlValue, {
        method: 'GET',
        credentials: 'same-origin',
        headers: this.jsonHeaders(),
        signal: this.freshAbortSignal(),
      });

      if (!response.ok) {
        throw new Error(`status ${response.status}`);
      }

      const payload = await response.json() as StatusPayload;
      this.consecutiveFailures = 0;
      this.applyPayload(payload);

      if (this.isTerminal(payload.state)) {
        this.handleTerminal(payload);
        return;
      }

      this.scheduleNext(this.pollInterval());
    } catch (error) {
      if ((error as Error).name === 'AbortError') return;

      this.consecutiveFailures += 1;
      if (this.consecutiveFailures >= 3 && this.hasMessageTarget) {
        this.setMessage(this.reconnectMessageValue || 'Reconnecting…');
      }
      this.scheduleNext(this.backoffInterval());
    }
  }

  private applyPayload(payload:StatusPayload):void {
    this.setMessage(payload.message || this.pendingMessageValue);
    this.updateSteps(payload.step);
    this.rememberServerUpdate(payload.updated_at);
    const progress = payload.progress;
    if (progress && progress.total > 0) {
      this.updateProgressBar(progress);
    } else {
      this.hideProgressBar();
    }
  }

  private rememberServerUpdate(updatedAt:string | null):void {
    if (!updatedAt) return;
    const parsed = Date.parse(updatedAt);
    if (!Number.isNaN(parsed)) {
      this.lastServerUpdateAt = parsed;
      this.updateActivity();
    }
  }

  private updateSteps(currentStep:string | undefined):void {
    if (!this.hasStepsTarget || !currentStep) return;

    const order = ['queued', 'preparing_source', 'waiting_for_model', 'writing_drafts'];
    const currentIndex = order.indexOf(currentStep);
    this.stepsTarget.querySelectorAll<HTMLElement>('[data-step]').forEach((item) => {
      const step = item.dataset.step || '';
      const index = order.indexOf(step);
      item.classList.toggle('is-current', step === currentStep);
      item.classList.toggle('is-done', currentIndex > -1 && index > -1 && index < currentIndex);
    });
  }


  private updateProgressBar(progress:Progress):void {
    if (!this.hasProgressContainerTarget || !this.hasProgressBarTarget) return;

    this.progressContainerTarget.hidden = false;
    const pct = Math.max(0, Math.min(100, Math.round((progress.done / progress.total) * 100)));
    const item = this.progressBarTarget.querySelector<HTMLElement>('.ProgressBar-item');
    if (item) {
      item.style.width = `${pct}%`;
    }
  }

  private hideProgressBar():void {
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.hidden = true;
    }
  }

  private handleTerminal(payload:StatusPayload):void {
    this.stopAll();
    this.hide(this.hasCancelButtonTarget ? this.cancelButtonTarget : null);
    // Poll chrome is only present while pending; hide it so the Turbo Frame result is authoritative.
    if (this.hasBannerTarget) {
      this.bannerTarget.hidden = true;
    }

    switch (payload.state) {
      case 'succeeded':
        this.reloadFrame();
        this.focusResultsHeading();
        break;
      case 'failed':
      case 'cancelled':
        this.reloadFrame();
        break;
      default:
        this.setMessage(payload.message);
    }
  }

  private formatSucceeded(payload:StatusPayload):string {
    const count = payload.progress?.done ?? payload.progress?.total;
    const template = this.succeededMessageValue;
    if (template && count != null) {
      return template.replace('%{count}', String(count));
    }
    return payload.message;
  }

  private formatFailed(payload:StatusPayload):string {
    const template = this.failedMessageValue;
    const error = payload.error || '';
    if (template) {
      return template.replace('%{error}', error);
    }
    return payload.message || error;
  }

  private onTimeout():void {
    this.stopPolling();
    this.setMessage(this.timeoutMessageValue || 'Still working — check again');
    this.hide(this.hasCancelButtonTarget ? this.cancelButtonTarget : null);
    this.show(this.hasCheckAgainButtonTarget ? this.checkAgainButtonTarget : null);
    this.stopped = true;
  }

  private reloadFrame():void {
    const frame = document.getElementById(this.frameIdValue) as FrameElement | null;
    if (!frame) return;

    const url = this.frameUrlValue
      || `${window.location.pathname}${window.location.search}`;
    const current = frame.getAttribute('src');
    if (current === url && typeof frame.reload === 'function') {
      frame.reload();
      return;
    }

    // Setting src triggers a Turbo Frame fetch; required when the frame had no src at render.
    frame.src = url;
  }

  private focusResultsHeading():void {
    window.setTimeout(() => {
      const heading = document.getElementById('tm-draft-results-heading');
      heading?.focus();
    }, 100);
  }

  private isTerminal(state:GenerationState):boolean {
    return state === 'succeeded' || state === 'failed' || state === 'cancelled';
  }

  private pollInterval():number {
    if (Date.now() - this.startedAt >= 30_000) {
      this.currentInterval = Math.max(this.currentInterval, 5000);
    }
    return this.currentInterval;
  }

  private backoffInterval():number {
    const delay = Math.min(15_000, this.intervalValue * (2 ** Math.min(this.consecutiveFailures, 4)));
    return delay;
  }

  private scheduleNext(ms:number):void {
    this.stopPolling();
    if (this.stopped || this.paused) return;
    this.pollTimer = setTimeout(() => { void this.poll(); }, ms);
  }

  private startElapsed():void {
    if (this.hasActivityTarget) {
      const initial = this.activityTarget.dataset.updatedAt;
      if (initial) this.rememberServerUpdate(initial);
    }
    this.updateElapsed();
    this.elapsedTimer = setInterval(() => {
      this.updateElapsed();
      this.updateActivity();
    }, 1000);
  }

  private updateElapsed():void {
    if (!this.hasElapsedTarget) return;
    const seconds = Math.floor((Date.now() - this.startedAt) / 1000);
    const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
    const ss = String(seconds % 60).padStart(2, '0');
    this.elapsedTarget.textContent = `${mm}:${ss}`;
  }

  private updateActivity():void {
    if (!this.hasActivityTarget || this.lastServerUpdateAt == null) return;
    const seconds = Math.max(0, Math.floor((Date.now() - this.lastServerUpdateAt) / 1000));
    if (seconds < 2) {
      this.activityTarget.textContent = this.workingMessageValue || '· working…';
      return;
    }
    const template = this.lastUpdateMessageValue || '· last update %{seconds}s ago';
    this.activityTarget.textContent = template.replace('%{seconds}', String(seconds));
  }

  private setMessage(text:string):void {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = text;
    }
  }

  private jsonHeaders():HeadersInit {
    return {
      Accept: 'application/json',
      'X-CSRF-Token': this.csrfToken,
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  private freshAbortSignal():AbortSignal {
    this.abortController?.abort();
    this.abortController = new AbortController();
    return this.abortController.signal;
  }

  private stopPolling():void {
    if (this.pollTimer != null) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }
    this.abortController?.abort();
    this.abortController = null;
  }

  private stopAll():void {
    this.stopped = true;
    this.stopPolling();
    if (this.elapsedTimer != null) {
      clearInterval(this.elapsedTimer);
      this.elapsedTimer = null;
    }
  }

  private show(el:HTMLElement | null):void {
    if (el) el.hidden = false;
  }

  private hide(el:HTMLElement | null):void {
    if (el) el.hidden = true;
  }
}
