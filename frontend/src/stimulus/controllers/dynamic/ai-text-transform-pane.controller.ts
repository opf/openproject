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
import { closestDragBlockingElement } from 'core-stimulus/helpers/interactive-element-helper';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;
const GEOMETRY_PROPERTIES = ['left', 'top', 'right', 'bottom', 'width', 'height', 'maxWidth', 'maxHeight'] as const;
const POLL_MIN = 400;
const POLL_MAX = 1000;
const POLL_BACKOFF = 1.5;
const POLL_HIDDEN = 5000;
const APPLY_TIMEOUT = 300;

type Geometry = Partial<Record<typeof GEOMETRY_PROPERTIES[number], string>>;

interface RequestDetail {
  requestId?:string;
}

interface AppliedDetail extends RequestDetail {
  ok?:boolean;
}

interface SubmitEndDetail {
  success?:boolean;
}

interface ResizeStart {
  x:number;
  y:number;
  left:number;
  top:number;
  width:number;
  height:number;
  edge:string;
}

// A new run replaces the whole pane element, so the place the user moved it to outlives the controller.
let rememberedGeometry:Geometry|null = null;

const clamp = (value:number, min:number, max:number) => Math.min(Math.max(min, value), max);

export default class AiTextTransformPaneController extends Controller<HTMLElement> {
  static targets = ['pane', 'state', 'error', 'errorMessage'];

  static values = {
    closeForm: String,
    editorGone: String,
    selectionGone: String,
    requestFailed: String,
  };

  static services:ServiceKey[] = ['turboRequests'];

  declare readonly paneTarget:HTMLElement;
  declare readonly errorTarget:HTMLElement;
  declare readonly errorMessageTarget:HTMLElement;
  declare readonly hasErrorTarget:boolean;
  declare readonly closeFormValue:string;
  declare readonly editorGoneValue:string;
  declare readonly selectionGoneValue:string;
  declare readonly requestFailedValue:string;
  declare services:Promise<PickedServices<'turboRequests'>>;

  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:ResizeStart|null = null;
  private pointerListeners:AbortController|null = null;

  private run = { state: '', seq: '0', requestId: '', pollUrl: '' };
  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private pollInFlight = false;
  private pollDelay = POLL_MIN;
  private applyTimer:ReturnType<typeof setTimeout>|null = null;
  private applyAnswered = false;
  private closing = false;
  private abandoned = false;
  private focusToRestore:{ form:string }|null = null;

  initialize():void {
    useAngularServices(this);
  }

  connect():void {
    if (rememberedGeometry) {
      Object.assign(this.paneTarget.style, rememberedGeometry);
      this.keepInViewport();
    }
    this.paneTarget.focus({ preventScroll: true });
  }

  disconnect():void {
    this.endPointerAction();
    this.stopPolling();
    this.clearApplyTimer();
    rememberedGeometry = this.pinned ? this.geometry() : null;
    if (!this.element.isConnected) {
      this.abandon();
    }
  }

  // The footer, and with it the state element, is replaced on every poll that brings news.
  stateTargetConnected(element:HTMLElement):void {
    const { state = '', seq = '0', requestId = '', pollUrl = '' } = element.dataset;
    this.run = { state, seq, requestId, pollUrl };
    this.restoreFocus();

    if (state === 'generating') {
      this.schedulePoll();
    } else {
      this.stopPolling();
    }
  }

  rememberFocus(event:Event):void {
    const target = (event.target as Element).getAttribute('target');
    const focused = document.activeElement;
    if (!target || !this.element.querySelector(`#${CSS.escape(target)}`)) {
      return;
    }

    if (!this.focusToRestore && focused && focused !== this.paneTarget && this.element.contains(focused)) {
      this.focusToRestore = { form: focused.getAttribute('form') ?? '' };
    }
  }

  submitStarted(event:Event):void {
    const form = event.target as HTMLFormElement;
    if (form.id === this.closeFormValue) {
      this.closing = true;
      return;
    }

    this.hideError();
    this.setButtonsDisabled(form.id, true);
  }

