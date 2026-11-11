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
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { buildWorkPackage } from '../../../wp-fast-table/testing/work-package-fixture';
import { configureTimelineTesting, mountTimeline } from '../testing/timeline-harness';
import { RenderInfo, TimelineViewParameters } from '../wp-timeline';
import { TimelineCellRenderer } from './timeline-cell-renderer';

describe('TimelineCellRenderer', () => {
  let mount:ReturnType<typeof mountTimeline>;
  let renderer:TimelineCellRenderer;

  beforeEach(async () => {
    await configureTimelineTesting();
    mount = mountTimeline();
    mount.finishDays();
    renderer = new TimelineCellRenderer(mount.injector, mount.controller);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    mount?.destroy();
  });

  function info(attributes:Record<string, unknown> = {}):RenderInfo {
    const workPackage = buildWorkPackage({ id: '1', attributes: {
      injector: mount.injector, type: { id: '1', name: 'Task' }, isLeaf: true,
      startDate: '2026-11-02', dueDate: '2026-11-04',
      ignoreNonWorkingDays: true, ...attributes,
    } });
    const viewParams = new TimelineViewParameters();
    viewParams.dateDisplayStart = moment('2026-11-01');
    viewParams.dateDisplayEnd = moment('2026-11-30');
    return { workPackage, change: new WorkPackageChangeset(workPackage), viewParams };
  }

  it.each([
    [true, true, true, true],
    [false, true, true, false],
    [true, false, true, false],
    [true, true, false, false],
  ])('permits date movement with start writable %s, finish writable %s and editable %s', (start, due, editable, permitted) => {
    const schemaCache = mount.injector.get(SchemaCacheService);
    const schema = Object.assign(schemaCache.of(info().workPackage), {
      startDate: { writable: start },
      dueDate: { writable: due },
      isAttributeEditable: () => editable,
    });
    vi.spyOn(schemaCache, 'of').mockReturnValue(schema);

    expect(renderer.canMoveDates(info().workPackage)).toBe(permitted);
  });

  it('renders configured labels and clears a label when it is disabled', () => {
    mount.injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
    const timeline = mount.injector.get(WorkPackageViewTimelineService);
    timeline.updateLabels({ left: 'subject', right: '', farRight: '' });
    const renderInfo = info();
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    const labels = renderer.createAndAddLabels(renderInfo, element);

    expect(labels.left).toHaveTextContent('Work package 1');
    expect(labels.left).toHaveClass('not-empty');
    expect(labels.right).toBeEmptyDOMElement();

    timeline.updateLabels({ left: '', right: 'subject', farRight: '' });
    renderer.update(element, labels, renderInfo);

    expect(labels.left).toBeEmptyDOMElement();
    expect(labels.left).not.toHaveClass('not-empty');
    expect(labels.right).toHaveTextContent('Work package 1');
  });

  it('positions a dated bar across all of its calendar days', () => {
    const renderInfo = info();
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    expect(renderer.update(element, null, renderInfo)).toBe(true);

    expect(element.style.left).toBe('30px');
    expect(element.style.width).toBe('90px');
    expect(element.style.minWidth).toBe('30px');
    expect(element.style.visibility).toBe('visible');
  });

  it('hides an undated bar and shows it after dates are assigned', () => {
    const empty = info({ startDate: null, dueDate: null });
    const element = renderer.render(empty);
    mount.side.appendChild(element);

    renderer.update(element, null, empty);
    expect(element.style.visibility).toBe('hidden');

    renderer.update(element, null, info());
    expect(element.style.visibility).toBe('visible');
    expect(element.style.width).toBe('90px');
  });

  it('fades a finish-only bar towards its missing start', () => {
    const renderInfo = info({ startDate: null });
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    renderer.update(element, null, renderInfo);

    expect(element.style.left).toBe('90px');
    expect(element.style.width).toBe('30px');
    expect(element.querySelector<HTMLElement>('.timeline-element--bg')!.style.backgroundImage).toContain('linear-gradient');
  });

  it.each([
    ['2026-11-06', false],
    ['2026-11-07', true],
    ['2026-11-08', true],
  ])('identifies non-working date %s', (date, nonWorking) => {
    expect(renderer.cursorOrDatesAreNonWorking([moment(date)], info({ ignoreNonWorkingDays: false }))).toBe(nonWorking);
  });

  it('allows weekend dates when the work package ignores non-working days', () => {
    expect(renderer.cursorOrDatesAreNonWorking([moment('2026-11-07')], info())).toBe(false);
  });

  it('extends a two-day placeholder over the weekend', () => {
    const renderInfo = info({ duration: 'P2D', ignoreNonWorkingDays: false });
    const event = new MouseEvent('mousemove');
    Object.defineProperty(event, 'offsetX', { value: 150 });

    const placeholder = renderer.displayPlaceholderUnderCursor(event, renderInfo);

    expect(placeholder.style.left).toBe('150px');
    expect(placeholder.style.width).toBe('120px');
  });

  it('marks an automatically scheduled parent read-only', () => {
    const renderInfo = info({ isLeaf: false, scheduleManually: false });
    const element = renderer.render(renderInfo);
    mount.side.appendChild(element);

    renderer.update(element, null, renderInfo);
    expect(element.querySelector('.timeline-element--bg')).toHaveClass('-readonly');

    renderer.update(element, null, info({ isLeaf: false, scheduleManually: true }));
    expect(element.querySelector('.timeline-element--bg')).not.toHaveClass('-readonly');
  });
});
