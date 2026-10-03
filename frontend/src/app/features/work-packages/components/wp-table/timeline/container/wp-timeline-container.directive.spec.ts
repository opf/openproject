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
import { fireEvent, waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { nextTask } from 'core-common/testing/timing';
import { configureTimelineTesting, makeTable, mountTimeline } from '../testing/timeline-harness';

describe('Timeline attachment ownership', () => {
  const mounts:ReturnType<typeof mountTimeline>[] = [];
  beforeEach(configureTimelineTesting);
  afterEach(() => { mounts.splice(0).forEach((mount) => mount.destroy()); });
  function mount() { const value = mountTimeline(); mounts.push(value); return value; }

  it('does not assign days, render, or publish an old days load into a fresh attachment', async () => {
    const m = mount();
    let renders = 0;
    let publications = 0;
    m.controller.onRefreshRequested('test', () => { renders += 1; });
    m.querySpace.timelineRendered.subscribe(() => { publications += 1; });
    const original = m.controller.workPackageTable;
    original.destroy();
    expect(m.transport.days[0].observed).toBe(true);
    m.controller.disableViewParamsCalculation = true;
    m.controller.viewParameters.dateDisplayStart.add(5, 'years');
    m.controller.workPackageTable = makeTable(m.controller);
    m.finishDays([{ id: 'old', date: '2026-10-01' }]);
    await nextTask();
    expect(m.controller.nonWorkingDays).toEqual([]);
    expect(renders).toBe(0);
    expect(publications).toBe(0);
    m.finishDays([], 1);
    await nextTask();
    expect(renders).toBe(1);
    await waitFor(() => expect(publications).toBe(1));
  });

  it('does not assign or publish a days load after independent directive disposal', async () => {
    const m = mount();
    let renders = 0;
    let publications = 0;
    m.controller.onRefreshRequested('test', () => { renders += 1; });
    m.querySpace.timelineRendered.subscribe(() => { publications += 1; });
    m.fixture.destroy();
    const requests = m.transport.dayRequests.length;
    m.controller.viewParameters.dateDisplayStart.add(5, 'years');
    fireEvent.scroll(m.side);
    fireEvent(window, new Event('wp-resize.timeline'));
    expect(m.transport.dayRequests).toHaveLength(requests);
    m.finishDays([{ id: 'old', date: '2026-10-01' }]);
    await nextTask();
    expect(m.controller.nonWorkingDays).toEqual([]);
    expect(renders).toBe(0);
    expect(publications).toBe(0);
  });

  it('cancels a queued publication if its table is disposed after the days load', async () => {
    const m = mount();
    let publications = 0;
    m.querySpace.timelineRendered.subscribe(() => { publications += 1; });
    m.finishDays();
    await Promise.resolve();
    await Promise.resolve();
    m.controller.workPackageTable.destroy();
    await nextTask();
    expect(publications).toBe(0);
  });

  it('ignores already-destroyed tables and duplicate live registration', () => {
    const m = mount();
    const dead = makeTable(m.controller);
    dead.destroy();
    const original = m.controller.workPackageTable;
    m.controller.workPackageTable = dead;
    expect(m.controller.workPackageTable).toBe(original);
    let attachments = 0;
    m.controller.tables$.subscribe(() => { attachments += 1; });
    m.controller.workPackageTable = original;
    m.controller.workPackageTable = original;
    expect(attachments).toBe(1);
  });

  it('returns exact refresh cleanup without removing a replacement callback', async () => {
    const m = mount();
    let calls = 0;
    const release = m.controller.onRefreshRequested('test', () => { calls += 100; });
    m.controller.onRefreshRequested('test', () => { calls += 1; });
    release();
    m.finishDays();
    await waitFor(() => expect(calls).toBe(1));
  });

  it('rebinds the typed common stream once per replacement and ignores retired emissions', () => {
    const m = mount();
    const source = new Subject<number>();
    const received:number[] = [];
    source.pipe(m.controller.commonPipes).subscribe((value) => received.push(value));
    source.next(1);
    m.controller.workPackageTable.destroy();
    source.next(2);
    m.controller.workPackageTable = makeTable(m.controller);
    source.next(3);
    expect(received).toEqual([1, 3]);
  });

  it('owns scroll requests within each embedded timeline and removes listeners on disposal', () => {
    const first = mount();
    const second = mount();
    const firstDays = first.transport.dayRequests.length;
    const secondDays = second.transport.dayRequests.length;
    // Scroll to an uncached year, since the pending initial request is shared.
    second.side.scrollLeft = 0;
    second.controller.viewParameters.dateDisplayStart.add(5, 'years');
    fireEvent.scroll(second.side);
    expect(first.transport.dayRequests).toHaveLength(firstDays);
    expect(second.transport.dayRequests).toHaveLength(secondDays + 1);
    second.controller.workPackageTable.destroy();
    second.controller.viewParameters.dateDisplayStart.add(5, 'years');
    fireEvent.scroll(second.side);
    expect(second.transport.dayRequests).toHaveLength(secondDays + 1);
  });
});
