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
import { renderStreamMessage } from '@hotwired/turbo';
import { closestDragBlockingElement } from 'core-stimulus/helpers/interactive-element-helper';
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;
const VERTICAL_RESIZE_THRESHOLD = 6;
const VERTICAL_RESIZE_RATIO = 1 / 3;
const GEOMETRY_PROPERTIES = ['left', 'top', 'right', 'bottom', 'width', 'height', 'maxWidth', 'maxHeight'] as const;
const POLL_MIN = 400;
const POLL_MAX = 1000;
const POLL_BACKOFF = 1.5;
const POLL_HIDDEN = 5000;
const POLL_RETRIES = 5;
const RETRY_MIN = 1000;
const APPLY_TIMEOUT = 300;
const BOTTOM_TOLERANCE = 4;
const MORE_BELOW_CLASS = 'op-ai-result-pane--more-below';

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
  vertical:boolean;
}

// A new run replaces the whole pane element, so the place the user moved it to outlives the controller.
let rememberedGeometry:Geometry|null = null;

const clamp = (value:number, min:number, max:number) => Math.min(Math.max(min, value), max);

export default class AiTextTransformPaneController extends Controller<HTMLElement> {
  static targets = ['pane', 'scroll', 'state', 'error', 'errorMessage', 'notice'];

  static values = {
    closeForm: String,
    editorGone: String,
    selectionGone: String,
    requestFailed: String,
  };


  declare readonly paneTarget:HTMLElement;
  declare readonly scrollTarget:HTMLElement;
  declare readonly hasScrollTarget:boolean;
  declare readonly errorTarget:HTMLElement;
  declare readonly errorMessageTarget:HTMLElement;
  declare readonly hasErrorTarget:boolean;
  declare readonly closeFormValue:string;
  declare readonly editorGoneValue:string;
  declare readonly selectionGoneValue:string;
  declare readonly requestFailedValue:string;

  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:ResizeStart|null = null;
  private pointerListeners:AbortController|null = null;
  private scrollWatch:{ element:HTMLElement; mutations:MutationObserver; resizes:ResizeObserver; listeners:AbortController }|null = null;
  private followsOutput = true;
  private knownScroll = { top: 0, height: 0, viewport: 0 };

  private run = { state: '', seq: '0', requestId: '', pollUrl: '' };
  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private pollInFlight = false;
  private pollDelay = POLL_MIN;
  private pollFailures = 0;
  private applyTimer:ReturnType<typeof setTimeout>|null = null;
  private applyAnswered = false;
  private closing = false;
  private abandoned = false;
  private focusToRestore:{ form:string }|null = null;

  connect():void {
    if (rememberedGeometry) {
      Object.assign(this.paneTarget.style, rememberedGeometry);
      this.keepInViewport();
    }
    this.paneTarget.focus({ preventScroll: true });
  }

  disconnect():void {
    this.endPointerAction();
    this.unwatchScroll();
    this.stopPolling();
    this.clearApplyTimer();
    rememberedGeometry = this.pinned ? this.geometry() : null;
    if (!this.element.isConnected) {
      this.abandon();
    }
  }

  scrollTargetConnected(element:HTMLElement):void {
    this.unwatchScroll();
    const listeners = new AbortController();
    const resizes = new ResizeObserver((entries) => this.scrollAreaResized(entries.some((entry) => entry.target === element)));
    const mutations = new MutationObserver((records) => {
      this.observeContentResizes(resizes, element, records);
      this.outputChanged();
    });
    mutations.observe(element, { childList: true, characterData: true, subtree: true });
    resizes.observe(element);
    Array.from(element.children).forEach((child) => resizes.observe(child));
    element.addEventListener('scroll', () => this.scrolled(), { passive: true, signal: listeners.signal });
    this.scrollWatch = { element, mutations, resizes, listeners };
    this.followsOutput = this.scrolledToEnd;
    this.rememberScrollPosition();
    this.showMoreBelow();
  }

  scrollTargetDisconnected(element:HTMLElement):void {
    if (this.scrollWatch?.element === element) {
      this.unwatchScroll();
    }
  }

