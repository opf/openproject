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
  AI_TEXT_TRANSFORM_TERMINAL_STATUSES,
  AiTextTransformRun,
  AiTextTransformRunClient,
  AiTextTransformRunEvent,
} from 'core-stimulus/helpers/ai-text-transform-run';

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
 * against the execute API and shows the run as the shared run client polls it.
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

  private client:AiTextTransformRunClient|null = null;
  private runId:string|null = null;
  private tickTimer:ReturnType<typeof setInterval>|null = null;
  private startedAt = 0;
  private finishedAt:number|null = null;
  private text = '';

  disconnect():void {
    this.client?.dispose();
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

    this.client = new AiTextTransformRunClient(this.urlValue, {
      onRun: (run) => this.apply(run),
      onRequestFailed: (status, body) => this.requestFailed(status, body),
    });
    await this.client.start(this.body());
  }

  async cancel():Promise<void> {
    this.cancelTarget.disabled = true;
    await this.client?.cancel();
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

  private requestFailed(status:number, body:string):void {
    this.setStatus('error');
    this.outputTarget.textContent = `HTTP ${status}\n\n${body}`;
    this.finish();
  }

  private apply(run:AiTextTransformRun):void {
    if (this.runId === null) {
      this.runId = run.id;
      this.cancelTarget.disabled = run._links.cancel === undefined;
      this.systemPromptTarget.textContent = run.systemPrompt ?? '';
    }

    this.setStatus(run.status);
    run.events.forEach((event) => {
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

    if (AI_TEXT_TRANSFORM_TERMINAL_STATUSES.includes(run.status)) {
      this.finish();
    }
    this.renderRunMeta(run.status);
  }

  private finish():void {
    this.stopTimer();
    this.finishedAt ??= performance.now();
    this.renderTimer();
    this.cancelTarget.disabled = true;
    this.executeTarget.disabled = false;
    this.spinnerTarget.hidden = true;
  }

  private reset():void {
    this.client?.dispose();
    this.client = null;
    this.stopTimer();
    this.runId = null;
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

  private setStatus(status:string):void {
    this.statusTarget.textContent = status;
    Object.values(LABEL_SCHEMES).forEach((cls) => this.statusTarget.classList.remove(cls));
    this.statusTarget.classList.add(LABEL_SCHEMES[status] ?? 'Label--secondary');
  }

  private renderRunMeta(status:string):void {
    const rows:[string, string][] = [
      ['Run', this.runId ?? ''],
      ['Status', status],
      ['Events', String(this.client?.highestSeq ?? 0)],
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

  private appendEventRow(event:AiTextTransformRunEvent):void {
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
