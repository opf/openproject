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
import moment from 'moment';
import { nextTask } from 'core-common/testing/timing';
import { WorkPackageTableTimelineGrid } from './wp-timeline-grid.directive';
import { TimelineViewParameters } from '../wp-timeline';
import { configureTimelineTesting, makeTable, mountTimeline, mountTimelineChild } from '../testing/timeline-harness';

describe('Timeline grid deferred ownership', () => {
  let m:ReturnType<typeof mountTimeline>;
  beforeEach(async () => { await configureTimelineTesting(); m = mountTimeline(); });
  afterEach(() => m.destroy());
  let externalElement:HTMLElement;
  function render(child?:WorkPackageTableTimelineGrid) {
    const vp = new TimelineViewParameters();
    vp.dateDisplayStart = moment('2026-01-01');
    vp.dateDisplayEnd = moment('2026-03-01');
    vp.visibleViewportAtCalculationTime = [moment('2026-01-10'), moment('2026-01-15')];
    (child ?? m.child(WorkPackageTableTimelineGrid)).refreshView(vp);
    return (child ? externalElement : m.side).querySelector<HTMLElement>('.wp-table-timeline--grid')!;
  }
  it('releases only its own refresh callback', () => {
    const child = mountTimelineChild(WorkPackageTableTimelineGrid, m);
    const replacement = mountTimelineChild(WorkPackageTableTimelineGrid, m);
    const renderers = (m.controller as unknown as { renderers:Record<string, unknown> }).renderers;
    const callback = renderers.grid;
    child.destroy();
    expect(renderers.grid).toBe(callback);
    replacement.destroy();
    expect(renderers.grid).toBeUndefined();
  });
  it('drops the offscreen batch after table disposal', async () => {
    const element = render();
    const initial = element.childElementCount;
    expect(initial).toBeGreaterThan(0);
    m.controller.workPackageTable.destroy();
    await nextTask();
    expect(element.childElementCount).toBe(initial);
  });
  it('drops the offscreen batch after child disposal', async () => {
    const child = mountTimelineChild(WorkPackageTableTimelineGrid, m);
    externalElement = child.location.nativeElement as HTMLElement;
    const element = render(child.instance);
    const initial = element.childElementCount;
    child.destroy();
    await nextTask();
    expect(element.childElementCount).toBe(initial);
  });
  it('renders a replacement using the same element without an old offscreen batch', async () => {
    const element = render();
    await nextTask();
    const liveCount = element.childElementCount;
    render();
    m.controller.workPackageTable.destroy();
    m.controller.workPackageTable = makeTable(m.controller);
    const fresh = render();
    expect(fresh).toBe(element);
    await nextTask();
    expect(element.childElementCount).toBe(liveCount);
  });
});
