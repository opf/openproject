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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageTableRow } from 'core-app/features/work-packages/components/wp-fast-table/wp-table.interfaces';
import { SingleRowBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/rows/single-row-builder';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { groupedRowClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers';
import {
  GroupedRenderPass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-render-pass';
import {
  GroupHeaderBuilder,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/group-header-builder';

class TestGroupedRenderPass extends GroupedRenderPass {
  public renderRows():this {
    this.tableBody = document.createDocumentFragment();
    this.renderedOrder = [];
    this.doRender();

    return this;
  }
}

describe('GroupedRenderPass', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders a work package under its multi-value group when hrefs match in different order', () => {
    const workPackage = {
      id: '1',
      customField16: [
        { href: '/api/v3/custom_options/9' },
        { href: '/api/v3/custom_options/11' },
        { href: '/api/v3/custom_options/10' },
      ],
    } as unknown as WorkPackageResource;
    const group = buildGroup({
      0: { href: '/api/v3/custom_options/10' },
      1: { href: '/api/v3/custom_options/9' },
      2: { href: '/api/v3/custom_options/11' },
    });
    const row = buildTableRow(workPackage);
    const pass = buildRenderPass([row], [group]);

    pass.renderRows();

    const rows = Array.from(pass.tableBody.children);
    expect(rows).toHaveLength(2);
    expect(rows[0].getAttribute('data-test-selector')).toBe('group-header');
    expect(rows[1].classList.contains(groupedRowClassName(group.index))).toBe(true);
    expect(pass.result).toEqual([
      { classIdentifier: 'group-custom-field-16-options', workPackageId: null, hidden: false },
      { classIdentifier: 'wp-row-1', workPackageId: '1', hidden: false },
    ]);
  });

  it('leaves a work package ungrouped when the multi-value hrefs differ', () => {
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    const workPackage = {
      id: '1',
      customField16: [
        { href: '/api/v3/custom_options/9' },
      ],
    } as unknown as WorkPackageResource;
    const group = buildGroup({
      0: { href: '/api/v3/custom_options/10' },
    });
    const row = buildTableRow(workPackage);
    const pass = buildRenderPass([row], [group]);

    pass.renderRows();

    const rows = Array.from(pass.tableBody.children);
    expect(rows).toHaveLength(1);
    expect(rows[0].getAttribute('data-test-selector')).toBe('work-package-row');
    expect(rows[0].classList.contains(groupedRowClassName(group.index))).toBe(false);
    expect(pass.result).toEqual([
      { classIdentifier: 'wp-row-1', workPackageId: '1', hidden: false },
    ]);
  });
});

function buildRenderPass(rows:WorkPackageTableRow[], groups:GroupObject[]):TestGroupedRenderPass {
  const pass = new TestGroupedRenderPass(
    buildInjector(),
    buildWorkPackageTable(rows),
    groups,
    buildHeaderBuilder(),
    1,
  );
  pass.rowBuilder = buildRowBuilder();

  return pass;
}

function buildWorkPackageTable(rows:WorkPackageTableRow[]):WorkPackageTable {
  return {
    originalRows: rows.map((row) => row.workPackageId),
    originalRowIndex: Object.fromEntries(rows.map((row) => [row.workPackageId, row])),
    configuration: {
      dragAndDropEnabled: false,
    },
  } as unknown as WorkPackageTable;
}

function buildInjector():Injector {
  const services = new Map<unknown, unknown>([
    [I18nService, { t: (key:string) => key }],
    [WorkPackageViewColumnsService, { getColumns: () => [] }],
    [WorkPackageViewBaselineService, { isActive: () => false }],
  ]);

  return {
    get: (token:unknown, notFoundValue?:unknown) => services.get(token) ?? notFoundValue ?? null,
  };
}

function buildTableRow(workPackage:WorkPackageResource):WorkPackageTableRow {
  return {
    object: workPackage,
    workPackageId: workPackage.id!,
    position: 0,
    group: null,
  };
}

function buildGroup(href:Record<string, { href:string }>):GroupObject {
  return {
    value: 'Option set',
    count: 1,
    collapsed: false,
    index: 0,
    identifier: 'custom-field-16-options',
    sums: null as unknown as GroupObject['sums'],
    href: href as unknown as GroupObject['href'],
    _links: {
      valueLink: [],
      groupBy: { href: '/api/v3/queries/group_bys/customField16' },
    },
  };
}

function buildHeaderBuilder():GroupHeaderBuilder {
  return {
    buildGroupRow: () => {
      const row = document.createElement('tr');
      row.setAttribute('data-test-selector', 'group-header');

      return row;
    },
  } as unknown as GroupHeaderBuilder;
}

function buildRowBuilder():SingleRowBuilder {
  return {
    buildEmpty: (workPackage:WorkPackageResource) => {
      const row = document.createElement('tr');
      row.setAttribute('data-test-selector', 'work-package-row');
      row.dataset.workPackageId = workPackage.id!;

      return [row, false] as [HTMLTableRowElement, boolean];
    },
    classIdentifier: (workPackage:WorkPackageResource) => `wp-row-${workPackage.id}`,
  } as unknown as SingleRowBuilder;
}
