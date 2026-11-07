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

import '@angular/compiler';
import { wideFixture, WideProfile } from './wide-fixture';
import { CommonModule } from '@angular/common';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { I18n } from 'i18n-js';
import { Component, Injector, NO_ERRORS_SCHEMA, isDevMode } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom, map, of, take } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackagesTableComponent } from 'core-app/features/work-packages/components/wp-table/wp-table.component';
import { WorkPackageTimelineTableController } from 'core-app/features/work-packages/components/wp-table/timeline/container/wp-timeline-container.directive';
import { WorkPackageTableRowComponent } from 'core-app/features/work-packages/components/wp-fast-table/template-rows/wp-table-row.component';
import { buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { buildWorkPackage } from 'core-app/features/work-packages/components/wp-fast-table/testing/work-package-fixture';

@Component({
  selector: 'op-table-benchmark',
  templateUrl: '../../src/app/features/work-packages/components/wp-table/wp-table.component.html',
  imports: [CommonModule, WorkPackageTableRowComponent],
  schemas: [NO_ERRORS_SCHEMA],
})
class BenchmarkTableComponent extends WorkPackagesTableComponent {}

const warmups = 2;
const samples = 7;
const median = (values:number[]) => values.length ? [...values].sort((a, b) => a - b)[Math.floor(values.length / 2)] : null;

function assert(condition:unknown, message:string):asserts condition {
  if (!condition) throw new Error(message);
}

window.I18n = new I18n();
TestBed.initTestEnvironment(BrowserTestingModule, platformBrowserTesting());

export async function runBenchmark(options:{ initialOnly?:boolean; scenario?:string; suite?:'default'|'wide' } = {}) {
  assert(!isDevMode(), 'Angular development mode is enabled');
  const results:unknown[] = [];
  const cases:{ rowCount:number; parents:number; profile?:WideProfile }[] = options.suite === 'wide'
    ? [100, 500].flatMap((rowCount) => (['simple8', 'mixed10'] as const).map((profile) => ({ rowCount, parents: 0, profile })))
    : [{ rowCount: 100, parents: 0 }, { rowCount: 500, parents: 0 }, { rowCount: 500, parents: 20 }];
  for (const { rowCount, parents, profile } of cases) {
    const wide = profile ? wideFixture(profile) : undefined;
    const columns = wide?.columns ?? (parents ? ['id', 'subject', { id: 'follows', relationType: 'follows' }] : ['id', 'subject']);
    const target = parents ? String(rowCount) : '1';
    const relations = Array.from({ length: parents }, (_, index) => ({ from: String(index + 1), to: target, type: 'follows' }));
    for (const templates of [false, true]) {
      const scenario = `${profile ? `${profile}:` : ''}${rowCount}:${parents}:${templates ? 'Angular' : 'legacy'}`;
      if (options.scenario && options.scenario !== scenario) continue;
      TestBed.resetTestingModule();
      await TestBed.configureTestingModule({
        imports: [BenchmarkTableComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          ...harnessProviders(new FakeDragAndDropService(), { workPackages: [], relations }),
          ...(wide?.providers ?? []),
          WorkPackageViewSumService,
          { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
        ],
      }).compileComponents();
      Object.assign(TestBed.inject(ConfigurationService), { activeFeatureFlags: templates ? ['newTableRendering'] : [] });
      const fields = TestBed.inject(DisplayFieldService);
      fields.addFieldType(TextDisplayField, 'text', ['String']);
      fields.addFieldType(WorkPackageIdDisplayField, 'id', ['id']);
      wide?.register(fields);
      if (wide) wide.initialize(TestBed.inject(HalResourceService));
      const query = buildQuery(columns, null, false, false);
      if (wide) query.highlightedAttributes = wide.highlightedAttributes;
      const querySpace = TestBed.inject(IsolatedQuerySpace);
      querySpace.query.putValue(query);
      querySpace.groups.putValue([]);
      initializeViewServices(TestBed.inject(Injector), query);
      TestBed.inject(WorkPackageViewSumService).initialize(query);
      relations.forEach(({ from }) => TestBed.inject(WorkPackageViewRelationColumnsService).setExpandFor(from, 'follows'));

      const states = TestBed.inject(States);
      const resources = Array.from({ length: rowCount }, (_, index) => buildWorkPackage({ id: String(index + 1), attributes: wide?.attributes(index) }));
      resources.forEach((resource) => states.workPackages.get(resource.id!).putValue(resource));
      querySpace.results.putValue({ elements: [], offset: 1, pageSize: rowCount, count: 0, total: 0 } as unknown as WorkPackageCollectionResource);
      const timings = { initial: [] as number[], redraw: [] as number[], refresh: [] as number[] };
      const stages = {
        initial: { buildRows: [] as number[], angular: [] as number[], calls: [] as number[] },
        redraw: { buildRows: [] as number[], angular: [] as number[], calls: [] as number[] },
        refresh: { buildRows: [] as number[], angular: [] as number[], calls: [] as number[] },
      };

      for (let sample = 0; sample < warmups + samples; sample++) {
        querySpace.tableRendered.clear();
        querySpace.initialized.clear();
        const fixture = TestBed.createComponent(BenchmarkTableComponent);
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
          let stage = { buildRows: 0, angular: 0, calls: 0 };
          const builder = table.rowBuilder;
          const buildRows = builder.buildRows.bind(builder);
          builder.buildRows = (options) => {
            const start = performance.now();
            try { return buildRows(options); } finally { stage.buildRows += performance.now() - start; }
          };
          const component = fixture.componentInstance;
          const renderRows = component.renderRows.bind(component);
          component.renderRows = (rows, view) => {
            const start = performance.now();
            try { stage.calls++; renderRows(rows, view); } finally { stage.angular += performance.now() - start; }
          };
          const recordStage = (operation:keyof typeof stages) => {
            if (sample >= warmups) {
              stages[operation].buildRows.push(stage.buildRows);
              stages[operation].angular.push(stage.angular);
              stages[operation].calls.push(stage.calls);
            }
            stage = { buildRows: 0, angular: 0, calls: 0 };
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
          assert(root.querySelectorAll('.work-package--results-tbody > tr').length === rowCount + parents, 'Incorrect row count');
          assert(root.querySelector('.work-package--results-tbody a[href*="/work_packages/1"]'), `Missing work package link (${templates ? 'Angular' : 'legacy'}, ${rowCount}): ${root.querySelector('.work-package--results-tbody > tr')?.innerHTML}`);
          assert(root.querySelectorAll('tr[opwptablerow]').length === (templates ? rowCount + parents : 0), 'Incorrect renderer');
          if (wide) {
            root.querySelectorAll<HTMLTableRowElement>('.work-package--results-tbody > tr')
              .forEach((row, index) => wide.assertRow(row, index, `Work package ${index + 1}`));
          }
          if (options.initialOnly) {
            const occurrences = Array.from(root.querySelectorAll<HTMLTableRowElement>('.work-package--results-tbody > tr'))
              .filter((row) => row.querySelector(`a[data-work-package-id="${target}"]`));
            assert(occurrences.length === parents + 1, 'Incorrect initial target occurrence count');
            if (sample >= warmups) timings.initial.push(initial);
            continue;
          }
          const firstRow = root.querySelector('.work-package--results-tbody > tr');
          const redraw = await committedDuration(() => table.redrawTable());
          recordStage('redraw');
          if (templates) assert(root.querySelector('.work-package--results-tbody > tr') === firstRow, 'Row identity changed');
          const targetRows = Array.from(root.querySelectorAll<HTMLTableRowElement>('.work-package--results-tbody > tr'))
            .filter((row) => row.querySelector(`a[data-work-package-id="${target}"]`));
          assert(targetRows.length === parents + 1, 'Incorrect target occurrence count');
          const refreshStart = performance.now();
          table.refreshRows(buildWorkPackage({ id: target, subject: `Updated ${sample}`, attributes: wide?.attributes(Number(target) - 1) }));
          const refresh = performance.now() - refreshStart;
          recordStage('refresh');
          const updatedRows = Array.from(root.querySelectorAll<HTMLTableRowElement>('.work-package--results-tbody > tr'))
            .filter((row) => row.querySelector(`a[data-work-package-id="${target}"]`));
          assert(updatedRows.length === parents + 1, 'Refresh lost occurrences');
          updatedRows.forEach((row, index) => {
            assert(row.textContent?.includes(`Updated ${sample}`), 'Refresh failed');
            if (templates) assert(row === targetRows[index], 'Refresh replaced occurrence');
            wide?.assertRow(row, Number(target) - 1, `Updated ${sample}`);
          });
          if (templates) assert(root.querySelector('.work-package--results-tbody > tr') === firstRow, 'Refresh replaced row');
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
      results.push({
        renderer: templates ? 'Angular' : 'legacy', profile: profile ?? null, fixtureVersion: wide ? 'typed-hal-v1' : null, rowCount, relationParents: parents, columns, warmups, samples,
        initialMs: median(timings.initial), redrawMs: median(timings.redraw), refreshMs: median(timings.refresh),
        timings,
        stages: Object.fromEntries(Object.entries(stages).map(([operation, values]) => [operation, {
          buildRowsMs: median(values.buildRows), angularMs: median(values.angular), renderCalls: median(values.calls), samples: values,
        }])),
      });
    }
  }
  TestBed.resetTestingModule();
  assert(results.length > 0, 'No benchmark scenario matched');
  return { isDevMode: isDevMode(), initialOnly: !!options.initialOnly, scenario: options.scenario ?? null, suite: options.suite ?? 'default', results };
}

Object.assign(window, { runBenchmark });
