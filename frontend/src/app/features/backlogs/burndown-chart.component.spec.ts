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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BurndownChartComponent } from 'core-app/features/backlogs/burndown-chart.component';

describe('BurndownChartComponent', () => {
  let fixture:ComponentFixture<BurndownChartComponent>;
  let element:HTMLElement;

  const i18nStub = {
    locale: 'en',
    t(key:string, options:Record<string, string|number> = {}) {
      const translations:Record<string, string> = {
        'js.burndown.chart_day': `Day ${options.day}: ${options.values}`,
        'js.burndown.chart_label': 'Burndown chart',
        'js.burndown.chart_summary': `Burndown chart data: ${options.days}.`,
        'js.burndown.chart_value': `${options.label}: ${options.value}`,
        'js.burndown.day': 'Day',
        'js.burndown.points': 'Points',
      };

      return translations[key] ?? key;
    },
  };

  const chartData = (datasets:unknown[]) => JSON.stringify({
    labels: [['Mon 01/01'], ['Tue 02/01']],
    datasets,
  });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BurndownChartComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BurndownChartComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (datasets:unknown[]) => {
    fixture.componentRef.setInput('chartData', chartData(datasets));
    fixture.detectChanges();
  };

  it('provides a translated name and day-by-day description for the chart', () => {
    renderWith([
      { label: 'Story points', data: [8, 6] },
      { label: 'Story points (ideal)', data: [8, 4] },
    ]);

    const canvas = element.querySelector('canvas')!;
    const descriptionId = canvas.getAttribute('aria-describedby')!;
    const description = element.querySelector<HTMLElement>(`#${descriptionId}`)!;

    expect(canvas.getAttribute('role')).toEqual('img');
    expect(canvas.getAttribute('aria-label')).toEqual('Burndown chart');
    expect(description.hidden).toBe(true);
    expect(description.textContent?.trim()).toEqual(
      'Burndown chart data: Day 1: Story points: 8, Story points (ideal): 8; Day 2: Story points: 6, Story points (ideal): 4.',
    );
    expect(canvas.textContent?.trim()).toEqual(description.textContent?.trim());
  });

  it('uses a unique description ID for each chart', () => {
    renderWith([{ label: 'Story points', data: [8, 6] }]);
    const secondFixture = TestBed.createComponent(BurndownChartComponent);
    const secondElement = secondFixture.nativeElement as HTMLElement;

    secondFixture.componentRef.setInput('chartData', chartData([{ label: 'Story points', data: [5, 3] }]));
    secondFixture.detectChanges();

    const firstDescriptionId = element.querySelector('canvas')!.getAttribute('aria-describedby');
    const secondDescriptionId = secondElement.querySelector('canvas')!.getAttribute('aria-describedby');

    expect(firstDescriptionId).toEqual(fixture.componentInstance.chartDescriptionId);
    expect(secondDescriptionId).toEqual(secondFixture.componentInstance.chartDescriptionId);
    expect(firstDescriptionId).not.toEqual(secondDescriptionId);
  });

  it('does not render chart semantics without data', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(element.querySelector(`#${fixture.componentInstance.chartDescriptionId}`)).toBeNull();
  });
});