  submitEnded(event:CustomEvent<SubmitEndDetail>):void {
    const form = event.target as HTMLFormElement;
    const { success } = event.detail;

    if (form.id === this.closeFormValue) {
      this.closing = success === true;
      if (success === false) {
        this.element.remove();
      }
    } else if (success === false) {
      this.setButtonsDisabled(form.id, false);
      this.showError(this.requestFailedValue);
    }
  }

  // Whoever owns the editor answers right away; without an answer the editor is gone.
  accepted(event:CustomEvent<RequestDetail>):void {
    if (!this.isOwnRequest(event.detail) || this.applyAnswered || this.applyTimer) {
      return;
    }

    this.applyTimer = setTimeout(() => {
      this.applyTimer = null;
      this.showError(this.editorGoneValue);
    }, APPLY_TIMEOUT);
  }

  applied(event:CustomEvent<AppliedDetail>):void {
    if (!this.isOwnRequest(event.detail)) {
      return;
    }

    this.applyAnswered = true;
    this.clearApplyTimer();
    if (event.detail.ok) {
      this.element.remove();
    } else {
      this.showError(this.selectionGoneValue);
    }
  }

  abandon(event?:PageTransitionEvent):void {
    if (event?.persisted) {
      return;
    }
    if (this.run.state !== 'generating' || this.closing || this.abandoned || !this.run.pollUrl) {
      return;
    }

    this.abandoned = true;
    const { pathname } = new URL(this.run.pollUrl, window.location.origin);
    void fetch(`${pathname}/cancel`, {
      method: 'POST',
      credentials: 'same-origin',
      keepalive: true,
      headers: { 'X-CSRF-Token': getMetaContent('csrf-token') },
    }).catch(() => undefined);
  }

  beginDrag(event:PointerEvent):void {
    if (event.button !== 0 || closestDragBlockingElement(event.target as Element, event.currentTarget as Element)) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    this.listen((move) => this.drag(move));
    event.preventDefault();
  }

  beginResize(event:PointerEvent):void {
    if (event.button !== 0) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.resizeStart = {
      x: event.clientX,
      y: event.clientY,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      edge: (event.currentTarget as HTMLElement).dataset.edge ?? 'bottom-right',
    };
    this.pin(rect.left, rect.top);
    this.listen((move) => this.resize(move));
    event.preventDefault();
  }

  keepInViewport():void {
    if (this.pinned) {
      const rect = this.paneTarget.getBoundingClientRect();
      this.pinInViewport(rect.left, rect.top);
    }
  }

  close(event?:Event):void {
    event?.stopPropagation();
    const form = document.getElementById(this.closeFormValue);
    if (form instanceof HTMLFormElement) {
      form.requestSubmit();
    } else {
      this.element.remove();
    }
  }

  private get pinned():boolean {
    return this.paneTarget.style.left !== '';
  }

  private schedulePoll():void {
    if (this.pollTimer || this.pollInFlight) {
      return;
    }

    this.pollTimer = setTimeout(() => { void this.poll(); }, document.hidden ? POLL_HIDDEN : this.pollDelay);
  }

