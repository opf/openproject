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

import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { waitFor } from '@testing-library/dom';
import { WorkPackageTableTimelineStaticElements } from './wp-timeline-static-elements.directive';
import { nextTask } from 'core-common/testing/timing';
import { configureTimelineTesting, mountTimeline, mountTimelineChild } from '../testing/timeline-harness';

describe('Timeline static elements ownership', () => {
  const mounts:ReturnType<typeof mountTimeline>[] = [];
  beforeEach(configureTimelineTesting);
  afterEach(() => { mounts.splice(0).forEach((mount) => mount.destroy()); });
  function mount() { const value = mountTimeline(); mounts.push(value); return value; }
  it('releases only its own refresh callback', () => {
    const m = mount();
    const child = mountTimelineChild(WorkPackageTableTimelineStaticElements, m);
    const replacement = mountTimelineChild(WorkPackageTableTimelineStaticElements, m);
    const renderers = (m.controller as unknown as { renderers:Record<string, unknown> }).renderers;
    const callback = renderers['static elements'];
    child.destroy();
    expect(renderers['static elements']).toBe(callback);
    replacement.destroy();
    expect(renderers['static elements']).toBeUndefined();
  });
  it('scrolls only its own embedded timeline', async () => {
    const first = mount();
    const second = mount();
    first.side.scrollLeft = 0;
    second.finishDays();
    await nextTask();
    expect(first.side.scrollLeft).toBe(0);
    await waitFor(() => expect(second.side.scrollLeft).toBeGreaterThan(0));
  });
});
