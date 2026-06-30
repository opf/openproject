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
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import WorkPackageTimelineController from './work-package-timeline.controller';

const EVENT_NAME = 'op-dispatched:resource-allocations:changed';

describe('WorkPackageTimelineController', () => {
  let ctx:StimulusTestContext;

  // A stand-in for the FullCalendar instance. We stub `initializeCalendar` so no
  // real calendar is built (it would measure the DOM and fetch the feeds); the
  // controller's reload wiring only needs the refetch/destroy methods.
  const calendar = {
    destroy: vi.fn(),
    refetchEvents: vi.fn(),
    refetchResources: vi.fn(),
  };

  const mountTimeline = async ():Promise<void> => {
    ctx = await setupStimulusTest({
      controllers: { 'resource-management--work-package-timeline': WorkPackageTimelineController },
    });

    const prefix = 'data-resource-management--work-package-timeline';
    ctx.appendHTML(`
      <div data-controller="resource-management--work-package-timeline"
           ${prefix}-reload-event-name-value="${EVENT_NAME}">
        <div ${prefix}-target="calendar"></div>
      </div>
    `);

    // connect() schedules the (stubbed) calendar init on the next animation frame.
    await ctx.nextFrame();
    await ctx.nextFrame();
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(WorkPackageTimelineController.prototype as unknown as { initializeCalendar:() => void }, 'initializeCalendar')
      .mockImplementation(function stubInitializeCalendar(this:{ calendar:unknown }) {
        this.calendar = calendar;
      });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  it('refetches both feeds when the allocation-changed event fires', async () => {
    await mountTimeline();

    document.dispatchEvent(new CustomEvent(EVENT_NAME));

    expect(calendar.refetchResources).toHaveBeenCalledTimes(1);
    expect(calendar.refetchEvents).toHaveBeenCalledTimes(1);
  });

  it('stops refetching once the controller disconnects', async () => {
    await mountTimeline();
    ctx.container.querySelector('[data-controller]')?.removeAttribute('data-controller');
    await ctx.nextFrame();

    document.dispatchEvent(new CustomEvent(EVENT_NAME));

    expect(calendar.refetchResources).not.toHaveBeenCalled();
    expect(calendar.refetchEvents).not.toHaveBeenCalled();
  });
});