  private stopPolling():void {
    if (this.pollTimer) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }
  }

  private async poll():Promise<void> {
    this.pollTimer = null;
    this.pollInFlight = true;
    const url = new URL(this.run.pollUrl, window.location.origin);
    url.searchParams.set('after', this.run.seq);
    url.searchParams.set('state', this.run.state);

    try {
      const { turboRequests } = await this.services;
      const { html } = await turboRequests.request(
        url.toString(),
        { method: 'GET', headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' },
        true,
      );
      this.pollDelay = html.trim() === '' ? Math.min(POLL_MAX, this.pollDelay * POLL_BACKOFF) : POLL_MIN;
    } catch {
      this.showError(this.requestFailedValue);
      return;
    } finally {
      this.pollInFlight = false;
    }

    if (this.element.isConnected && this.run.state === 'generating') {
      this.schedulePoll();
    }
  }

  private restoreFocus():void {
    const restore = this.focusToRestore;
    this.focusToRestore = null;
    if (!restore || this.element.contains(document.activeElement)) {
      return;
    }

    const button = restore.form ? this.buttonsOf(restore.form).find((candidate) => !candidate.disabled) : undefined;
    (button ?? this.paneTarget).focus({ preventScroll: true });
  }

  private isOwnRequest(detail:RequestDetail|undefined):boolean {
    return !!this.run.requestId && detail?.requestId === this.run.requestId;
  }

  private buttonsOf(formId:string):HTMLButtonElement[] {
    return Array.from(this.element.querySelectorAll<HTMLButtonElement>(`button[form="${formId}"]`));
  }

  private setButtonsDisabled(formId:string, disabled:boolean):void {
    this.buttonsOf(formId).forEach((button) => { button.disabled = disabled; });
  }

  private showError(message:string):void {
    if (this.hasErrorTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorTarget.hidden = false;
    }
  }

  private hideError():void {
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true;
    }
  }

  private clearApplyTimer():void {
    if (this.applyTimer) {
      clearTimeout(this.applyTimer);
      this.applyTimer = null;
    }
  }

  private drag(event:PointerEvent):void {
    if (this.dragOffset) {
      this.pinInViewport(event.clientX - this.dragOffset.x, event.clientY - this.dragOffset.y);
    }
  }

  private resize(event:PointerEvent):void {
    if (!this.resizeStart) {
      return;
    }

    const { x, y, left, top, width, height, edge } = this.resizeStart;
    const { style } = this.paneTarget;
    style.maxWidth = `calc(100vw - ${2 * EDGE_MARGIN}px)`;

    if (edge.endsWith('left')) {
      const newWidth = clamp(width - (event.clientX - x), MIN_WIDTH, left + width - EDGE_MARGIN);
      this.pin(left + width - newWidth, top);
      style.width = `${newWidth}px`;
    } else {
      style.width = `${clamp(width + (event.clientX - x), MIN_WIDTH, window.innerWidth - left - EDGE_MARGIN)}px`;
    }

    if (edge.startsWith('bottom')) {
      style.height = `${clamp(height + (event.clientY - y), MIN_HEIGHT, window.innerHeight - top - EDGE_MARGIN)}px`;
      style.maxHeight = `calc(100vh - ${2 * EDGE_MARGIN}px)`;
    }
  }

  private pinInViewport(left:number, top:number):void {
    const { width, height } = this.paneTarget.getBoundingClientRect();
    const maxLeft = Math.max(EDGE_MARGIN, window.innerWidth - width - EDGE_MARGIN);
    const maxTop = Math.max(EDGE_MARGIN, window.innerHeight - height - EDGE_MARGIN);

    this.pin(clamp(left, EDGE_MARGIN, maxLeft), clamp(top, EDGE_MARGIN, maxTop));
  }

  private pin(left:number, top:number):void {
    Object.assign(this.paneTarget.style, { left: `${left}px`, top: `${top}px`, right: 'auto', bottom: 'auto' });
  }

  private geometry():Geometry {
    const { style } = this.paneTarget;
    return Object.fromEntries(GEOMETRY_PROPERTIES.map((property) => [property, style[property]]));
  }

  private listen(onMove:(event:PointerEvent) => void):void {
    this.pointerListeners?.abort();
    this.pointerListeners = new AbortController();
    const { signal } = this.pointerListeners;
    const end = () => this.endPointerAction();

    window.addEventListener('pointermove', onMove, { signal });
    window.addEventListener('pointerup', end, { signal });
    window.addEventListener('pointercancel', end, { signal });
  }

  private endPointerAction():void {
    this.pointerListeners?.abort();
    this.pointerListeners = null;
    this.dragOffset = null;
    this.resizeStart = null;
  }
}
