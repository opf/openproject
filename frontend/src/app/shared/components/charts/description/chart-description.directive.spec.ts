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

import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { within } from '@testing-library/dom';
import { ChartDescription } from 'core-app/shared/components/charts/description/chart-description';
import { ChartDescriptionDirective } from 'core-app/shared/components/charts/description/chart-description.directive';
import { tableColumns, tableRows } from 'core-app/shared/components/charts/description/testing/chart-description-table';

const burndown:ChartDescription = {
  label: 'Burndown chart',
  summary: '3 Nov – 14 Nov.',
  table: {
    caption: 'Burndown chart: data',
    columns: ['Date', 'Remaining', 'Guideline'],
    rows: [
      { header: '11/03/2026', cells: ['40', '40'] },
      { header: '11/04/2026', cells: ['', '36'] },
    ],
  },
};

const burnup:ChartDescription = {
  ...burndown,
  label: 'Burnup chart',
  summary: '3 Nov – 14 Nov. Completed: 12.',
  table: { ...burndown.table, caption: 'Burnup chart: data' },
};

@Component({
  template: `
    <div style="position: relative">
      <canvas [opChartDescription]="first()" style="display: block; height: 100px"></canvas>
    </div>
    <canvas [opChartDescription]="second()"></canvas>
  `,
  imports: [ChartDescriptionDirective],
})
class HostComponent {
  readonly first = signal(burndown);
  readonly second = signal(burnup);
}

describe('ChartDescriptionDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let view:ReturnType<typeof within>;

  beforeEach(() => {
    fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    view = within(fixture.nativeElement as HTMLElement);
  });

  it('exposes the chart as an image named by its label and described by its summary', () => {
    expect(view.getByRole('img', { name: 'Burndown chart', description: '3 Nov – 14 Nov.' })).toBeInTheDocument();
  });

  it('renders a captioned data table after the chart', () => {
    const chart = view.getByRole('img', { name: 'Burndown chart' });
    const table = view.getByRole('table', { name: 'Burndown chart: data' });

    expect(tableColumns(table)).toEqual(['Date', 'Remaining', 'Guideline']);
    expect(tableRows(table).map(([header]) => header)).toEqual(['11/03/2026', '11/04/2026']);
    expect(table).toAppearAfter(chart);
  });

  it('renders an empty cell as empty', () => {
    const table = view.getByRole('table', { name: 'Burndown chart: data' });
    expect(tableRows(table)[1]).toEqual(['11/04/2026', '', '36']);
  });

  it('hides the description visually as a single box', () => {
    const table = view.getByRole('table', { name: 'Burndown chart: data' });
    const summary = view.getByText('3 Nov – 14 Nov.', { selector: 'p' });

    expect(table.closest('op-chart-description-content')).toHaveClass('sr-only');
    expect(table).not.toHaveClass('sr-only');
    expect(summary).not.toHaveClass('sr-only');
  });

  it('pins the description to the top-left of the chart container', () => {
    const host = view.getByRole('table', { name: 'Burndown chart: data' }).closest('op-chart-description-content');

    expect(host).toHaveStyle('inset-block-start: 0px; inset-inline-start: 0px');
  });

  it('does not point aria-describedby at the table', () => {
    const chart = view.getByRole('img', { name: 'Burndown chart' });
    const summary = view.getByText('3 Nov – 14 Nov.', { selector: 'p' });

    expect(chart).toHaveAttribute('aria-describedby', summary.id);
    expect(chart).toHaveAccessibleDescription('3 Nov – 14 Nov.');
  });

  it('gives each instance its own summary id', () => {
    const first = view.getByRole('img', { name: 'Burndown chart' });
    const second = view.getByRole('img', { name: 'Burnup chart' });

    expect(first.getAttribute('aria-describedby')).not.toEqual(second.getAttribute('aria-describedby'));
    expect(second).toHaveAccessibleDescription('3 Nov – 14 Nov. Completed: 12.');
  });

  it('re-renders the table when the description changes', () => {
    fixture.componentInstance.first.set({
      ...burndown,
      label: 'Burndown chart (updated)',
      summary: '5 Nov.',
      table: { ...burndown.table, rows: [{ header: '11/05/2026', cells: ['30', '32'] }] },
    });
    fixture.detectChanges();

    const table = view.getByRole('table', { name: 'Burndown chart: data' });

    expect(view.getByRole('img', { name: 'Burndown chart (updated)', description: '5 Nov.' })).toBeInTheDocument();
    expect(tableRows(table)).toEqual([['11/05/2026', '30', '32']]);
  });
});
