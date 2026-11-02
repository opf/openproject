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
import { By } from '@angular/platform-browser';
import { BaseChartDirective } from 'ng2-charts';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
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

  // The real TimezoneService, stubbed only at its configuration, so that these examples exercise
  // the zone conversion rather than a stand-in for it. The zone decides which day a point falls
  // on, so each example sets it rather than it being fixed here.
  const configurationStub = {
    isTimezoneSet: () => true,
    timezone: () => zone,
    dateFormatPresent: () => true,
    dateFormat: () => 'MM/DD/YYYY',
    timeFormatPresent: () => true,
    timeFormat: () => 'hh:mm A',
  };

  // The window is the server's, not the series' extent, so it is stated rather than derived.
  const chartData = (series:unknown[], step:'day'|'hour' = 'hour') => JSON.stringify({
    step,
    range: { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' },
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
        { provide: ConfigurationService, useValue: configurationStub },
        TimezoneService,
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BurndownChartComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (series:unknown[], step:'day'|'hour' = 'hour') => {
    fixture.componentRef.setInput('chartData', chartData(series, step));
    fixture.detectChanges();
  };

  const seriesWithAPointAt = (iso:string) => [
    { id: 'remaining', label: 'Story points', data: [{ x: iso, y: 8 }] },
  ];

  // Both are what chart.js itself calls to put words on the axis and in the tooltip.
  const axisLabelAt = (timestamp:number):string => {
    const { scales } = fixture.componentInstance.lineChartOptions();
    const callback = scales?.x?.ticks?.callback as unknown as (value:number) => string;

    return callback(timestamp);
  };

  const tooltipTitleAt = (timestamp:number):string => {
    const { plugins } = fixture.componentInstance.lineChartOptions();
    const title = plugins?.tooltip?.callbacks?.title as unknown as
      (items:{ datasetIndex:number, parsed:{ x:number } }[]) => string;

    return title([{ datasetIndex: 0, parsed: { x: timestamp } }]);
  };

  // What chart.js put on the axis, rather than what it was asked for. ng2-charts builds the chart
  // on an input change that follows its own ngOnInit, which one round of change detection does not
  // reach, so it is asked to build it here.
  const renderedYAxisLabels = () => {
    const directive = fixture.debugElement.query(By.directive(BaseChartDirective))
      .injector.get(BaseChartDirective);

    return directive.render()!.scales.y.ticks.map((tick) => tick.value);
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

  // Story points are whole, so the axis is labeled in whole ones -- a sprint holding a single
  // point was otherwise drawn against fifths of one. The guideline divides those points across
  // working days and does carry fractions, but it is a line between the labels rather than one
  // of them, so it is left to the tooltip to report its decimal.
  it('labels the axis in whole story points', () => {
    renderWith([
      { id: 'remaining', label: 'Story points', data: [point('2026-10-12T09:00:00.000Z', 1)] },
      {
        id: 'guideline',
        label: 'Guideline',
        data: [point('2026-10-12T23:59:59.999Z', 0.6), point('2026-10-13T23:59:59.999Z', 0.2)],
      },
    ]);

    const labels = renderedYAxisLabels();

    expect(labels.length).toBeGreaterThan(1);
    expect(labels.filter((label) => !Number.isInteger(label))).toEqual([]);
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

  // The axis places points using the OpenProject zone, so everything naming those points has to
  // use it too. Where it did not, labels slid against the data for anyone whose browser zone
  // differed -- a point drawn at one gridline but named for another.
  describe('naming instants when the browser zone differs', () => {
    // 18:30Z is the following midnight in Kolkata, and the day before it in UTC.
    const dayEndInKolkata = Date.parse('2026-10-16T18:29:59.999Z');
    const midnightInKolkata = Date.parse('2026-10-16T18:30:00.000Z');

    beforeEach(() => {
      zone = 'Asia/Kolkata';
    });

    it('labels the axis in the OpenProject zone', () => {
      renderWith(seriesWithAPointAt('2026-10-16T18:30:00.000Z'));

      expect(axisLabelAt(midnightInKolkata)).toEqual('10/17/2026');
    });

    it('names an hourly tick in the OpenProject zone, rounded to the hour it closes', () => {
      renderWith(seriesWithAPointAt('2026-10-16T18:29:59.999Z'));

      expect(tooltipTitleAt(dayEndInKolkata)).toEqual('10/17/2026 12:00 AM');
    });

    // Dated in that zone, which west of Kolkata is still the day before -- so this says nothing
    // unless the conversion happens.
    it('names a daily tick by its date in the OpenProject zone', () => {
      const justPastMidnightInKolkata = Date.parse('2026-10-16T19:00:00.000Z');

      renderWith(seriesWithAPointAt('2026-10-16T19:00:00.000Z'), 'day');

      expect(tooltipTitleAt(justPastMidnightInKolkata)).toEqual('10/17/2026');
    });
  });

  // A tick sits at the close of the period it carries, which the axis draws on the next gridline
  // -- a millisecond is less than a pixel. Naming it for the period it covered instead put every
  // daily point one gridline away from its own tooltip.
  describe('naming a tick for the boundary it is drawn on', () => {
    const dayEnd = '2026-10-16T23:59:59.999Z';
    const hourEnd = '2026-10-16T09:59:59.999Z';

    it('names a day end as the date that follows it', () => {
      renderWith(seriesWithAPointAt(dayEnd), 'day');

      expect(tooltipTitleAt(Date.parse(dayEnd))).toEqual('10/17/2026');
    });

    it('names an hour end as the hour it opens', () => {
      renderWith(seriesWithAPointAt(hourEnd));

      expect(tooltipTitleAt(Date.parse(hourEnd))).toEqual('10/16/2026 10:00 AM');
    });

    // The interval's own bounds are exact instants rather than period closes, so the rounding
    // must leave them where they are rather than carrying them to the next day.
    it('leaves an instant that is genuinely mid-day on its own date', () => {
      const sprintStart = '2026-10-16T09:00:00.000Z';

      renderWith(seriesWithAPointAt(sprintStart), 'day');

      expect(tooltipTitleAt(Date.parse(sprintStart))).toEqual('10/16/2026');
    });
  });

  it('does not render chart semantics without data', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(element.querySelector(`#${fixture.componentInstance.chartDescriptionId}`)).toBeNull();
  });
});
