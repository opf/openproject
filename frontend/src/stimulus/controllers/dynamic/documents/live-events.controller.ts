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

import { HocuspocusProvider, onAwarenessUpdateParameters, onStatelessParameters } from '@hocuspocus/provider';
import * as Turbo from '@hotwired/turbo';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { ApplicationController, useDebounce } from 'stimulus-use';

interface LiveUser {id:string, name:string, avatarUrl:string}

export default class extends ApplicationController {
  static debounces = ['triggerUpdateUsersUI'];
  static targets = ['users', 'popover'];

  declare readonly usersTarget:HTMLElement;
  declare readonly popoverTarget:HTMLElement;

  private provider:HocuspocusProvider|null = null;
  private readyCallback:((provider:HocuspocusProvider) => void) | null = null;
  private latestUserIds:string|null = null;
  private requestedUserIds:string|null = null;
  private renderedUserIds:string|null = null;

  connect() {
    this.readyCallback = (provider:HocuspocusProvider) => {
      this.provider = provider;
      this.provider.on('awarenessUpdate', this.onAwarenessUpdate);
      this.provider.on('stateless', this.onStateless);
    };
    LiveCollaborationManager.onReady(this.readyCallback);

    useDebounce(this, { wait: 1000 });
  }

  disconnect() {
    // Deregister before cleanup to prevent stale callbacks firing into a detached controller
    if (this.readyCallback) {
      LiveCollaborationManager.offReady(this.readyCallback);
      this.readyCallback = null;
    }

    this.latestUserIds = null;
    this.requestedUserIds = null;
    this.renderedUserIds = null;

    this.provider?.off('awarenessUpdate', this.onAwarenessUpdate);
    this.provider?.off('stateless', this.onStateless);

    this.provider = null;
  }

  togglePopover() {
    this.popoverTarget.classList.toggle('d-none');
  }

  closePopover() {
    this.popoverTarget.classList.add('d-none');
  }

  closeOnClickOutside(event:MouseEvent) {
    if (!this.element.contains(event.target as Node)) {
      this.closePopover();
    }
  }

  private onAwarenessUpdate = (data:onAwarenessUpdateParameters) => {
    const awarenessStates = data.states;

    if (awarenessStates.length === 0) return;

    this.latestUserIds = this.userIdsParams(awarenessStates);

    if (this.latestUserIds !== this.renderedUserIds && this.latestUserIds !== this.requestedUserIds) {
      this.requestedUserIds = this.latestUserIds;
      this.triggerUpdateUsersUI();
    }
  };

  private onStateless = (data:onStatelessParameters) => {
    if (data.payload == 'storeEvent') {
      this.fetchTemplate(`${window.location.pathname}/render_last_saved_at`)
        .then((html) => Turbo.renderStreamMessage(html))
        .catch(() => undefined);
    }
  };

  private userIdsParams(states:onAwarenessUpdateParameters['states']) {
    const params = new URLSearchParams();

    states.forEach((state) => {
      if (state.user) {
        params.append('user_ids[]', (state.user as LiveUser).id);
      }
    });

    return params.toString();
  }

  private triggerUpdateUsersUI() {
    const userIds = this.latestUserIds;
    if (userIds === null) return;

    this.requestedUserIds = userIds;
    this.fetchTemplate(`${window.location.pathname}/render_avatars?${userIds}`)
      .then((html) => {
        if (userIds !== this.latestUserIds) return;

        Turbo.renderStreamMessage(html);
        this.renderedUserIds = userIds;
      })
      .catch(() => {
        if (userIds === this.requestedUserIds) {
          this.requestedUserIds = null;
        }
      });
  }

  private fetchTemplate(url:string):Promise<string> {
    return fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
      },
    })
      .then((response:Response) => {
        if (response.ok) {
          return response.text();
        }
        return Promise.reject(new Error(`Failed to fetch ${url}: ${response.status} ${response.statusText}`));
      })
      .catch((error:Error) => {
        console.error('Error:', error);
        throw error;
      });
  }
}
