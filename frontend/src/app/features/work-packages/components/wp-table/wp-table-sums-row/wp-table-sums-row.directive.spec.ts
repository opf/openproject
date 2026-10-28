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

import { Component, Injector } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { nextTask } from 'core-common/testing/timing';
import { buildQuery, buildTable, FakeDragAndDropService, harnessProviders, initializeViewServices, TableHarness } from '../../wp-fast-table/testing/table-harness';
import { WorkPackageTableSumsRowController } from './wp-table-sums-row.directive';

@Component({ template: '<table><tbody><tr wpTableSumsRow></tr></tbody></table>', standalone: false })
class SumsHostComponent {}

describe('WorkPackageTableSumsRowController input readiness', () => {
  let fixture:ComponentFixture<SumsHostComponent>;
  let directive:WorkPackageTableSumsRowController;
  let row:HTMLTableRowElement;
  let harness:TableHarness;
  let schemaResponse:Subject<SchemaResource>;
  const tables:TableHarness[] = [];
  const schema = {} as SchemaResource;

  beforeEach(async () => {
    schemaResponse = new Subject<SchemaResource>();
    await TestBed.configureTestingModule({ declarations: [SumsHostComponent, WorkPackageTableSumsRowController], providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }) })
      .overrideDirective(WorkPackageTableSumsRowController, {
        add: {
          providers: [
            SchemaCacheService, WorkPackageViewSumService,
            { provide: HalResourceService, useValue: { createHalResourceOfClass: () => schema, get: () => schemaResponse } },
          ],
        },
      }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    harness = buildTable({ workPackages: [] });
    tables.push(harness);
    fixture = TestBed.createComponent(SumsHostComponent);
    const debug = fixture.debugElement.query(By.directive(WorkPackageTableSumsRowController));
    directive = debug.injector.get(WorkPackageTableSumsRowController);
    row = debug.nativeElement as HTMLTableRowElement;
    directive.wpTableSums.setEnabled(true);
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/schema' }, totalSums: {},
    } as unknown as WorkPackageCollectionResource);
  });

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  async function resolveSchema() {
    schemaResponse.next(schema);
    await nextTask();
  }

  it('waits for the table input and replays the initial sums', async () => {
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    fixture.detectChanges();
    expect(loading).not.toHaveBeenCalled();
    directive.workPackageTable = harness.table;
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    expect(loading).toHaveBeenCalledTimes(1);
  });

  it('ignores an already destroyed table input', async () => {
    harness.table.destroy();
    directive.workPackageTable = harness.table;
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    fixture.detectChanges();
    await resolveSchema();
    expect(loading).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
  });

  it.each(['sums row', 'table'])('ignores schema completion after destroying the %s', async (owner) => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    if (owner === 'sums row') fixture.destroy();
    else harness.table.destroy();
    await resolveSchema();
    expect(row).toBeEmptyDOMElement();
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/another' }, totalSums: {},
    } as unknown as WorkPackageCollectionResource);
    expect(loading).not.toHaveBeenCalled();
  });

  it('ignores schema completion from the previous input', async () => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    directive.workPackageTable = replacement.table;
    replacement.table.destroy();
    await resolveSchema();
    expect(row).toBeEmptyDOMElement();
  });

  it('keeps a replacement input reacting when the previous table is destroyed', async () => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    directive.workPackageTable = replacement.table;
    harness.table.destroy();
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    directive.wpTableSums.setEnabled(false);
    expect(row).toBeEmptyDOMElement();
  });
});
