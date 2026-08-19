/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { vi } from 'vitest';
import { StreamActions } from '@hotwired/turbo';
import { registerDispatchEventStreamAction } from './dispatch-event-stream-action';

describe('dispatchEvent turbo stream action', () => {
  // Invoke the action the way Turbo does: `this` bound to the <turbo-stream>
  // element carrying the attributes.
  const runAction = (attributes:Record<string, string>):void => {
    const element = document.createElement('turbo-stream');
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
    StreamActions.dispatchEvent.call(element);
  };

  // Capture every event the action dispatches on `document`, regardless of
  // name, so we can assert both what fires and what does not.
  let dispatched:CustomEvent[];

  beforeEach(() => {
    registerDispatchEventStreamAction();
    dispatched = [];
    // jsdom does not let us add a listener for an arbitrary name retroactively,
    // so we spy on dispatchEvent itself to record everything.
    vi.spyOn(document, 'dispatchEvent').mockImplementation((event:Event) => {
      dispatched.push(event as CustomEvent);
      return true;
    });
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('dispatches an op-dispatched: prefixed event on document with parsed detail', () => {
    runAction({ 'event-name': 'op-dispatched:resource-allocations:changed', detail: '{"workPackageId":42}' });

    expect(dispatched).toHaveLength(1);
    expect(dispatched[0].type).toBe('op-dispatched:resource-allocations:changed');
    expect(dispatched[0].detail).toEqual({ workPackageId: 42 });
  });

  it('defaults detail to an empty object when no detail attribute is present', () => {
    runAction({ 'event-name': 'op-dispatched:no-detail' });

    expect(dispatched).toHaveLength(1);
    expect(dispatched[0].detail).toEqual({});
  });

  it('refuses to dispatch a native event name like submit', () => {
    runAction({ 'event-name': 'submit' });

    expect(dispatched).toHaveLength(0);
    expect(console.error).toHaveBeenCalledWith(expect.stringContaining('submit'));
  });

  it('refuses an event in the general op: namespace', () => {
    runAction({ 'event-name': 'op:theme-changed' });

    expect(dispatched).toHaveLength(0);
    expect(console.error).toHaveBeenCalledWith(expect.stringContaining('op:theme-changed'));
  });

  it('refuses an unprefixed event even if it matches a real listener', () => {
    runAction({ 'event-name': 'resource-allocations:changed' });

    expect(dispatched).toHaveLength(0);
  });

  it('does nothing when no event-name is given', () => {
    runAction({ detail: '{"workPackageId":42}' });

    expect(dispatched).toHaveLength(0);
    expect(console.error).not.toHaveBeenCalled();
  });
});
