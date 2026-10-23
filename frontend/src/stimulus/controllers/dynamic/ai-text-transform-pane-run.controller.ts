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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import {
  AI_TEXT_TRANSFORM_APPLIED_EVENT,
  AI_TEXT_TRANSFORM_APPLY_EVENT,
  AiTextTransformAppliedDetail,
  AiTextTransformApplyDetail,
} from 'core-app/core/ai-actions/ai-text-transform-events';

const POLL_MIN = 400;
const POLL_MAX = 1000;
const POLL_HIDDEN = 5000;
const APPLY_TIMEOUT = 300;
const PANE_SELECTOR = '[data-controller~="ai-text-transform-pane"]';

const pollDelays = new Map<string, number>();

/**
 * Demo glue (AI-126 demo branch, until AI-176): sits on the pane footer's state element, which the
 * server replaces on every poll that brings news. It polls while the run is generating, waits for
 * the editor's answer after Replace, and cancels the run when the pane disappears while generating.
 */
export default class AiTextTransformPaneRunController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['turboRequests'];

  static values = {
    state: String,
    run: String,
    seq: Number,
    requestId: String,
    pollUrl: String,
    editorGone: String,
    selectionGone: String,
  };

  declare readonly stateValue:string;
  declare readonly runValue:string;
  declare readonly seqValue:number;
  declare readonly requestIdValue:string;
  declare readonly pollUrlValue:string;
  declare readonly editorGoneValue:string;
  declare readonly selectionGoneValue:string;
  declare services:Promise<PickedServices<'turboRequests'>>;
  declare turboRequests:TurboRequestsService;

  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private applyTimer:ReturnType<typeof setTimeout>|null = null;
  private answered = false;

  private readonly onApply = (event:Event) => this.awaitApplied((event as CustomEvent<AiTextTransformApplyDetail>).detail);
  private readonly onApplied = (event:Event) => this.applied((event as CustomEvent<AiTextTransformAppliedDetail>).detail);

  initialize():void {
    useAngularServices(this);
  }

  connect():void {
    document.addEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, this.onApplied);
    if (this.stateValue === 'generating') {
      this.schedulePoll(pollDelays.get(this.runValue) ?? POLL_MIN);
    } else {
      pollDelays.delete(this.runValue);
    }
  }

  disconnect():void {
    document.removeEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, this.onApplied);
    this.clearTimers();
    this.cancelIfAbandoned();
  }

  private schedulePoll(delay:number):void {
    this.pollTimer = setTimeout(() => { void this.poll(delay); }, document.hidden ? POLL_HIDDEN : delay);
  }

  private async poll(delay:number):Promise<void> {
    this.pollTimer = null;
    const url = new URL(this.pollUrlValue, window.location.origin);
    url.searchParams.set('after', String(this.seqValue));
    const { turboRequests } = await this.services;

    try {
      const { html } = await turboRequests.request(
        url.toString(),
        { method: 'GET', headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' },
        true,
      );
      pollDelays.set(this.runValue, html.trim() === '' ? Math.min(POLL_MAX, delay * 1.5) : POLL_MIN);
    } catch {
      return;
    }

    // Without news the footer stays and this controller keeps polling; with news a new one takes over.
    if (this.element.isConnected) {
      this.schedulePoll(pollDelays.get(this.runValue) ?? POLL_MAX);
    }
  }

  // A pane replaced by a new start or left with the page while generating stops its run.
  private cancelIfAbandoned():void {
    if (this.stateValue !== 'generating') {
      return;
    }

    const stillShown = document.querySelector(`[data-ai-text-transform-pane-run-run-value="${this.runValue}"]`);
    if (stillShown) {
      return;
    }

    const url = new URL(this.pollUrlValue, window.location.origin);
    void fetch(`${url.pathname}/cancel`, {
      method: 'POST',
      credentials: 'same-origin',
      keepalive: true,
      headers: { 'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '' },
    });
  }

  // Whoever owns the editor answers the apply event right away; without an answer the editor is gone.
  private awaitApplied(detail:AiTextTransformApplyDetail):void {
    if (detail.requestId !== this.requestIdValue || this.answered) {
      return;
    }

    this.applyTimer = setTimeout(() => this.showApplyFailure(this.editorGoneValue), APPLY_TIMEOUT);
  }

  private applied(detail:AiTextTransformAppliedDetail):void {
    if (detail.requestId !== this.requestIdValue) {
      return;
    }

    this.answered = true;
    this.clearTimers();
    if (detail.ok) {
      this.element.closest(PANE_SELECTOR)?.remove();
    } else {
      this.showApplyFailure(this.selectionGoneValue);
    }
  }

  private showApplyFailure(message:string):void {
    const pane = this.element.closest(PANE_SELECTOR);
    const banner = pane?.querySelector<HTMLElement>('[data-ai-text-transform-pane-target="applyFailed"]');
    const text = pane?.querySelector<HTMLElement>('[data-ai-text-transform-pane-target="applyFailedMessage"]');
    if (banner && text) {
      text.textContent = message;
      banner.hidden = false;
    }
  }

  private clearTimers():void {
    if (this.pollTimer !== null) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }
    if (this.applyTimer !== null) {
      clearTimeout(this.applyTimer);
      this.applyTimer = null;
    }
  }
}
