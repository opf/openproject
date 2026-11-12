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
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { WorkPackageTableTimelineRelations } from './wp-timeline-relations.directive';
import { mountTimelineChild } from '../testing/timeline-harness';
import { nextTask } from 'core-common/testing/timing';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageRelationsService } from '../../../wp-relations/wp-relations.service';
import { buildWorkPackage } from '../../../wp-fast-table/testing/work-package-fixture';
import { configureTimelineTesting, makeTable, mountTimeline } from '../testing/timeline-harness';

describe('Timeline relation attachment ownership', () => {
  let m:ReturnType<typeof mountTimeline>;
  beforeEach(async () => { await configureTimelineTesting(); m = mountTimeline(); });
  afterEach(() => m.destroy());
  async function drawRelation() {
    const states = m.injector.get(States);
    const rows = ['1', '2'].map((id) => {
      const wp = buildWorkPackage({ id, attributes: { injector: m.injector, startDate: '2026-10-01', dueDate: '2026-10-04' } });
      states.workPackages.get(id).putValue(wp);
      return { workPackageId: id, classIdentifier: `wp-row-${id}`, hidden: false };
    });
    m.querySpace.tableRendered.putValue(rows);
    m.finishDays();
    await waitFor(() => expect(m.controller.workPackageCells('1')).toHaveLength(1));
    const relation = new RelationResource(m.injector, {}, true, () => undefined, 'Relation');
    relation.id = '10';
    relation.type = 'precedes';
    relation.from = states.workPackages.get('1').value!;
    relation.to = states.workPackages.get('2').value!;
    void m.injector.get(WorkPackageRelationsService).updateValue('1', { '10': relation });
    const container = m.side.querySelector<HTMLElement>('.wp-table-timeline--relations')!;
    expect(container.querySelectorAll('.relation-line').length).toBeGreaterThan(0);
    return { container, relation };
  }

  it('does not paint retired relation DOM when relations or work packages change', async () => {
    const { container, relation } = await drawRelation();
    const original = container.innerHTML;
    const retiredNodes = Array.from(container.children);
    m.controller.workPackageTable.destroy();
    await m.injector.get(WorkPackageRelationsService).updateValue('1', { '10': relation });
    m.injector.get(States).workPackages.get('1').putValue(buildWorkPackage({ id: '1' }));
    await nextTask();
    expect(container.innerHTML).toBe(original);
    retiredNodes.forEach((node, index) => expect(container.children[index]).toBe(node));
  });

  it('draws cached relations again for a fresh attachment', async () => {
    const { container } = await drawRelation();
    m.controller.workPackageTable.destroy();
    container.replaceChildren();
    m.controller.workPackageTable = makeTable(m.controller);
    await waitFor(() => expect(container.querySelectorAll('.relation-line').length).toBeGreaterThan(0));
  });

  it('observes a submitted request rejection after its attachment is disposed', async () => {
    const error = new Error('relation transport failed');
    m.controller.workPackageTable.destroy();
    m.transport.relations.error(error);
    await waitFor(() => expect(m.transport.errors).toContain(error));
  });

  it('removes a retired child refresh callback and preserves a replacement registration', () => {
    const child = mountTimelineChild(WorkPackageTableTimelineRelations, m);
    const replacement = mountTimelineChild(WorkPackageTableTimelineRelations, m);
    const renderers = (m.controller as unknown as { renderers:Record<string, unknown> }).renderers;
    const replacementCallback = renderers.relations;
    child.destroy();
    expect(renderers.relations).toBe(replacementCallback);
    replacement.destroy();
    expect(renderers.relations).toBeUndefined();
  });

  it('stops requesting relations while its table is disposed and rebinds a replacement', async () => {
    const initial = m.transport.relationRequests.length;
    m.controller.workPackageTable.destroy();
    m.querySpace.tableRendered.putValue([{ workPackageId: '1', classIdentifier: 'wp-row-1', hidden: false }]);
    m.injector.get(States).workPackages.get('1').putValue(buildWorkPackage({ id: '1' }));
    void m.injector.get(WorkPackageRelationsService).updateValue('1', {});
    await nextTask();
    expect(m.transport.relationRequests).toHaveLength(initial);
    m.controller.workPackageTable = makeTable(m.controller);
    expect(m.transport.relationRequests).toHaveLength(initial + 1);
    expect(m.transport.relationRequests.at(-1)).toEqual(['1']);
  });
});
