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

import { Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { buildTable, TableHarness } from '../../../wp-fast-table/testing/table-harness';
import { hierarchyGroupClass } from '../../../wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { TableDragActionService } from './table-drag-action.service';
import { GroupByDragActionService } from './group-by-drag-action.service';
import { HierarchyDragActionService } from './hierarchy-drag-action.service';

describe('prepared table drag actions', () => {
  let harness:TableHarness;
  afterEach(() => harness?.destroy());

  it('has a default persistence no-op independent of the table', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }] });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    const action = new TableDragActionService(harness.querySpace, harness.injector);
    const prepared = await action.prepareDrop(wp, harness.row('1'));
    await harness.destroy();
    await expect(prepared.persist()).resolves.toBeUndefined();
  });

  it.each(['Status', '[]Status'])('captures group attribute/value before disposal without mutating a changeset (%s)', async (type) => {
    const saved = { id: 'saved' } as WorkPackageResource;
    const projectedResource:Record<string, unknown> = {};
    const editing = { changeFor: vi.fn(() => ({ projectedResource })), save: vi.fn((change:unknown) => Promise.resolve({ resource: saved, change })) };
    const events = { push: vi.fn() };
    harness = buildTable({
      workPackages: [{ id: '1', attributes: { status: { href: '/statuses/1' } } }],
      groups: [{ value: 'New', href: '/statuses/1', count: 1 }],
      providers: [
        { provide: HalResourceEditingService, useValue: { ...editing, typedState: () => ({ hasValue: () => false }) } },
        { provide: HalEventsService, useValue: events },
        { provide: SchemaCacheService, useValue: {
          of: () => ({ ofProperty: () => undefined, mappedName: (name:string) => name }),
          state: () => ({ value: {} }),
          proxied: () => ({ ofProperty: () => ({ type }) }),
        } },
      ],
    });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    const action = new GroupByDragActionService(harness.querySpace, harness.injector);
    const prepared = await action.prepareDrop(wp, harness.row('1'));
    expect(editing.changeFor).not.toHaveBeenCalled();
    expect(projectedResource).toEqual({});
    harness.querySpace.groups.putValue([]);
    await harness.destroy();
    await prepared.persist();
    expect(editing.changeFor).toHaveBeenCalledExactlyOnceWith(wp);
    expect(projectedResource.status).toEqual(type.startsWith('[]') ? [{ href: '/statuses/1' }] : { href: '/statuses/1' });
    expect(events.push).toHaveBeenCalledExactlyOnceWith(saved, { eventType: 'updated' });
  });

  it('captures relation-row parent decisions before parent resource loading', async () => {
    const loaded = new Subject<WorkPackageResource>();
    const hierarchy = { changeParent: vi.fn(() => Promise.resolve()) };
    const states = new States();
    harness = buildTable({
      states,
      showHierarchies: true,
      workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '3' }] }, { id: '3' }],
      relations: [{ from: '2', to: '3', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      providers: [
        { provide: WorkPackageRelationsHierarchyService, useValue: hierarchy },
        { provide: ApiV3Service, useValue: { work_packages: {
          requireAll: (ids:string[]) => Promise.resolve(ids.map((id) => states.workPackages.get(id).value!)),
          id: () => ({ get: () => loaded }),
          cache: { current: (_id:string, fallback:unknown) => fallback, state: (id:string) => states.workPackages.get(id) },
        } } },
      ],
    });
    harness.expand('2', 'relationsOfTypeFollows');
    await harness.render();
    const row = harness.row('1');
    harness.relationRow('2', '3').after(row);
    row.classList.add(hierarchyGroupClass('3'));
    const wp = states.workPackages.get('1').value!;
    const action = new HierarchyDragActionService(harness.querySpace, harness.injector);
    const preparing = action.prepareDrop(wp, row);
    expect(hierarchy.changeParent).not.toHaveBeenCalled();
    await harness.destroy();
    loaded.next({ parent: { id: '3' } } as WorkPackageResource);
    loaded.complete();
    const prepared = await preparing;
    await prepared.persist();
    expect(hierarchy.changeParent).toHaveBeenCalledExactlyOnceWith(wp, '3', { reportError: false });
  });
});
