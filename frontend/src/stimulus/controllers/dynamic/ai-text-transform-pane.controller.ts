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
} from 'core-stimulus/controllers/dynamic/ai-text-transform-menu.controller';

const POLL_MIN = 400;
const POLL_MAX = 1000;
const POLL_HIDDEN = 5000;
const APPLY_TIMEOUT = 300;
const COPIED_FEEDBACK = 1500;
const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;

// A new start replaces the pane element; the user's position and size carry over to the next one.
let lastGeometry:Partial<Pick<CSSStyleDeclaration, 'left'|'top'|'right'|'bottom'|'width'|'height'>>|null = null;

/**
 * Demo (AI-126): the server-rendered AI result pane. It polls the pane endpoint while the text is
 * generating (the server answers with updated sections), and owns dragging, resizing, Escape and
 * Copy. Replace, close and retry are plain Turbo form submissions.
 */
export default class AiTextTransformPaneController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['turboRequests'];

  static targets = ['pane', 'state', 'raw', 'copyLabel', 'applyFailed', 'applyFailedMessage'];

  static values = {
    closeForm: String,
    editorGone: String,
    selectionGone: String,
    copied: String,
    copy: String,
  };

  declare readonly paneTarget:HTMLElement;
  declare readonly stateTarget:HTMLElement;
  declare readonly hasStateTarget:boolean;
  declare readonly rawTarget:HTMLTemplateElement;
  declare readonly copyLabelTarget:HTMLElement;
  declare readonly applyFailedTarget:HTMLElement;
  declare readonly applyFailedMessageTarget:HTMLElement;
  declare readonly closeFormValue:string;
  declare readonly editorGoneValue:string;
  declare readonly selectionGoneValue:string;
  declare readonly copiedValue:string;
  declare readonly copyValue:string;
  declare services:Promise<PickedServices<'turboRequests'>>;
  declare turboRequests:TurboRequestsService;

  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private pollDelay = POLL_MIN;
  private polling = false;
  private applyTimer:ReturnType<typeof setTimeout>|null = null;
  private answeredRequest:string|null = null;
  private closing = false;
  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:{ x:number; y:number; left:number; width:number; height:number; edge:string }|null = null;

  private readonly onPointerMove = (event:PointerEvent) => this.drag(event);
  private readonly onPointerUp = () => this.endDrag();
  private readonly onResizeMove = (event:PointerEvent) => this.resize(event);
  private readonly onResizeUp = () => this.endResize();
  private readonly onKeydown = (event:KeyboardEvent) => this.keydown(event);
  private readonly onApply = (event:Event) => this.awaitApplied((event as CustomEvent<AiTextTransformApplyDetail>).detail);
  private readonly onApplied = (event:Event) => this.applied((event as CustomEvent<AiTextTransformAppliedDetail>).detail);
  private readonly onSubmit = (event:SubmitEvent) => {
    if ((event.target as HTMLFormElement).id === this.closeFormValue) {
      this.closing = true;
    }
  };

  initialize():void {
    useAngularServices(this);
  }

  connect():void {
    this.restoreGeometry();
    this.element.addEventListener('submit', this.onSubmit);
    document.addEventListener('keydown', this.onKeydown);
    document.addEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, this.onApplied);
  }

  disconnect():void {
    this.saveGeometry();
    this.cancelIfAbandoned();
    this.element.removeEventListener('submit', this.onSubmit);
    document.removeEventListener('keydown', this.onKeydown);
    document.removeEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, this.onApplied);
    this.stopPolling();
    this.clearApplyTimer();
    this.endDrag();
    this.endResize();
  }

  // Every poll that brings news replaces the footer, so a new state target connects each time.
  stateTargetConnected(state:HTMLElement):void {
    if (state.dataset.state !== 'generating') {
      this.stopPolling();
    } else if (this.pollTimer === null && !this.polling) {
      this.schedulePoll(POLL_MIN);
    }
  }

  async copy():Promise<void> {
    await navigator.clipboard.writeText(this.rawTarget.content.textContent ?? '');
    this.copyLabelTarget.textContent = this.copiedValue;
    setTimeout(() => { this.copyLabelTarget.textContent = this.copyValue; }, COPIED_FEEDBACK);
  }

  beginDrag(event:PointerEvent):void {
    if ((event.target as HTMLElement).closest('button')) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    window.addEventListener('pointermove', this.onPointerMove);
    window.addEventListener('pointerup', this.onPointerUp);
    event.preventDefault();
  }

  // Resizing pins the pane to explicit coordinates first, so a right or bottom handle grows it in
  // place and a left handle moves the left edge only.
  beginResize(event:PointerEvent):void {
    const rect = this.paneTarget.getBoundingClientRect();
    const edge = (event.currentTarget as HTMLElement).dataset.edge ?? 'bottom-right';
    this.resizeStart = { x: event.clientX, y: event.clientY, left: rect.left, width: rect.width, height: rect.height, edge };
    this.pin(rect.left, rect.top);
    window.addEventListener('pointermove', this.onResizeMove);
    window.addEventListener('pointerup', this.onResizeUp);
    event.preventDefault();
  }

  private saveGeometry():void {
    const { left, top, right, bottom, width, height } = this.paneTarget.style;
    lastGeometry = left || width ? { left, top, right, bottom, width, height } : lastGeometry;
  }

  private restoreGeometry():void {
    if (lastGeometry) {
      Object.assign(this.paneTarget.style, lastGeometry);
    }
  }

  // Replaced by a new start or left with the page while still generating: stop the run.
  private cancelIfAbandoned():void {
    if (this.closing || !this.hasStateTarget || this.stateTarget.dataset.state !== 'generating') {
      return;
    }

    const url = new URL(this.stateTarget.dataset.pollUrl ?? '', window.location.origin);
    void fetch(`${url.pathname}/cancel`, {
      method: 'POST',
      credentials: 'same-origin',
      keepalive: true,
      headers: { 'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '' },
    });
  }

  private schedulePoll(delay:number):void {
    this.pollTimer = setTimeout(() => {
      this.pollTimer = null;
      void this.poll();
    }, document.hidden ? POLL_HIDDEN : delay);
  }

  private async poll():Promise<void> {
    if (!this.hasStateTarget) {
      return;
    }

    const url = new URL(this.stateTarget.dataset.pollUrl ?? '', window.location.origin);
    url.searchParams.set('after', this.stateTarget.dataset.seq ?? '0');
    const { turboRequests } = await this.services;

    this.polling = true;
    try {
      const { html } = await turboRequests.request(
        url.toString(),
        { method: 'GET', headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' },
        true,
      );
      this.pollDelay = html.trim() === '' ? Math.min(POLL_MAX, this.pollDelay * 1.5) : POLL_MIN;
    } catch {
      return;
    } finally {
      this.polling = false;
    }

    if (this.hasStateTarget && this.stateTarget.dataset.state === 'generating' && this.pollTimer === null) {
      this.schedulePoll(this.pollDelay);
    }
  }

  private stopPolling():void {
    if (this.pollTimer !== null) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }
  }

  private keydown(event:KeyboardEvent):void {
    if (event.key === 'Escape') {
      document.querySelector<HTMLFormElement>(`#${this.closeFormValue}`)?.requestSubmit();
    }
  }

  // Whoever owns the editor answers the apply event right away. Without an answer the editor is gone.
  private awaitApplied(detail:AiTextTransformApplyDetail):void {
    if (detail.requestId === this.answeredRequest || !this.ownsRequest(detail.requestId)) {
      return;
    }

    this.clearApplyTimer();
    this.applyTimer = setTimeout(() => this.showApplyFailure(this.editorGoneValue), APPLY_TIMEOUT);
  }

  private applied(detail:AiTextTransformAppliedDetail):void {
    if (!this.ownsRequest(detail.requestId)) {
      return;
    }

    this.answeredRequest = detail.requestId;
    this.clearApplyTimer();
    if (detail.ok) {
      this.element.remove();
    } else {
      this.showApplyFailure(this.selectionGoneValue);
    }
  }

  private ownsRequest(requestId:string):boolean {
    return this.hasStateTarget && this.stateTarget.dataset.requestId === requestId;
  }

  private showApplyFailure(message:string):void {
    this.applyFailedMessageTarget.textContent = message;
    this.applyFailedTarget.hidden = false;
  }

  private clearApplyTimer():void {
    if (this.applyTimer !== null) {
      clearTimeout(this.applyTimer);
      this.applyTimer = null;
    }
  }

  private drag(event:PointerEvent):void {
    if (!this.dragOffset) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    const maxLeft = window.innerWidth - rect.width - EDGE_MARGIN;
    const maxTop = window.innerHeight - EDGE_MARGIN * 6;
    const left = Math.min(Math.max(EDGE_MARGIN, event.clientX - this.dragOffset.x), Math.max(EDGE_MARGIN, maxLeft));
    const top = Math.min(Math.max(EDGE_MARGIN, event.clientY - this.dragOffset.y), maxTop);

    this.pin(left, top);
  }

  private pin(left:number, top:number):void {
    const { style } = this.paneTarget;
    style.left = `${left}px`;
    style.top = `${top}px`;
    style.right = 'auto';
    style.bottom = 'auto';
  }

  private endDrag():void {
    this.dragOffset = null;
    window.removeEventListener('pointermove', this.onPointerMove);
    window.removeEventListener('pointerup', this.onPointerUp);
  }

  private resize(event:PointerEvent):void {
    if (!this.resizeStart) {
      return;
    }

    const { edge, left, width, height, x, y } = this.resizeStart;
    const rect = this.paneTarget.getBoundingClientRect();
    const dx = event.clientX - x;
    const dy = event.clientY - y;

    if (edge.endsWith('left')) {
      const newWidth = Math.min(Math.max(MIN_WIDTH, width - dx), left + width - EDGE_MARGIN);
      this.pin(left + width - newWidth, rect.top);
      this.paneTarget.style.width = `${newWidth}px`;
    } else {
      const maxWidth = window.innerWidth - left - EDGE_MARGIN;
      this.paneTarget.style.width = `${Math.min(Math.max(MIN_WIDTH, width + dx), maxWidth)}px`;
    }

    if (edge.startsWith('bottom')) {
      const maxHeight = window.innerHeight - rect.top - EDGE_MARGIN;
      this.paneTarget.style.height = `${Math.min(Math.max(MIN_HEIGHT, height + dy), maxHeight)}px`;
    }
  }

  private endResize():void {
    this.resizeStart = null;
    window.removeEventListener('pointermove', this.onResizeMove);
    window.removeEventListener('pointerup', this.onResizeUp);
  }
}
