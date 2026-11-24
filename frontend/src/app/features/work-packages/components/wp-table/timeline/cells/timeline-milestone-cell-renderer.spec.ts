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

import moment from 'moment';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { buildWorkPackage } from '../../../wp-fast-table/testing/work-package-fixture';
import { configureTimelineTesting, mountTimeline } from '../testing/timeline-harness';
import { RenderInfo, TimelineViewParameters } from '../wp-timeline';
import { TimelineMilestoneCellRenderer } from './timeline-milestone-cell-renderer';

describe('TimelineMilestoneCellRenderer', () => {
  let mount:ReturnType<typeof mountTimeline>;
  let renderer:TimelineMilestoneCellRenderer;

  beforeEach(async () => {
    await configureTimelineTesting();
    mount = mountTimeline();
    mount.finishDays();
    renderer = new TimelineMilestoneCellRenderer(mount.injector, mount.controller);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    mount?.destroy();
  });

  function baselineTimestamp(attributes:Record<string, unknown>, exists = true) {
    return { $links: {}, _meta: { exists, matchesFilters: exists, timestamp: '' }, ...attributes };
  }

  function info(timestamp:Record<string, unknown>|null = null):RenderInfo {
    const workPackage = buildWorkPackage({ id: '1', attributes: {
      injector: mount.injector, type: { id: '1', name: 'Task' }, isLeaf: true,
      date: '2026-11-04',
      attributesByTimestamp: timestamp ? [baselineTimestamp(timestamp)] : [],
    } });
    const viewParams = new TimelineViewParameters();
    viewParams.dateDisplayStart = moment('2026-10-01');
    viewParams.dateDisplayEnd = moment('2026-12-01');
    return { workPackage, change: new WorkPackageChangeset(workPackage), viewParams };
  }

  function activateBaseline() {
    vi.spyOn(mount.injector.get(WorkPackageViewBaselineService), 'isActive').mockReturnValue(true);
  }

  it('does not draw a baseline marker while the baseline filter is inactive', () => {
    const renderInfo = info({ date: '2026-10-20' });
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    renderer.update(element, null, renderInfo);

    expect(mount.side.querySelector('.baseline-bar')).toBeNull();
  });

  it('draws a baseline marker and connects it to the current milestone on different days', () => {
    activateBaseline();
    const renderInfo = info({ date: '2026-10-20' });
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    renderer.update(element, null, renderInfo);

    const baselineBar = mount.side.querySelector<HTMLElement>('.baseline-bar')!;
    expect(baselineBar).not.toBeNull();
    expect(baselineBar.style.left).toBe(`${19 * 30}px`);
    expect(baselineBar.style.width).toBe('30px');

    const connector = mount.side.querySelector<HTMLElement>('.baseline-connector')!;
    expect(connector).not.toBeNull();
    expect(connector.style.left).toBe(`${20 * 30}px`);
    expect(connector.style.width).toBe(`${(34 - 20) * 30}px`);
  });

  it('does not draw a connector when the baseline and current milestone fall on the same day', () => {
    activateBaseline();
    const renderInfo = info({ date: '2026-11-04' });
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    renderer.update(element, null, renderInfo);

    expect(mount.side.querySelector('.baseline-bar')).not.toBeNull();
    expect(mount.side.querySelector('.baseline-connector')).toBeNull();
  });
});
