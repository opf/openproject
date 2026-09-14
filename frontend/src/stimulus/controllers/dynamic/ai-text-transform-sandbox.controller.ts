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
const TIMER_TICK = 100;
const LABEL_SCHEMES:Record<string, string> = {
  idle: 'Label--secondary',
  creating: 'Label--secondary',
  queued: 'Label--secondary',
  running: 'Label--accent',
  succeeded: 'Label--success',
  failed: 'Label--danger',
  cancelled: 'Label--attention',
  error: 'Label--danger',
};

/**
 * Prototype sandbox for the description assistant: posts the textarea content
 * against the execute API and polls the run with an adaptive cursor-based loop.
 */
export default class AiTextTransformSandboxController extends Controller<HTMLElement> {
  static targets = [
    'content', 'contextMode', 'typeId',
    'execute', 'cancel', 'spinner', 'status', 'timer', 'output',
    'runMeta', 'systemPrompt', 'eventsBody',
  ];

  static values = { url: String, actionId: Number };

  declare readonly contentTarget:HTMLTextAreaElement;
  declare readonly contextModeTarget:HTMLSelectElement;
  declare readonly typeIdTarget:HTMLSelectElement;
  declare readonly executeTarget:HTMLButtonElement;
  declare readonly cancelTarget:HTMLButtonElement;
  declare readonly spinnerTarget:HTMLElement;
  declare readonly statusTarget:HTMLElement;
  declare readonly timerTarget:HTMLElement;
  declare readonly outputTarget:HTMLElement;
  declare readonly runMetaTarget:HTMLElement;
  declare readonly systemPromptTarget:HTMLElement;
  declare readonly eventsBodyTarget:HTMLElement;
  declare readonly urlValue:string;
  declare readonly actionIdValue:number;

  private runId:string|null = null;
  private runUrl:string|null = null;
  private cancelUrl:string|null = null;
  private cursor = 0;
  private delay = MIN_DELAY;
  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private tickTimer:ReturnType<typeof setInterval>|null = null;
  private startedAt = 0;
  private finishedAt:number|null = null;
  private inFlight = false;
  private text = '';
  private readonly onVisibilityChange = () => { this.handleVisibilityChange(); };

  connect():void {
    document.addEventListener('visibilitychange', this.onVisibilityChange);
  }

  disconnect():void {
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    this.stopPolling();
    this.stopTimer();
  }

  submit(event:Event):void {
    event.preventDefault();
    void this.execute();
  }

  async execute():Promise<void> {
    this.reset();
    this.setStatus('creating');
    this.startTimer();

    const response = await this.request(this.urlValue, 'POST', JSON.stringify(this.body()));
    if (!response.ok) {
      this.stopTimer();
      this.setStatus('error');
      this.outputTarget.textContent = `HTTP ${response.status}\n\n${await response.text()}`;
      this.executeTarget.disabled = false;
      this.spinnerTarget.hidden = true;
      return;
    }

    const run = await response.json() as RunResponse;
    this.runId = run.id;
    this.runUrl = run._links.self.href;
    this.cancelUrl = run._links.cancel?.href ?? null;
    this.cancelTarget.disabled = this.cancelUrl === null;
    this.systemPromptTarget.textContent = run.systemPrompt ?? '';
    this.apply(run);
    this.schedule();
  }

  async cancel():Promise<void> {
    if (!this.cancelUrl) {
      return;
    }
    this.cancelTarget.disabled = true;
    await this.request(this.cancelUrl, 'POST');
  }

  private body() {
    const body:Record<string, unknown> = {
      actionId: this.actionIdValue,
      content: this.contentTarget.value,
    };

    switch (this.contextModeTarget.value) {
      case 'work_package':
        if (this.hiddenValue('work_package_id')) {
          body.workPackageId = Number(this.hiddenValue('work_package_id'));
        }
        break;
      case 'new_work_package':
        if (this.hiddenValue('project_id') || this.typeIdTarget.value) {
          body.projectId = Number(this.hiddenValue('project_id'));
          body.typeId = Number(this.typeIdTarget.value);
        }
        break;
      default:
        break;
    }
    return body;
  }

