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

import { Injector, NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom, map, of, take } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackagesTableComponent } from '../../wp-table/wp-table.component';
import { WorkPackageTimelineTableController } from '../../wp-table/timeline/container/wp-timeline-container.directive';
import { WorkPackageTableRowComponent } from '../template-rows/wp-table-row.component';
import { buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices } from './table-harness';
import { buildWorkPackage } from './work-package-fixture';

const warmups = 2;
const samples = 7;
const columns = ['id', 'subject'];
const median = (values:number[]) => [...values].sort((a, b) => a - b)[Math.floor(values.length / 2)];

for (const rowCount of [100, 500]) {
  for (const templates of [false, true]) {
    describe(`${templates ? 'Angular' : 'legacy'} rendering: ${rowCount} rows × ${columns.length} columns`, () => {
      beforeEach(async () => {
        await TestBed.configureTestingModule({
          imports: [WorkPackageTableRowComponent],
          declarations: [WorkPackagesTableComponent],
          schemas: [NO_ERRORS_SCHEMA],
          providers: [
            ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
            WorkPackageViewSumService,
            { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
          ],
        }).compileComponents();
        Object.assign(TestBed.inject(ConfigurationService), { activeFeatureFlags: templates ? ['newTableRendering'] : [] });
        const fields = TestBed.inject(DisplayFieldService);
        fields.addFieldType(TextDisplayField, 'text', ['String']);
        fields.addFieldType(WorkPackageIdDisplayField, 'id', ['id']);
        const query = buildQuery(columns, null, false, false);
        const querySpace = TestBed.inject(IsolatedQuerySpace);
        querySpace.query.putValue(query);
        querySpace.groups.putValue([]);
        initializeViewServices(TestBed.inject(Injector), query);
        TestBed.inject(WorkPackageViewSumService).initialize(query);
      });

      it('reports committed initial render, redraw and synchronous refresh medians', async () => {
        const querySpace = TestBed.inject(IsolatedQuerySpace);
        const states = TestBed.inject(States);
        const resources = Array.from({ length: rowCount }, (_, index) => buildWorkPackage({ id: String(index + 1) }));
        resources.forEach((resource) => states.workPackages.get(resource.id!).putValue(resource));
        querySpace.results.putValue({ elements: [], offset: 1, pageSize: rowCount, count: 0, total: 0 } as unknown as WorkPackageCollectionResource);
        const timings = { initial: [] as number[], redraw: [] as number[], refresh: [] as number[] };
        const stages = {
          initial: { buildRows: [] as number[], angular: [] as number[] },
          redraw: { buildRows: [] as number[], angular: [] as number[] },
          refresh: { buildRows: [] as number[], angular: [] as number[] },
        };

        for (let sample = 0; sample < warmups + samples; sample++) {
          querySpace.tableRendered.clear();
          querySpace.initialized.clear();
          const fixture = TestBed.createComponent(WorkPackagesTableComponent);
          fixture.componentRef.setInput('configuration', {
            actionsColumnEnabled: false, columnMenuEnabled: false, contextMenuEnabled: false,
            inlineCreateEnabled: false, dragAndDropEnabled: false,
          });
          const root = fixture.nativeElement as HTMLElement;
          document.body.appendChild(root);
          try {
            fixture.detectChanges();
            const timelineBody = document.createElement('div');
            root.querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(timelineBody);
            fixture.componentInstance.registerTimeline({} as WorkPackageTimelineTableController, timelineBody);
            const table = fixture.componentInstance.workPackageTable;
            let stage = { buildRows: 0, angular: 0 };
            const builder = table.rowBuilder;
            const buildRows = builder.buildRows.bind(builder);
            vi.spyOn(builder, 'buildRows').mockImplementation((options) => {
              const start = performance.now();
              try { return buildRows(options); } finally { stage.buildRows += performance.now() - start; }
            });
            const component = fixture.componentInstance;
            const renderRows = component.renderRows.bind(component);
            vi.spyOn(component, 'renderRows').mockImplementation((rows, view) => {
              const start = performance.now();
              try { renderRows(rows, view); } finally { stage.angular += performance.now() - start; }
            });
            const recordStage = (operation:keyof typeof stages) => {
              if (sample >= warmups) {
                stages[operation].buildRows.push(stage.buildRows);
                stages[operation].angular.push(stage.angular);
              }
              stage = { buildRows: 0, angular: 0 };
            };
            const committedDuration = async (run:() => void) => {
              querySpace.tableRendered.clear();
              const start = performance.now();
              const committed = firstValueFrom(querySpace.tableRendered.values$().pipe(take(1), map(() => performance.now() - start)));
              run();
              return committed;
            };
            const initial = await committedDuration(() => {
              querySpace.results.putValue({ elements: resources, offset: 1, pageSize: rowCount, count: rowCount, total: rowCount } as unknown as WorkPackageCollectionResource);
              querySpace.initialized.putValue(null);
            });
            recordStage('initial');
            expect(root.querySelectorAll('.work-package--results-tbody > tr')).toHaveLength(rowCount);
            expect(root.querySelectorAll('tr[opwptablerow]')).toHaveLength(templates ? rowCount : 0);
            const firstRow = root.querySelector('.work-package--results-tbody > tr');
            const redraw = await committedDuration(() => table.redrawTable());
            recordStage('redraw');
            if (templates) expect(root.querySelector('.work-package--results-tbody > tr')).toBe(firstRow);
            const refreshStart = performance.now();
            table.refreshRows(buildWorkPackage({ id: '1', subject: `Updated ${sample}` }));
            const refresh = performance.now() - refreshStart;
            recordStage('refresh');
            expect(root.querySelector('.work-package--results-tbody > tr')).toHaveTextContent(`Updated ${sample}`);
            if (sample >= warmups) {
              timings.initial.push(initial);
              timings.redraw.push(redraw);
              timings.refresh.push(refresh);
            }
          } finally {
            fixture.destroy();
            root.remove();
          }
        }
        // eslint-disable-next-line no-console
        console.info('[table-rendering-perf]', JSON.stringify({
          renderer: templates ? 'Angular' : 'legacy', rowCount, columns, warmups, samples,
          initialMs: median(timings.initial), redrawMs: median(timings.redraw), refreshMs: median(timings.refresh),
          timings,
          stages: Object.fromEntries(Object.entries(stages).map(([operation, values]) => [operation, {
            buildRowsMs: median(values.buildRows), angularMs: median(values.angular), samples: values,
          }])),
        }));
      }, 120_000);
    });
  }
}
