/*
 * -- copyright
 * openproject is an open source project management software.
 * copyright (c) the openproject gmbh
 *
 * this program is free software; you can redistribute it and/or
 * modify it under the terms of the gnu general public license version 3.
 *
 * openproject is a fork of chiliproject, which is a fork of redmine. the copyright follows:
 * copyright (c) 2006-2013 jean-philippe lang
 * copyright (c) 2010-2013 the chiliproject team
 *
 * this program is free software; you can redistribute it and/or
 * modify it under the terms of the gnu general public license
 * as published by the free software foundation; either version 2
 * of the license, or (at your option) any later version.
 *
 * this program is distributed in the hope that it will be useful,
 * but without any warranty; without even the implied warranty of
 * merchantability or fitness for a particular purpose.  see the
 * gnu general public license for more details.
 *
 * you should have received a copy of the gnu general public license
 * along with this program; if not, write to the free software
 * foundation, inc., 51 franklin street, fifth floor, boston, ma  02110-1301, usa.
 *
 * see copyright and license files for more details.
 * ++
 */

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
  private currentUsers = new Map<number, LiveUser>();

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

    this.currentUsers.clear();

    this.provider?.off('awarenessUpdate', this.onAwarenessUpdate);
    this.provider?.off('stateless', this.onStateless);

    this.provider = null;
  }

  toggle_popover() {
    this.popoverTarget.classList.toggle('d-none');
  }

  private onAwarenessUpdate = (data:onAwarenessUpdateParameters) => {
    const awarenessStates = data.states;

    if (awarenessStates.length === 0) return;

    const changed = this.updateUsers(awarenessStates);
    if (changed) {
      this.triggerUpdateUsersUI();
    }
  };

  private onStateless = (data:onStatelessParameters) => {
    if (data.payload == 'storeEvent') {
      this.fetchTemplate(`${window.location.pathname}/render_last_saved_at`);
    }
  };

  private updateUsers(states:onAwarenessUpdateParameters['states']) {
    const nextState = new Map<number, LiveUser>();

    states.forEach((state) => {
      if (state.user) {
        nextState.set(state.clientId, state.user as LiveUser);
      }
    });

    const previousUsers = [...this.currentUsers.keys()];
    const nextUsers = [...nextState.keys()];

    this.currentUsers = nextState;

    return (
      previousUsers.length !== nextUsers.length || previousUsers.some(id => !nextUsers.includes(id))
    );
  }

  private triggerUpdateUsersUI() {
    const params = new URLSearchParams();

    for (const user of this.currentUsers.values()) {
      params.append('user_ids[]', user.id);
    }

    this.fetchTemplate(`${window.location.pathname}/render_avatars?${params}`);
  }

  private fetchTemplate(url:string) {
    void fetch(url, {
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
      .then((html:string) => Turbo.renderStreamMessage(html))
      .catch((error:Error) => console.error('Error:', error));
  }
}