  private hiddenValue(name:string):string {
    const input = this.element.querySelector<HTMLInputElement>(`input[type="hidden"][name="${name}"]`);
    return input?.value ?? '';
  }

  private schedule():void {
    this.stopPolling();
    this.pollTimer = setTimeout(() => { void this.poll(); }, this.delay);
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
        this.setStatus('error');
        this.outputTarget.textContent = `Poll failed: HTTP ${response.status}`;
        this.finish();
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
      this.appendEventRow(event);
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
      this.finish();
    }
    this.renderRunMeta(run.status);
  }

  private finish():void {
    this.stopPolling();
    this.stopTimer();
    this.finishedAt = performance.now();
    this.renderTimer();
    this.cancelTarget.disabled = true;
    this.executeTarget.disabled = false;
    this.spinnerTarget.hidden = true;
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
    this.stopTimer();
    this.runId = null;
    this.runUrl = null;
    this.cancelUrl = null;
    this.cursor = 0;
    this.delay = MIN_DELAY;
    this.text = '';
    this.finishedAt = null;
    this.outputTarget.textContent = '';
    this.systemPromptTarget.textContent = '';
    this.runMetaTarget.textContent = '';
    this.eventsBodyTarget.textContent = '';
    this.timerTarget.textContent = '';
    this.executeTarget.disabled = true;
    this.cancelTarget.disabled = true;
    this.spinnerTarget.hidden = false;
  }

  private startTimer():void {
    this.startedAt = performance.now();
    this.tickTimer = setInterval(() => this.renderTimer(), TIMER_TICK);
    this.renderTimer();
  }

  private stopTimer():void {
    if (this.tickTimer !== null) {
      clearInterval(this.tickTimer);
      this.tickTimer = null;
    }
  }

  private renderTimer():void {
    const end = this.finishedAt ?? performance.now();
    const seconds = ((end - this.startedAt) / 1000).toFixed(1);
    this.timerTarget.textContent = this.finishedAt === null ? `${seconds} s` : `${seconds} s total`;
  }

  private stopPolling():void {
    if (this.pollTimer !== null) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }
  }

  private handleVisibilityChange():void {
    if (!document.hidden && this.runUrl && this.pollTimer === null && !this.inFlight) {
      this.schedule();
    }
  }

  private setStatus(status:string):void {
    this.statusTarget.textContent = status;
    Object.values(LABEL_SCHEMES).forEach((cls) => this.statusTarget.classList.remove(cls));
    this.statusTarget.classList.add(LABEL_SCHEMES[status] ?? 'Label--secondary');
  }

  private renderRunMeta(status:string):void {
    const rows:[string, string][] = [
      ['Run', this.runId ?? ''],
      ['Status', status],
      ['Events', String(this.cursor)],
      ['Elapsed', this.timerTarget.textContent ?? ''],
    ];
    this.runMetaTarget.textContent = '';
    rows.forEach(([term, value]) => {
      const dt = document.createElement('dt');
      dt.textContent = term;
      dt.className = 'text-bold';
      const dd = document.createElement('dd');
      dd.textContent = value;
      dd.className = 'mb-2';
      this.runMetaTarget.append(dt, dd);
    });
  }

  private appendEventRow(event:RunEvent):void {
    const row = document.createElement('tr');
    const cells = [
      String(event.seq),
      event.kind,
      JSON.stringify(event.payload),
      new Date().toISOString().slice(11, 23),
    ];
    cells.forEach((value, index) => {
      const cell = document.createElement('td');
      cell.textContent = value;
      cell.className = index === 2 ? 'p-2 border-bottom wb-break-all' : 'p-2 border-bottom no-wrap';
      row.append(cell);
    });
    this.eventsBodyTarget.append(row);
  }
}
