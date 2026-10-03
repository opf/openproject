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

export interface AiTextTransformRunEvent {
  seq:number;
  kind:'status'|'text_delta'|'completed'|'error';
  payload:{ status?:string; delta?:string; text?:string; message?:string; reason?:string };
}

export interface AiTextTransformRun {
  id:string;
  status:string;
  systemPrompt?:string;
  events:AiTextTransformRunEvent[];
  _links:{ self:{ href:string }; cancel?:{ href:string } };
}

export interface AiTextTransformRunCallbacks {
  // Called for the create response and for every poll that was not superseded.
  onRun:(run:AiTextTransformRun) => void;
  // Called when creating or polling fails on the HTTP level. The client stops afterwards.
  onRequestFailed:(status:number, body:string) => void;
}

export const AI_TEXT_TRANSFORM_TERMINAL_STATUSES = ['succeeded', 'failed', 'cancelled'];

const MIN_DELAY = 400;
const MAX_DELAY = 1000;
const DELAY_STEP = 150;

/**
 * Client for one AI text transform run (API v3, AI-136): creates the run and polls its
 * event log with a cursor. Polling backs off from 400 ms to 1 s, keeps one request in
 * flight, ignores responses for an outdated cursor, pauses while the tab is hidden and
 * never resumes after a terminal status.
 */
export class AiTextTransformRunClient {
  private runUrl:string|null = null;
  private cancelUrl:string|null = null;
  private cursor = 0;
  private delay = MIN_DELAY;
  private pollTimer:ReturnType<typeof setTimeout>|null = null;
  private inFlight = false;
  private finished = false;
  private readonly onVisibilityChange = () => { this.handleVisibilityChange(); };

  constructor(
    private readonly createUrl:string,
    private readonly callbacks:AiTextTransformRunCallbacks,
  ) {
    document.addEventListener('visibilitychange', this.onVisibilityChange);
  }

  get running():boolean {
    return this.runUrl !== null && !this.finished;
  }

  get highestSeq():number {
    return this.cursor;
  }

  async start(body:Record<string, unknown>):Promise<void> {
    const response = await this.request(this.createUrl, 'POST', JSON.stringify(body));
    if (!response.ok) {
      this.finished = true;
      this.callbacks.onRequestFailed(response.status, await response.text());
      return;
    }

    const run = await response.json() as AiTextTransformRun;
    this.runUrl = run._links.self.href;
    this.cancelUrl = run._links.cancel?.href ?? null;
    this.apply(run);
  }

  async cancel():Promise<void> {
    if (this.cancelUrl && !this.finished) {
      await this.request(this.cancelUrl, 'POST');
    }
  }

  dispose():void {
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    this.finished = true;
    this.clearTimer();
  }

  private apply(run:AiTextTransformRun):void {
    run.events.forEach((event) => { this.cursor = Math.max(this.cursor, event.seq); });
    if (AI_TEXT_TRANSFORM_TERMINAL_STATUSES.includes(run.status)) {
      this.finished = true;
      this.clearTimer();
    }

    this.callbacks.onRun(run);

    if (!this.finished) {
      this.schedule();
    }
  }

  private schedule():void {
    this.clearTimer();
    this.pollTimer = setTimeout(() => { void this.poll(); }, this.delay);
    this.delay = Math.min(MAX_DELAY, this.delay + DELAY_STEP);
  }

  private async poll():Promise<void> {
    this.pollTimer = null;
    if (!this.runUrl || this.inFlight || this.finished) {
      return;
    }
    if (document.hidden) {
      return;
    }

    this.inFlight = true;
    const requestedCursor = this.cursor;
    try {
      const response = await this.request(`${this.runUrl}?after=${requestedCursor}`, 'GET');
      if (this.finished) {
        return;
      }
      if (!response.ok) {
        this.finished = true;
        this.callbacks.onRequestFailed(response.status, await response.text());
        return;
      }
      if (requestedCursor !== this.cursor) {
        return;
      }
      this.apply(await response.json() as AiTextTransformRun);
    } finally {
      this.inFlight = false;
    }
  }

  private handleVisibilityChange():void {
    if (!document.hidden && this.running && this.pollTimer === null && !this.inFlight) {
      this.schedule();
    }
  }

  private clearTimer():void {
    if (this.pollTimer !== null) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
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
}
