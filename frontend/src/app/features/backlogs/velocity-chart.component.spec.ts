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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { VelocityChartComponent } from './velocity-chart.component';
import AverageLinePlugin from './plugin.average-line';

describe('VelocityChartComponent', () => {
  let fixture:ComponentFixture<VelocityChartComponent>;
  let element:HTMLElement;

  const cssVariables = {
    '--display-blue-scale-2': '#bbddff',
    '--display-blue-scale-6': '#0055aa',
    '--display-green-scale-2': '#bbeecc',
    '--display-green-scale-6': '#118833',
    '--fgColor-muted': '#666666',
  };

  beforeEach(async () => {
    Object.entries(cssVariables).forEach(([name, value]) => document.body.style.setProperty(name, value));

    await TestBed.configureTestingModule({
      imports: [VelocityChartComponent],
      providers: [{ provide: I18nService, useValue: { locale: 'de' } }],
    }).compileComponents();

    fixture = TestBed.createComponent(VelocityChartComponent);
    element = fixture.nativeElement as HTMLElement;

    fixture.componentRef.setInput('chartData', JSON.stringify({
      labels: ['Sprint 1', 'A sprint with a very long name'],
      datasets: [
        { label: 'Committed', data: [21, 13] },
        { label: 'Completed', data: [20, 9] },
      ],
      average: 14.5,
      yAxisTitle: 'Story points',
    }));
    fixture.detectChanges();
  });

  afterEach(() => {
    Object.keys(cssVariables).forEach((name) => document.body.style.removeProperty(name));
  });

  const options = () => fixture.componentInstance.barChartOptions();

  it('renders the chart', () => {
    expect(element.querySelector('canvas')).not.toBeNull();
  });

  it('colors committed blue and completed green', () => {
    const [committed, completed] = fixture.componentInstance.barChartData().datasets;

    expect(committed).toEqual(expect.objectContaining({
      label: 'Committed',
      data: [21, 13],
      backgroundColor: '#bbddff',
      borderColor: '#0055aa',
      borderWidth: 1,
    }));
    expect(completed).toEqual(expect.objectContaining({
      label: 'Completed',
      data: [20, 9],
      backgroundColor: '#bbeecc',
      borderColor: '#118833',
    }));
  });

  it('keeps the global Primer colors plugin from overriding the dataset colors', () => {
    expect(options().plugins!['primer-colors']).toEqual({ enabled: false });
  });

  it('registers the average line plugin', () => {
    expect(fixture.componentInstance.plugins).toContain(AverageLinePlugin);
  });

  it('configures the average line with a locale-formatted label', () => {
    expect(options().plugins!.averageLine).toEqual({ value: 14.5, label: '14,5', color: '#666666' });
  });

  it('titles the y axis', () => {
    const yScale = options().scales!.y as { title:{ display:boolean, text:string } };

    expect(yScale.title).toEqual(expect.objectContaining({ display: true, text: 'Story points' }));
  });

  describe('x axis labels', () => {
    const tickLabel = (label:string) => {
      const callback = options().scales!.x!.ticks!.callback as unknown as
        (this:{ getLabelForValue:(value:number) => string }, value:number) => string;

      return callback.call({ getLabelForValue: () => label }, 0);
    };

    it('keeps short sprint names', () => {
      expect(tickLabel('Sprint 1')).toBe('Sprint 1');
    });

    it('keeps names of exactly the maximum length', () => {
      expect(tickLabel('Fifteen chars!!')).toBe('Fifteen chars!!');
    });

    it('truncates long sprint names with an ellipsis', () => {
      expect(tickLabel('A sprint with a very long name')).toBe('A sprint with…');
    });
  });
});
