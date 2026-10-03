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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import {
  AiTextTransformRun,
  AiTextTransformRunClient,
} from 'core-stimulus/helpers/ai-text-transform-run';
import {
  AI_TEXT_TRANSFORM_START_EVENT,
  AiTextTransformStartDetail,
} from 'core-stimulus/controllers/dynamic/ai-text-transform-menu.controller';

type PopoverState = 'generating'|'done'|'stopped'|'failed';

const RENDER_INTERVAL = 1200;
const COPIED_FEEDBACK = 1500;
const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;
// Demo only: ?ai_demo_fault=blocked or =failed in the page URL makes the next runs end that way.
const DEMO_FAULT_PARAM = 'ai_demo_fault';

/**
 * Demo (AI-126): the AI result pane, a wrapper around Primer::Alpha::Overlay. It runs the action
 * chosen in the editor's AI menu, shows the text while it streams in and replaces the editor content
 * on request. Dragging and resizing are feature code on this wrapper; the overlay itself is unchanged.
 */
export default class AiTextTransformResultOverlayController extends Controller<HTMLElement> {
  static targets = [
    'overlay', 'handle', 'grip', 'resize', 'title', 'context', 'output', 'stopped', 'failed', 'failedMessage',
    'generatingFooter', 'doneFooter', 'errorFooter', 'copyLabel',
  ];

  static values = {
    runsUrl: String,
    renderUrl: String,
    editorGone: String,
    selectionGone: String,
    contextDocument: String,
    contextSelection: String,
    copied: String,
    copy: String,
  };

  declare readonly overlayTarget:HTMLElement;
  declare readonly handleTarget:HTMLElement;
  declare readonly gripTarget:HTMLElement;
  declare readonly resizeTargets:HTMLElement[];
  declare readonly titleTarget:HTMLElement;
  declare readonly contextTarget:HTMLElement;
  declare readonly outputTarget:HTMLElement;
  declare readonly stoppedTarget:HTMLElement;
  declare readonly failedTarget:HTMLElement;
  declare readonly failedMessageTarget:HTMLElement;
  declare readonly generatingFooterTarget:HTMLElement;
  declare readonly doneFooterTarget:HTMLElement;
  declare readonly errorFooterTarget:HTMLElement;
  declare readonly copyLabelTarget:HTMLElement;
  declare readonly runsUrlValue:string;
  declare readonly renderUrlValue:string;
  declare readonly editorGoneValue:string;
  declare readonly selectionGoneValue:string;
  declare readonly contextDocumentValue:string;
  declare readonly contextSelectionValue:string;
  declare readonly copiedValue:string;
  declare readonly copyValue:string;

  private client:AiTextTransformRunClient|null = null;
  private request:AiTextTransformStartDetail|null = null;
  private input = '';
  private markdown = '';
  private result:string|null = null;
  private lastRenderAt = 0;
  private renderTimer:ReturnType<typeof setTimeout>|null = null;
  private renderSequence = 0;
  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:{ x:number; y:number; left:number; width:number; height:number; edge:string }|null = null;

  private readonly onStart = (event:Event) => {
    void this.start((event as CustomEvent<AiTextTransformStartDetail>).detail);
  };

  private readonly onPointerDown = (event:PointerEvent) => this.beginDrag(event);
  private readonly onPointerMove = (event:PointerEvent) => this.drag(event);
  private readonly onPointerUp = () => this.endDrag();
  private readonly onResizeDown = (event:PointerEvent) => this.beginResize(event);
  private readonly onResizeMove = (event:PointerEvent) => this.resize(event);
  private readonly onResizeUp = () => this.endResize();
  private readonly onToggle = (event:Event) => this.toggled(event as ToggleEvent);

  connect():void {
    window.addEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    [this.handleTarget, this.gripTarget].forEach((el) => el.addEventListener('pointerdown', this.onPointerDown));
    this.resizeTargets.forEach((el) => el.addEventListener('pointerdown', this.onResizeDown));
    this.overlayTarget.addEventListener('toggle', this.onToggle);
  }

  disconnect():void {
    window.removeEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    [this.handleTarget, this.gripTarget].forEach((el) => el.removeEventListener('pointerdown', this.onPointerDown));
    this.resizeTargets.forEach((el) => el.removeEventListener('pointerdown', this.onResizeDown));
    this.overlayTarget.removeEventListener('toggle', this.onToggle);
    this.endDrag();
    this.endResize();
    this.stopRun();
  }

  async cancel():Promise<void> {
    await this.client?.cancel();
  }

  // Closing while the text is generating cancels the run, afterwards it discards the result.
  // The cleanup runs in toggled(), so the overlay header's own close button takes the same path.
  dismiss():void {
    this.hideOverlay();
  }

  async retry():Promise<void> {
    if (this.request) {
      await this.run();
    }
  }

