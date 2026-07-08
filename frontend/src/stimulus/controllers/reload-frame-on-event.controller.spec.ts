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

import ReloadFrameOnEventController from './reload-frame-on-event.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

interface ReloadableFrame extends HTMLElement {
  src:string;
  reload:() => void;
}

describe('ReloadFrameOnEventController', () => {
  let ctx:StimulusTestContext;

  // Each frame gets its own reload counter. The controller listens on
  // `document`, so a counter per frame keeps a test from observing reloads
  // triggered on another test's (or another frame's) controller.
  const mountFrame = async ():Promise<{ frame:ReloadableFrame; calls:{ count:number } }> => {
    await ctx.mount(`
      <turbo-frame id="frame"
                   data-controller="reload-frame-on-event"
                   data-reload-frame-on-event-event-name-value="op-dispatched:resource-allocations:changed"
                   data-reload-frame-on-event-url-value="/planner/view">
        content
      </turbo-frame>
    `);

    const frame = ctx.container.querySelector('#frame') as unknown as ReloadableFrame;
    const calls = { count: 0 };
    frame.reload = () => { calls.count += 1; };
    return { frame, calls };
  };

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'reload-frame-on-event': ReloadFrameOnEventController },
    });
  });

  afterEach(() => ctx.dispose());

  it('points the frame at its url on the first event, then reloads on later events', async () => {
    const { frame, calls } = await mountFrame();

    document.dispatchEvent(new CustomEvent('op-dispatched:resource-allocations:changed'));
    expect(frame.src).toContain('/planner/view');
    expect(calls.count).toBe(0);

    document.dispatchEvent(new CustomEvent('op-dispatched:resource-allocations:changed'));
    expect(calls.count).toBe(1);
  });

  it('ignores unrelated events', async () => {
    const { frame, calls } = await mountFrame();

    document.dispatchEvent(new CustomEvent('some-other-event'));

    expect(frame.src || '').not.toContain('/planner/view');
    expect(calls.count).toBe(0);
  });

  it('stops reacting once disconnected', async () => {
    const { frame, calls } = await mountFrame();
    ctx.getController<ReloadFrameOnEventController>('reload-frame-on-event', frame).disconnect();

    document.dispatchEvent(new CustomEvent('op-dispatched:resource-allocations:changed'));

    expect(calls.count).toBe(0);
  });
});
