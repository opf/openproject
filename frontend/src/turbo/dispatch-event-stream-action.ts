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

import { StreamActions, StreamElement } from '@hotwired/turbo';

// Dedicated namespace for events dispatched via the `dispatchEvent` turbo stream
// action. This is a security boundary: turbo streams can be injected into the
// DOM (e.g. via stored content), so an attacker could otherwise forge arbitrary
// `document` events. Restricting to this prefix keeps the forgeable surface
// disjoint from the general `op:` event namespace (e.g. `op:theme-changed`),
// whose listeners must never be reachable from an injected stream. Every
// server-side `dispatch_event_via_turbo_stream` caller must name its event
// `op-dispatched:<name>`.
const DISPATCHED_EVENT_PREFIX = 'op-dispatched:';

export function registerDispatchEventStreamAction() {
  StreamActions.dispatchEvent = function dispatchEventStreamAction(this:StreamElement) {
    const name = this.getAttribute('event-name');
    if (!name) { return; }

    if (!name.startsWith(DISPATCHED_EVENT_PREFIX)) {
      console.error(`[dispatchEvent] Refusing to dispatch event "${name}": name must start with "${DISPATCHED_EVENT_PREFIX}".`);
      return;
    }

    const detail = JSON.parse(this.getAttribute('detail') ?? '{}') as unknown;
    document.dispatchEvent(new CustomEvent(name, { detail }));
  };
}
