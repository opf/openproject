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
import { SprintWorkPackageGraphComponent } from './sprint-work-package-graph.component';

describe('SprintWorkPackageGraphComponent', () => {
  let fixture:ComponentFixture<SprintWorkPackageGraphComponent>;
  let element:HTMLElement;

  const summary = 'Bar chart showing work packages which are 3 New; 1 In progress; 2 Closed.';

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SprintWorkPackageGraphComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(SprintWorkPackageGraphComponent);
    element = fixture.nativeElement as HTMLElement;

    fixture.componentRef.setInput('chartData', JSON.stringify({
      labels: ['New', 'In progress', 'Closed'],
      data: [3, 1, 2],
      colors: ['#1A67A3', '#FFA500', null],
      summary,
      statusColumnTitle: 'Status',
      countColumnTitle: 'Work packages',
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
    const canvas = () => element.querySelector('canvas')!;
    const referenced = (attribute:string) => document.getElementById(canvas().getAttribute(attribute)!)!;

    it('exposes the canvas as an image named by the summary', () => {
      expect(canvas()).toHaveRole('img');
      expect(referenced('aria-labelledby')).toHaveTextContent(summary);
    });

    it('describes the canvas with a data table of all statuses', () => {
      const table = referenced('aria-describedby');
      const rows = Array.from(table.querySelectorAll('tr'))
        .map((row) => Array.from(row.children).map((cell) => cell.textContent.trim()));

      expect(table.tagName).toBe('TABLE');
      expect(rows).toEqual([
        ['Status', 'Work packages'],
        ['New', '3'],
        ['In progress', '1'],
        ['Closed', '2'],
      ]);
    });

    it('marks up the table headers for screen readers', () => {
      const table = referenced('aria-describedby');

      expect(Array.from(table.querySelectorAll('thead th')).map((th) => th.getAttribute('scope')))
        .toEqual(['col', 'col']);
      expect(Array.from(table.querySelectorAll('tbody th')).map((th) => th.getAttribute('scope')))
        .toEqual(['row', 'row', 'row']);
    });

    it('hides the summary and table visually', () => {
      expect(referenced('aria-labelledby')).toHaveClass('sr-only');
      expect(referenced('aria-describedby')).toHaveClass('sr-only');
    });

    it('gives every chart instance its own ids', () => {
      const other = TestBed.createComponent(SprintWorkPackageGraphComponent);
      other.componentRef.setInput('chartData', fixture.componentRef.instance.chartData());
      other.detectChanges();

      const otherCanvas = (other.nativeElement as HTMLElement).querySelector('canvas')!;
      expect(otherCanvas).not.toHaveAttribute('aria-labelledby', canvas().getAttribute('aria-labelledby'));
      expect(otherCanvas).not.toHaveAttribute('aria-describedby', canvas().getAttribute('aria-describedby'));
    });
  });
});
