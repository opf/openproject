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
type DemoFault = 'blocked'|'failed'|null;

const RENDER_INTERVAL = 1200;
const COPIED_FEEDBACK = 1500;
const EDGE_MARGIN = 8;

/**
 * Demo (AI-126): the AI result popover. It runs the action chosen in the editor's AI menu
 * on the whole description, shows the text while it streams in and replaces the editor
 * content on request. The popover can be dragged by its header or the grip.
 */
export default class AiTextTransformPopoverController extends Controller<HTMLElement> {
  static targets = [
    'handle', 'grip', 'title', 'output', 'stopped', 'failed', 'failedMessage',
    'generatingFooter', 'doneFooter', 'errorFooter', 'copyLabel', 'faultState',
  ];

  static values = {
    runsUrl: String,
    renderUrl: String,
    workPackageLink: String,
    editorGone: String,
    copied: String,
    copy: String,
  };

  declare readonly handleTarget:HTMLElement;
  declare readonly gripTarget:HTMLElement;
  declare readonly titleTarget:HTMLElement;
  declare readonly outputTarget:HTMLElement;
  declare readonly stoppedTarget:HTMLElement;
  declare readonly failedTarget:HTMLElement;
  declare readonly failedMessageTarget:HTMLElement;
  declare readonly generatingFooterTarget:HTMLElement;
  declare readonly doneFooterTarget:HTMLElement;
  declare readonly errorFooterTarget:HTMLElement;
  declare readonly copyLabelTarget:HTMLElement;
  declare readonly faultStateTarget:HTMLElement;
  declare readonly runsUrlValue:string;
  declare readonly renderUrlValue:string;
  declare readonly workPackageLinkValue:string;
  declare readonly editorGoneValue:string;
  declare readonly copiedValue:string;
  declare readonly copyValue:string;

  private client:AiTextTransformRunClient|null = null;
  private request:AiTextTransformStartDetail|null = null;
  private input = '';
  private markdown = '';
  private result:string|null = null;
  private demoFault:DemoFault = null;
  private lastRenderAt = 0;
  private renderTimer:ReturnType<typeof setTimeout>|null = null;
  private renderSequence = 0;
  private dragOffset:{ x:number; y:number }|null = null;

  private readonly onStart = (event:Event) => {
    void this.start((event as CustomEvent<AiTextTransformStartDetail>).detail);
  };

  private readonly onPointerDown = (event:PointerEvent) => this.beginDrag(event);
  private readonly onPointerMove = (event:PointerEvent) => this.drag(event);
  private readonly onPointerUp = () => this.endDrag();

  connect():void {
    window.addEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    [this.handleTarget, this.gripTarget].forEach((el) => el.addEventListener('pointerdown', this.onPointerDown));
  }

  disconnect():void {
    window.removeEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    [this.handleTarget, this.gripTarget].forEach((el) => el.removeEventListener('pointerdown', this.onPointerDown));
    this.endDrag();
    this.stopRun();
  }

  async cancel():Promise<void> {
    await this.client?.cancel();
  }

  // Closing while the text is generating cancels the run, afterwards it discards the result.
  async dismiss():Promise<void> {
    if (this.client?.running) {
      await this.client.cancel();
    }
    this.stopRun();
    this.element.hidden = true;
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

    wrapper.dispatchEvent(new CustomEvent('op:ckeditor:setData', { detail: this.result }));
    this.element.hidden = true;
  }

  async copy():Promise<void> {
    if (this.result === null) {
      return;
    }

    await navigator.clipboard.writeText(this.result);
    this.copyLabelTarget.textContent = this.copiedValue;
    setTimeout(() => { this.copyLabelTarget.textContent = this.copyValue; }, COPIED_FEEDBACK);
  }

  forceError():void {
    this.setDemoFault('failed');
  }

  forceGuardrail():void {
    this.setDemoFault('blocked');
  }

  resetFault():void {
    this.setDemoFault(null);
  }

  private async start(detail:AiTextTransformStartDetail):Promise<void> {
    if (this.client?.running) {
      await this.client.cancel();
    }

    this.request = detail;
    this.input = await this.readEditor(detail.editorWrapper);
    this.titleTarget.textContent = detail.label;
    this.element.hidden = false;
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
    if (this.demoFault) {
      body.demoFault = this.demoFault;
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
      this.stopRun();
      this.element.hidden = true;
    }
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

  private readEditor(wrapper:HTMLElement):Promise<string> {
    return new Promise((resolve) => {
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:getData', { detail: (data:string) => resolve(data) }));
    });
  }

  // The deltas are markdown, the popover shows formatted text: the server renders it, at most
  // once per interval while the text streams in.
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

    const response = await fetch(this.renderUrl(), {
      method: 'POST',
      body: this.markdown,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'text/plain; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
    });
    if (!response.ok || sequence !== this.renderSequence) {
      return;
    }

    // Sanitized by the server's text formatting pipeline.
    this.outputTarget.innerHTML = await response.text();
  }

  private renderUrl():string {
    const { workPackageId } = this.contextIds();
    if (!workPackageId) {
      return this.renderUrlValue;
    }

    const link = this.workPackageLinkValue.replace('__id__', String(workPackageId));
    return `${this.renderUrlValue}?context=${encodeURIComponent(link)}`;
  }

  private clearRenderTimer():void {
    if (this.renderTimer !== null) {
      clearTimeout(this.renderTimer);
      this.renderTimer = null;
    }
  }

  private setDemoFault(fault:DemoFault):void {
    this.demoFault = fault;
    this.faultStateTarget.textContent = fault === null ? '' : `next run: ${fault}`;
  }

  private beginDrag(event:PointerEvent):void {
    if ((event.target as HTMLElement).closest('button')) {
      return;
    }

    const rect = this.element.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    window.addEventListener('pointermove', this.onPointerMove);
    window.addEventListener('pointerup', this.onPointerUp);
    event.preventDefault();
  }

  private drag(event:PointerEvent):void {
    if (!this.dragOffset) {
      return;
    }

    const rect = this.element.getBoundingClientRect();
    const maxLeft = window.innerWidth - rect.width - EDGE_MARGIN;
    const maxTop = window.innerHeight - EDGE_MARGIN * 6;
    const left = Math.min(Math.max(EDGE_MARGIN, event.clientX - this.dragOffset.x), Math.max(EDGE_MARGIN, maxLeft));
    const top = Math.min(Math.max(EDGE_MARGIN, event.clientY - this.dragOffset.y), maxTop);

    this.element.style.setProperty('left', `${left}px`, 'important');
    this.element.style.setProperty('right', 'auto', 'important');
    this.element.style.setProperty('top', `${top}px`);
  }

  private endDrag():void {
    this.dragOffset = null;
    window.removeEventListener('pointermove', this.onPointerMove);
    window.removeEventListener('pointerup', this.onPointerUp);
  }
}
