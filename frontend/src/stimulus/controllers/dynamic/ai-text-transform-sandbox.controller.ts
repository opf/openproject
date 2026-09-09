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

interface RunEvent {
  seq:number;
  kind:'status'|'text_delta'|'completed'|'error';
  payload:{ status?:string; delta?:string; text?:string; message?:string; reason?:string };
}

interface RunResponse {
  id:string;
  status:string;
  systemPrompt?:string;
  events:RunEvent[];
  _links:{ self:{ href:string }; cancel?:{ href:string } };
}

const TERMINAL_STATUSES = ['succeeded', 'failed', 'cancelled'];
const MIN_DELAY = 400;
const MAX_DELAY = 1000;
const DELAY_STEP = 150;

/**
 * Prototype sandbox for the description assistant: posts the textarea content
 * against the execute API and polls the run with an adaptive cursor-based loop.
 */
export default class AiTextTransformSandboxController extends Controller<HTMLElement> {
  static targets = [
    'content', 'workPackageId', 'projectId', 'typeId', 'execute', 'cancel', 'status', 'output', 'log', 'systemPrompt',
  ];

  static values = { url: String, actionId: Number };

  declare readonly contentTarget:HTMLTextAreaElement;
  declare readonly workPackageIdTarget:HTMLInputElement;
  declare readonly projectIdTarget:HTMLInputElement;
  declare readonly typeIdTarget:HTMLInputElement;
  declare readonly executeTarget:HTMLButtonElement;
  declare readonly cancelTarget:HTMLButtonElement;
  declare readonly statusTarget:HTMLElement;
  declare readonly outputTarget:HTMLElement;
  declare readonly logTarget:HTMLElement;
  declare readonly systemPromptTarget:HTMLElement;
  declare readonly urlValue:string;
  declare readonly actionIdValue:number;

  private runUrl:string|null = null;
  private cancelUrl:string|null = null;
  private cursor = 0;
  private delay = MIN_DELAY;
  private timer:ReturnType<typeof setTimeout>|null = null;
  private inFlight = false;
  private text = '';
  private readonly onVisibilityChange = () => { this.handleVisibilityChange(); };

  connect():void {
    document.addEventListener('visibilitychange', this.onVisibilityChange);
  }

  disconnect():void {
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    this.stopPolling();
  }

  async execute():Promise<void> {
    this.reset();
    this.setStatus('creating run');

    const response = await this.request(this.urlValue, 'POST', JSON.stringify(this.body()));
    if (!response.ok) {
      this.setStatus(`create failed: HTTP ${response.status}`);
      this.appendLog(await response.text());
      this.executeTarget.disabled = false;
      return;
    }

    const run = await response.json() as RunResponse;
    this.runUrl = run._links.self.href;
    this.cancelUrl = run._links.cancel?.href ?? null;
    this.cancelTarget.disabled = this.cancelUrl === null;
    this.appendLog(`created ${run.id}`);
    this.systemPromptTarget.textContent = run.systemPrompt ?? '';
    this.apply(run);
    this.schedule();
  }

  async cancel():Promise<void> {
    if (!this.cancelUrl) {
      return;
    }
    this.appendLog('cancel requested');
    const response = await this.request(this.cancelUrl, 'POST');
    this.appendLog(`cancel -> HTTP ${response.status}`);
  }

  private body() {
    const body:Record<string, unknown> = {
      actionId: this.actionIdValue,
      content: this.contentTarget.value,
    };
    const workPackageId = this.workPackageIdTarget.value.trim();
    const projectId = this.projectIdTarget.value.trim();
    const typeId = this.typeIdTarget.value.trim();

    if (workPackageId) {
      body.workPackageId = Number(workPackageId);
    } else if (projectId || typeId) {
      body.projectId = Number(projectId);
      body.typeId = Number(typeId);
    }
    return body;
  }

  private schedule():void {
    this.stopPolling();
    this.timer = setTimeout(() => { void this.poll(); }, this.delay);
    this.delay = Math.min(MAX_DELAY, this.delay + DELAY_STEP);
  }

  private async poll():Promise<void> {
    if (!this.runUrl || this.inFlight) {
      return;
    }
    if (document.hidden) {
      this.schedule();
      return;
    }

    this.inFlight = true;
    const requestedCursor = this.cursor;
    try {
      const response = await this.request(`${this.runUrl}?after=${requestedCursor}`, 'GET');
      if (!response.ok) {
        this.setStatus(`poll failed: HTTP ${response.status}`);
        return;
      }
      if (requestedCursor !== this.cursor) {
        return;
      }
      const run = await response.json() as RunResponse;
      this.apply(run);
      if (!TERMINAL_STATUSES.includes(run.status)) {
        this.schedule();
      }
    } finally {
      this.inFlight = false;
    }
  }

  private apply(run:RunResponse):void {
    this.setStatus(run.status);
    run.events.forEach((event) => {
      this.cursor = Math.max(this.cursor, event.seq);
      this.appendLog(`#${event.seq} ${event.kind} ${JSON.stringify(event.payload)}`);
      switch (event.kind) {
        case 'text_delta':
          this.text += event.payload.delta ?? '';
          this.outputTarget.textContent = this.text;
          break;
        case 'completed':
          this.text = event.payload.text ?? '';
          this.outputTarget.textContent = this.text;
          break;
        case 'error':
          this.outputTarget.textContent = `${this.text}\n\n[${event.payload.reason ?? 'error'}] ${event.payload.message ?? ''}`;
          break;
        default:
          break;
      }
    });

    if (TERMINAL_STATUSES.includes(run.status)) {
      this.stopPolling();
      this.cancelTarget.disabled = true;
      this.executeTarget.disabled = false;
      this.appendLog(`finished with ${run.status}`);
    }
  }

  private request(url:string, method:'GET'|'POST', body?:string):Promise<Response> {
    return fetch(url, {
      method,
      body,
      credentials: 'same-origin',
      headers: {
        Accept: 'application/hal+json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    });
  }

  private reset():void {
    this.stopPolling();
    this.runUrl = null;
    this.cancelUrl = null;
    this.cursor = 0;
    this.delay = MIN_DELAY;
    this.text = '';
    this.outputTarget.textContent = '';
    this.logTarget.textContent = '';
    this.systemPromptTarget.textContent = '';
    this.executeTarget.disabled = true;
    this.cancelTarget.disabled = true;
  }

  private stopPolling():void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  private handleVisibilityChange():void {
    if (!document.hidden && this.runUrl && this.timer === null && !this.inFlight) {
      this.schedule();
    }
  }

  private setStatus(status:string):void {
    this.statusTarget.textContent = status;
  }

  private appendLog(line:string):void {
    this.logTarget.textContent += `${new Date().toISOString().slice(11, 23)} ${line}\n`;
  }
}
