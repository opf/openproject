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
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import {
  AI_TEXT_TRANSFORM_START_EVENT,
  AiTextTransformStartDetail,
} from 'core-stimulus/controllers/dynamic/ai-text-transform-menu.controller';

export const AI_TEXT_TRANSFORM_RETRY_EVENT = 'op:ai-text-transform:retry';

// Demo only: ?ai_demo_fault=blocked or =failed in the page URL makes the next runs end that way.
const DEMO_FAULT_PARAM = 'ai_demo_fault';

/**
 * Demo (AI-126): turns the editor's start event into a Turbo request. The server answers with the
 * rendered result pane, or with updated pane sections when one is already open.
 */
export default class AiTextTransformPaneLauncherController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['turboRequests'];

  static values = { url: String };

  declare readonly urlValue:string;
  declare services:Promise<PickedServices<'turboRequests'>>;
  declare turboRequests:TurboRequestsService;

  private lastRequest:AiTextTransformStartDetail|null = null;

  private readonly onStart = (event:Event) => {
    void this.start((event as CustomEvent<AiTextTransformStartDetail>).detail);
  };

  private readonly onRetry = () => {
    if (this.lastRequest) {
      void this.start(this.lastRequest);
    }
  };

  initialize():void {
    useAngularServices(this);
  }

  connect():void {
    window.addEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    window.addEventListener(AI_TEXT_TRANSFORM_RETRY_EVENT, this.onRetry);
  }

  disconnect():void {
    window.removeEventListener(AI_TEXT_TRANSFORM_START_EVENT, this.onStart);
    window.removeEventListener(AI_TEXT_TRANSFORM_RETRY_EVENT, this.onRetry);
  }

  private async start(detail:AiTextTransformStartDetail):Promise<void> {
    this.lastRequest = detail;
    const { turboRequests } = await this.services;
    await turboRequests.request(this.urlValue, {
      method: 'POST',
      body: this.body(detail),
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin',
    });
  }

  private body(detail:AiTextTransformStartDetail):FormData {
    const body = new FormData();
    body.set('request_id', detail.requestId);
    body.set('action_id', String(detail.actionId));
    body.set('scope', detail.scope);
    body.set('input', detail.input);
    Object.entries(detail.context).forEach(([key, id]) => body.set(key, String(id)));

    const openPane = this.element.querySelector<HTMLElement>('[data-ai-text-transform-pane-target="state"]');
    if (openPane) {
      body.set('open', 'true');
      body.set('previous_run', openPane.dataset.run ?? '');
      body.set('previous_request_id', openPane.dataset.requestId ?? '');
    }

    const demoFault = new URLSearchParams(window.location.search).get(DEMO_FAULT_PARAM);
    if (demoFault) {
      body.set('demo_fault', demoFault);
    }
    return body;
  }
}
