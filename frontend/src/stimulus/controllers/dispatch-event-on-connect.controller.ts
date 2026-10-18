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

// Fires a single CustomEvent on `document` the moment the element is connected
// to the DOM. Lets a server-rendered HTML response signal that something
// changed and listeners should refresh, without needing a turbo-stream reply.
//
// The event name must start with `op-dispatched:`, matching the convention
// enforced by the `dispatchEvent` turbo-stream action - the frontend's
// listeners (IAN center, bell, WP split view) subscribe to that namespace.
export default class DispatchEventOnConnectController extends Controller {
  static values = { name: String };

  declare nameValue:string;

  declare hasNameValue:boolean;

  connect():void {
    if (!this.hasNameValue || this.nameValue.length === 0) { return; }

    if (!this.nameValue.startsWith('op-dispatched:')) {
      // Keep the server-rendered attribute from forging arbitrary document
      // events; the same guard the turbo-stream action enforces.
      // eslint-disable-next-line no-console
      console.error(`[dispatch-event-on-connect] Refusing to dispatch "${this.nameValue}": must start with "op-dispatched:".`);
      return;
    }

    document.dispatchEvent(new CustomEvent(this.nameValue));
  }
}
