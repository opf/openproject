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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { within } from '@testing-library/dom';
import { tableColumns, tableRows } from 'core-app/shared/components/charts/description/testing/chart-description-table';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SprintWorkPackageGraphComponent } from './sprint-work-package-graph.component';
import { defineTestCustomElement, TestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

describe('SprintWorkPackageGraphComponent', () => {
  let fixture:ComponentFixture<SprintWorkPackageGraphComponent>;
  let element:HTMLElement;

  const summary = 'Bar chart showing work packages which are 3 New; 1 In progress; 2 Closed.';

  const i18nStub = {
    locale: 'en',
    t(key:string, options:Record<string, string|number> = {}) {
      const translations:Record<string, string> = {
        'js.chart.description.caption': `${options.label}: data`,
        'js.sprint_work_package_graph.chart_label': 'Work packages by status chart',
        'js.sprint_work_package_graph.status_column': 'Status',
        'js.sprint_work_package_graph.count_column': 'Work packages',
      };

      return translations[key] ?? key;
    },
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SprintWorkPackageGraphComponent],
      providers: [{ provide: I18nService, useValue: i18nStub }],
    }).compileComponents();

    fixture = TestBed.createComponent(SprintWorkPackageGraphComponent);
    element = fixture.nativeElement as HTMLElement;

    fixture.componentRef.setInput('chartData', JSON.stringify({
      labels: ['New', 'In progress', 'Closed'],
      data: [3, 1, 2],
      colors: ['#1A67A3', '#FFA500', null],
      summary,
    }));
    fixture.detectChanges();
  });

  const options = () => fixture.componentInstance.barChartOptions;

  it('renders the chart', () => {
    expect(element.querySelector('canvas')).not.toBeNull();
  });

  it('charts one bar per status in the order they arrive', () => {
    const { labels, datasets } = fixture.componentInstance.barChartData();

    expect(labels).toEqual(['New', 'In progress', 'Closed']);
    expect(datasets).toHaveLength(1);
    expect(datasets[0].data).toEqual([3, 1, 2]);
  });

  it('leaves out the legend, which a single unlabeled dataset has nothing to say in', () => {
    expect(options().plugins!.legend!.display).toBe(false);
  });

  it('outlines each bar in its status color and fills it with the muted variant', () => {
    const [dataset] = fixture.componentInstance.barChartData().datasets;

    expect(dataset.borderColor).toEqual(['#1A67A3', '#FFA500', '#59636e']);
    expect(dataset.backgroundColor).toEqual([
      'rgba(26, 103, 163, 0.5)',
      'rgba(255, 165, 0, 0.5)',
      'rgba(89, 99, 110, 0.5)',
    ]);
  });

  it('keeps the Primer palette from painting over the status colors', () => {
    expect(options().plugins!['primer-colors']).toEqual({ enabled: false });
  });

  it('counts in whole work packages', () => {
    expect(options().scales!.y).toEqual(expect.objectContaining({ beginAtZero: true }));
    expect(options().scales!.y!.ticks).toEqual(expect.objectContaining({ precision: 0 }));
  });

  describe('accessibility', () => {
    it('names the chart and uses the server summary as its description', () => {
      expect(within(element).getByRole('img', { name: 'Work packages by status chart', description: summary }))
        .toBeInTheDocument();
    });

    it('tabulates one row per status', () => {
      const table = within(element).getByRole('table', { name: 'Work packages by status chart: data' });

      expect(tableColumns(table)).toEqual(['Status', 'Work packages']);
      expect(tableRows(table)).toEqual([
        ['New', '3'],
        ['In progress', '1'],
        ['Closed', '2'],
      ]);
    });
  });

  describe('as a custom element', () => {
    const payload = JSON.stringify({ labels: ['New'], data: [3], colors: ['#1A67A3'], summary: 'Summary' });
    let custom:TestCustomElement;

    afterEach(() => custom.element.remove());

    it('renders the chart from the chart-data attribute', async () => {
      custom = await defineTestCustomElement(SprintWorkPackageGraphComponent, { 'chart-data': payload });

      expect(custom.element.querySelector('canvas')).not.toBeNull();
      expect(tableRows(within(custom.element).getByRole('table'))).toEqual([['New', '3']]);
    });

    it('falls back to empty data once the chart-data attribute is removed', async () => {
      custom = await defineTestCustomElement(SprintWorkPackageGraphComponent, { 'chart-data': payload });

      await custom.remove('chart-data');

      expect(tableRows(within(custom.element).getByRole('table'))).toEqual([]);
    });

    it('renders the empty state without the attribute', async () => {
      custom = await defineTestCustomElement(SprintWorkPackageGraphComponent, {});

      expect(tableRows(within(custom.element).getByRole('table'))).toEqual([]);
    });
  });
});
