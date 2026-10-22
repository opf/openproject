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
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { BurndownChartComponent } from 'core-app/features/backlogs/burndown-chart.component';

describe('BurndownChartComponent', () => {
  let fixture:ComponentFixture<BurndownChartComponent>;
  let element:HTMLElement;
  let zone:string;

  const i18nStub = {
    locale: 'en',
    t(key:string, options:Record<string, string|number> = {}) {
      const translations:Record<string, string> = {
        'js.burndown_chart.chart_day': `Day ${options.day}: ${options.values}`,
        'js.burndown_chart.chart_label': 'Burndown chart',
        'js.burndown_chart.chart_summary': `Burndown chart data: ${options.days}.`,
        'js.burndown_chart.chart_value': `${options.label}: ${options.value}`,
      };

      return translations[key] ?? key;
    },
  };

  // Only what the chart asks of it. The zone decides which day a point falls on, so each example
  // sets it rather than it being fixed here.
  const timezoneStub = {
    userTimezone: () => zone,
    formattedDate: (iso:string) => iso,
    formattedDatetime: (iso:string) => iso,
  };

  const chartData = (series:unknown[]) => JSON.stringify({
    step: 'hour',
    series,
    nonWorkingIntervals: [],
  });

  const point = (x:string, y:number) => ({ x, y });

  beforeEach(async () => {
    zone = 'UTC';

    await TestBed.configureTestingModule({
      imports: [BurndownChartComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        { provide: TimezoneService, useValue: timezoneStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BurndownChartComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (series:unknown[]) => {
    fixture.componentRef.setInput('chartData', chartData(series));
    fixture.detectChanges();
  };

  const describedBy = (host:HTMLElement) => {
    const id = host.querySelector('canvas')!.getAttribute('aria-describedby')!;

    return host.querySelector<HTMLElement>(`#${id}`)!;
  };

  // Remaining is sampled hourly and the guideline once a day, so a day holds several values of the
  // one and a single value of the other. Each is reported by what it closed the day at.
  it('describes each day by the value its series closed at', () => {
    renderWith([
      {
        id: 'remaining',
        label: 'Story points',
        data: [
          point('2026-10-12T09:00:00.000Z', 8),
          point('2026-10-12T14:00:00.000Z', 7),
          point('2026-10-12T23:59:59.999Z', 5),
          point('2026-10-13T12:00:00.000Z', 3),
        ],
      },
      {
        id: 'guideline',
        label: 'Guideline',
        data: [
          point('2026-10-12T23:59:59.999Z', 6),
          point('2026-10-13T23:59:59.999Z', 4),
        ],
      },
    ]);

    const canvas = element.querySelector('canvas')!;
    const description = describedBy(element);

    expect(canvas).toHaveAttribute('role', 'img');
    expect(canvas).toHaveAccessibleName('Burndown chart');
    expect(canvas).toContainElement(description);
    expect(description).toHaveTextContent(
      'Burndown chart data: Day 1: Story points: 5, Guideline: 6; Day 2: Story points: 3, Guideline: 4.',
    );
    expect(canvas).toHaveAccessibleDescription(description.textContent.trim());
    expect(element.textContent.split(description.textContent.trim())).toHaveLength(2);
  });

  it('omits a series from a day it has no value on', () => {
    renderWith([
      { id: 'remaining', label: 'Story points', data: [point('2026-10-12T23:59:59.999Z', 8)] },
      {
        id: 'guideline',
        label: 'Guideline',
        data: [point('2026-10-12T23:59:59.999Z', 8), point('2026-10-13T23:59:59.999Z', 4)],
      },
    ]);

    expect(describedBy(element)).toHaveTextContent(
      'Burndown chart data: Day 1: Story points: 8, Guideline: 8; Day 2: Guideline: 4.',
    );
  });

  // The days are the reader's rather than UTC's: east of UTC these two instants fall either side
  // of a local midnight, so they are two days and not one.
  it('groups days in the viewer time zone', () => {
    zone = 'Asia/Kolkata';

    renderWith([
      {
        id: 'remaining',
        label: 'Story points',
        data: [point('2026-10-12T10:00:00.000Z', 8), point('2026-10-12T20:00:00.000Z', 5)],
      },
    ]);

    expect(describedBy(element)).toHaveTextContent(
      'Burndown chart data: Day 1: Story points: 8; Day 2: Story points: 5.',
    );
  });

  it('uses a unique description ID for each chart', () => {
    renderWith([{ id: 'remaining', label: 'Story points', data: [point('2026-10-12T23:59:59.999Z', 8)] }]);

    const secondFixture = TestBed.createComponent(BurndownChartComponent);
    const secondElement = secondFixture.nativeElement as HTMLElement;

    secondFixture.componentRef.setInput(
      'chartData',
      chartData([{ id: 'remaining', label: 'Story points', data: [point('2026-10-12T23:59:59.999Z', 5)] }]),
    );
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