  noticeTargetConnected(element:HTMLElement):void {
    if (!this.hasScrollTarget) {
      return;
    }

    this.catchUpWithUnseenScroll();
    if (this.followsOutput) {
      this.reveal(element);
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
    } else if (success) {
      this.setButtonsDisabled(form.id, true);
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
      vertical: false,
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

  private get scrolledToEnd():boolean {
    const { scrollHeight, scrollTop, clientHeight } = this.scrollTarget;
    return scrollHeight - scrollTop - clientHeight <= BOTTOM_TOLERANCE;
  }

  // Scroll events arrive with the next frame, after output or the pane may have changed, so only a move tells what the user did.
  // The user aimed at the layout they saw before that change, and the browser may have clamped the position to the new one.
  private catchUpWithUnseenScroll():void {
    const { scrollTop } = this.scrollTarget;
    const { top, height, viewport } = this.knownScroll;
    const atEnd = this.scrolledToEnd || height - scrollTop - viewport <= BOTTOM_TOLERANCE;
    if (scrollTop < top && !atEnd) {
      this.followsOutput = false;
    } else if (scrollTop > top && atEnd) {
      this.followsOutput = true;
    }
  }

  private rememberScrollPosition():void {
    const { scrollTop, scrollHeight, clientHeight } = this.scrollTarget;
    this.knownScroll = { top: scrollTop, height: scrollHeight, viewport: clientHeight };
  }

  private scrolled():void {
    this.catchUpWithUnseenScroll();
    this.rememberScrollPosition();
    this.showMoreBelow();
  }

  private outputChanged():void {
    this.catchUpWithUnseenScroll();
    if (this.followsOutput) {
      this.scrollTarget.scrollTop = this.scrollTarget.scrollHeight;
    }
    this.rememberScrollPosition();
    this.showMoreBelow();
  }

  private reveal(element:HTMLElement):void {
    this.followsOutput = false;
    element.scrollIntoView({ block: 'nearest' });
  }

  private scrollAreaResized(viewportChanged:boolean):void {
    if (viewportChanged || this.run.state === 'generating') {
      this.outputChanged();
    } else {
      this.scrolled();
    }
    this.followsOutput = this.scrolledToEnd;
  }

  private observeContentResizes(resizes:ResizeObserver, scrollArea:HTMLElement, records:MutationRecord[]):void {
    records
      .filter((record) => record.target === scrollArea)
      .forEach((record) => {
        record.removedNodes.forEach((node) => node instanceof Element && resizes.unobserve(node));
        record.addedNodes.forEach((node) => node instanceof Element && resizes.observe(node));
      });
  }

  private showMoreBelow():void {
    this.scrollTarget.classList.toggle(MORE_BELOW_CLASS, !this.scrolledToEnd);
  }

  private unwatchScroll():void {
    this.scrollWatch?.mutations.disconnect();
    this.scrollWatch?.resizes.disconnect();
    this.scrollWatch?.listeners.abort();
    this.scrollWatch = null;
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

    const response = await fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' })
      .catch(() => null);
    const html = response?.ok ? await response.text().catch(() => null) : null;
    this.pollInFlight = false;

    // A new run replaces this pane under the same element ids, so a late answer must not render into it.
    if (!this.element.isConnected) {
      return;
    }

    if (html === null) {
      this.pollFailed(response);
      return;
    }

    this.pollFailures = 0;
    this.pollDelay = html.trim() === '' ? Math.min(POLL_MAX, this.pollDelay * POLL_BACKOFF) : POLL_MIN;
    renderStreamMessage(html);
    if (this.run.state === 'generating') {
      this.schedulePoll();
    }
  }

  private pollFailed(response:Response|null):void {
    const transient = !response || response.ok || response.status >= 500;
    this.pollFailures += 1;
    if (!transient || this.pollFailures > POLL_RETRIES) {
      this.showError(this.requestFailedValue);
      return;
    }

    this.pollDelay = Math.min(POLL_HIDDEN, RETRY_MIN * 2 ** (this.pollFailures - 1));
    this.schedulePoll();
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
    const dx = event.clientX - x;
    const dy = event.clientY - y;
    const { style } = this.paneTarget;
    style.maxWidth = `calc(100vw - ${2 * EDGE_MARGIN}px)`;

    if (edge.endsWith('left')) {
      const newWidth = clamp(width - dx, MIN_WIDTH, left + width - EDGE_MARGIN);
      this.pin(left + width - newWidth, top);
      style.width = `${newWidth}px`;
    } else {
      style.width = `${clamp(width + dx, MIN_WIDTH, window.innerWidth - left - EDGE_MARGIN)}px`;
    }

    this.resizeStart.vertical ||= Math.abs(dy) > VERTICAL_RESIZE_THRESHOLD
      && Math.abs(dy) > Math.abs(dx) * VERTICAL_RESIZE_RATIO;

    if (this.resizeStart.vertical) {
      style.height = `${clamp(height + dy, MIN_HEIGHT, window.innerHeight - top - EDGE_MARGIN)}px`;
      style.maxHeight = `calc(100vh - ${this.minTop + EDGE_MARGIN}px)`;
    }
  }

  private get minTop():number {
    const header = document.querySelector('.op-app-header');
    return Math.max(0, header?.getBoundingClientRect().bottom ?? 0) + EDGE_MARGIN;
  }

  private pinInViewport(left:number, top:number):void {
    const { width, height } = this.paneTarget.getBoundingClientRect();
    const { minTop } = this;
    const maxLeft = Math.max(EDGE_MARGIN, window.innerWidth - width - EDGE_MARGIN);
    const maxTop = Math.max(minTop, window.innerHeight - height - EDGE_MARGIN);

    this.pin(clamp(left, EDGE_MARGIN, maxLeft), clamp(top, minTop, maxTop));
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