  replace():void {
    const wrapper = this.request?.editorWrapper;
    if (this.result === null || !wrapper?.isConnected) {
      this.showFailure(this.editorGoneValue, true);
      return;
    }

    if (this.request?.scope === 'selection') {
      let replaced = false;
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:replaceSelection', {
        detail: { markdown: this.result, done: (ok:boolean) => { replaced = ok; } },
      }));
      if (!replaced) {
        this.showFailure(this.selectionGoneValue, true);
        return;
      }
    } else {
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:replaceDocument', { detail: this.result }));
    }
    this.hideOverlay();
  }

  async copy():Promise<void> {
    if (this.result === null) {
      return;
    }

    await navigator.clipboard.writeText(this.result);
    this.copyLabelTarget.textContent = this.copiedValue;
    setTimeout(() => { this.copyLabelTarget.textContent = this.copyValue; }, COPIED_FEEDBACK);
  }

  private async start(detail:AiTextTransformStartDetail):Promise<void> {
    if (this.client?.running) {
      await this.client.cancel();
    }

    this.request = detail;
    this.input = detail.input;
    this.titleTarget.textContent = detail.label;
    this.contextTarget.textContent = detail.scope === 'selection' ? this.contextSelectionValue : this.contextDocumentValue;
    this.showOverlay();
    await this.run();
  }

  private async run():Promise<void> {
    if (!this.request) {
      return;
    }

    this.stopRun();
    this.markdown = '';
    this.result = null;
    this.outputTarget.innerHTML = '';
    this.show('generating');

    this.client = new AiTextTransformRunClient(this.runsUrlValue, {
      onRun: (run) => this.apply(run),
      onRequestFailed: (status, body) => this.showFailure(this.requestFailureMessage(status, body)),
    });
    await this.client.start(this.body());
  }

  private body():Record<string, unknown> {
    const { workPackageId, projectId, typeId } = this.contextIds();
    const body:Record<string, unknown> = { actionId: this.request?.actionId, content: this.input };

    if (workPackageId) {
      body.workPackageId = workPackageId;
    } else if (projectId && typeId) {
      body.projectId = projectId;
      body.typeId = typeId;
    }
    const demoFault = new URLSearchParams(window.location.search).get(DEMO_FAULT_PARAM);
    if (demoFault) {
      body.demoFault = demoFault;
    }
    return body;
  }

  private contextIds() {
    const context = this.request?.context ?? {};
    return { workPackageId: context.work_package_id, projectId: context.project_id, typeId: context.type_id };
  }

  private apply(run:AiTextTransformRun):void {
    run.events.forEach((event) => {
      switch (event.kind) {
        case 'text_delta':
          this.markdown += event.payload.delta ?? '';
          this.scheduleRender();
          break;
        case 'completed':
          this.result = event.payload.text ?? '';
          this.markdown = this.result;
          void this.renderNow();
          this.show('done');
          break;
        case 'error':
          this.discardPartialText();
          if (event.payload.reason === 'blocked') {
            this.show('stopped');
          } else {
            this.showFailure(event.payload.message ?? '');
          }
          break;
        default:
          break;
      }
    });

    if (run.status === 'cancelled') {
      this.hideOverlay();
    }
  }

  private get overlayOpen():boolean {
    return this.overlayTarget.matches(':popover-open');
  }

  private showOverlay():void {
    if (!this.overlayOpen) {
      this.overlayTarget.showPopover();
    }
  }

  private hideOverlay():void {
    if (this.overlayOpen) {
      this.overlayTarget.hidePopover();
    }
  }

  private toggled(event:ToggleEvent):void {
    if (event.newState !== 'closed') {
      return;
    }

    if (this.client?.running) {
      void this.client.cancel();
    }
    this.stopRun();
    this.clearSelectionMarker();
  }

  private show(state:PopoverState):void {
    this.generatingFooterTarget.hidden = state !== 'generating';
    this.doneFooterTarget.hidden = state !== 'done';
    this.errorFooterTarget.hidden = state !== 'stopped' && state !== 'failed';
    this.stoppedTarget.hidden = state !== 'stopped';
    this.failedTarget.hidden = state !== 'failed';
  }

  private showFailure(message:string, keepResult = false):void {
    if (!keepResult) {
      this.discardPartialText();
    }
    this.failedMessageTarget.textContent = message;
    this.show('failed');
    if (keepResult) {
      this.doneFooterTarget.hidden = false;
      this.errorFooterTarget.hidden = true;
    }
  }

  private discardPartialText():void {
    this.clearRenderTimer();
    this.renderSequence += 1;
    this.markdown = '';
    this.outputTarget.innerHTML = '';
  }

  private requestFailureMessage(status:number, body:string):string {
    try {
      const error = JSON.parse(body) as { message?:string };
      return error.message ?? `HTTP ${status}`;
    } catch {
      return `HTTP ${status}`;
    }
  }

  private stopRun():void {
    this.client?.dispose();
    this.client = null;
    this.clearRenderTimer();
  }

  private clearSelectionMarker():void {
    const wrapper = this.request?.editorWrapper;
    if (wrapper?.isConnected) {
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:clearSelectionMarker'));
    }
  }

  // The deltas are markdown, the popover shows formatted text: a demo endpoint renders it, at
  // most once per interval while the text streams in.
  private scheduleRender():void {
    if (this.renderTimer !== null) {
      return;
    }

    const wait = Math.max(0, RENDER_INTERVAL - (performance.now() - this.lastRenderAt));
    this.renderTimer = setTimeout(() => {
      this.renderTimer = null;
      void this.renderNow();
    }, wait);
  }

  private async renderNow():Promise<void> {
    this.clearRenderTimer();
    this.lastRenderAt = performance.now();
    this.renderSequence += 1;
    const sequence = this.renderSequence;

    const response = await fetch(this.renderUrlValue, {
      method: 'POST',
      body: JSON.stringify({ markdown: this.markdown, work_package_id: this.contextIds().workPackageId }),
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '',
      },
    });
    if (!response.ok || sequence !== this.renderSequence) {
      return;
    }

    // Sanitized by the server's text formatting pipeline.
    this.outputTarget.innerHTML = await response.text();
  }

  private clearRenderTimer():void {
    if (this.renderTimer !== null) {
      clearTimeout(this.renderTimer);
      this.renderTimer = null;
    }
  }

  private beginDrag(event:PointerEvent):void {
    if ((event.target as HTMLElement).closest('button')) {
      return;
    }

    const rect = this.overlayTarget.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    window.addEventListener('pointermove', this.onPointerMove);
    window.addEventListener('pointerup', this.onPointerUp);
    event.preventDefault();
  }

  private drag(event:PointerEvent):void {
    if (!this.dragOffset) {
      return;
    }

    const rect = this.overlayTarget.getBoundingClientRect();
    const maxLeft = window.innerWidth - rect.width - EDGE_MARGIN;
    const maxTop = window.innerHeight - EDGE_MARGIN * 6;
    const left = Math.min(Math.max(EDGE_MARGIN, event.clientX - this.dragOffset.x), Math.max(EDGE_MARGIN, maxLeft));
    const top = Math.min(Math.max(EDGE_MARGIN, event.clientY - this.dragOffset.y), maxTop);

    this.pin(left, top);
  }

  // anchored-position re-anchors on every window or document resize by assigning inline
  // top/left, which also drops an inline !important. The pinned class carries the position
  // through stylesheet rules that outrank it.
  private pin(left:number, top:number):void {
    const { style, classList } = this.overlayTarget;
    style.setProperty('--op-ai-result-left', `${left}px`);
    style.setProperty('--op-ai-result-top', `${top}px`);
    classList.add('op-ai-result-overlay_pinned');
  }

  private endDrag():void {
    this.dragOffset = null;
    window.removeEventListener('pointermove', this.onPointerMove);
    window.removeEventListener('pointerup', this.onPointerUp);
  }

  // Resizing pins the popover to explicit coordinates first, so a right or bottom handle
  // grows it in place and a left handle moves the left edge only.
  private beginResize(event:PointerEvent):void {
    const rect = this.overlayTarget.getBoundingClientRect();
    const edge = (event.currentTarget as HTMLElement).dataset.edge ?? 'bottom-right';
    this.resizeStart = { x: event.clientX, y: event.clientY, left: rect.left, width: rect.width, height: rect.height, edge };
    this.pin(rect.left, rect.top);
    window.addEventListener('pointermove', this.onResizeMove);
    window.addEventListener('pointerup', this.onResizeUp);
    event.preventDefault();
  }

  private resize(event:PointerEvent):void {
    if (!this.resizeStart) {
      return;
    }

    const { edge, left, width, height, x, y } = this.resizeStart;
    const rect = this.overlayTarget.getBoundingClientRect();
    const dx = event.clientX - x;
    const dy = event.clientY - y;
    const fromLeft = edge.endsWith('left');
    const vertical = edge.startsWith('bottom');

    if (fromLeft) {
      const maxWidth = left + width - EDGE_MARGIN;
      const newWidth = Math.min(Math.max(MIN_WIDTH, width - dx), maxWidth);
      this.pin(left + width - newWidth, rect.top);
      this.overlayTarget.style.width = `${newWidth}px`;
    } else {
      const maxWidth = window.innerWidth - left - EDGE_MARGIN;
      this.overlayTarget.style.width = `${Math.min(Math.max(MIN_WIDTH, width + dx), maxWidth)}px`;
    }

    if (vertical) {
      const maxHeight = window.innerHeight - rect.top - EDGE_MARGIN;
      this.overlayTarget.style.height = `${Math.min(Math.max(MIN_HEIGHT, height + dy), maxHeight)}px`;
    }
  }

  private endResize():void {
    this.resizeStart = null;
    window.removeEventListener('pointermove', this.onResizeMove);
    window.removeEventListener('pointerup', this.onResizeUp);
  }
}
