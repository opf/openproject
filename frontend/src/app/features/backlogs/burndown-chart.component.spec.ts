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
import { within } from '@testing-library/dom';
import { tableColumns, tableRows } from 'core-app/shared/components/charts/description/testing/chart-description-table';
import { CartesianScaleOptions } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { BurndownChartComponent } from 'core-app/features/backlogs/burndown-chart.component';
import { defineTestCustomElement, TestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

let zone:string;

const i18nStub = {
  locale: 'en',
  t(key:string, options:Record<string, string|number> = {}) {
    const translations:Record<string, string> = {
      'js.burndown_chart.chart_label': 'Burndown chart',
      'js.chart.description.caption': `${options.label}: data`,
      'js.chart.description.date': 'Date',
      'js.chart.description.week': 'Week of',
      'js.sprint_charts.description_summary': `${options.label} data: ${options.from} – ${options.to}. ${options.values}.`,
      'js.sprint_charts.column_with_unit': `${options.label} (${options.unit})`,
      'js.sprint_charts.description_value': `${options.label}: ${options.value}`,
      'js.sprint_charts.unit.story_points': 'story points',
      'js.sprint_charts.value_with_unit.story_points': `${options.value} story point${options.count === 1 ? '' : 's'}`,
      'js.sprint_charts.y_axis_title.story_points': 'Story points',
      'js.sprint_charts.y_axis_title.time': 'Estimated time',
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
  durationFormat: () => 'hours_only',
  hoursPerDay: () => 8,
  daysPerMonth: () => 20,
};

const configureTestingModule = () => TestBed.configureTestingModule({
  imports: [BurndownChartComponent],
  providers: [
    { provide: I18nService, useValue: i18nStub },
    { provide: ConfigurationService, useValue: configurationStub },
    TimezoneService,
  ],
}).compileComponents();

describe('BurndownChartComponent', () => {
  let fixture:ComponentFixture<BurndownChartComponent>;
  let element:HTMLElement;

  // The window is the server's, not the series' extent, so it is stated rather than derived.
  const chartData = (
    series:unknown[],
    step:'day'|'hour' = 'hour',
    nonWorkingIntervals:unknown[] = [],
    unit:'story_points'|'time' = 'story_points',
  ) => JSON.stringify({
    unit,
    step,
    range: { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' },
    series,
    nonWorkingIntervals,
  });

  const point = (x:string, y:number) => ({ x, y });

  beforeEach(async () => {
    zone = 'UTC';

    await configureTestingModule();

    fixture = TestBed.createComponent(BurndownChartComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (
    series:unknown[],
    step:'day'|'hour' = 'hour',
    nonWorkingIntervals:unknown[] = [],
    unit:'story_points'|'time' = 'story_points',
  ) => {
    fixture.componentRef.setInput('chartData', chartData(series, step, nonWorkingIntervals, unit));
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

  const yAxisTitle = () => (fixture.componentInstance.lineChartOptions().scales!.y as CartesianScaleOptions).title.text;

  const describedTable = () => within(element).getByRole('table');

  // Remaining is sampled hourly and the guideline once a day, so a day holds several values of the
  // one and a single value of the other. Each is reported by what it closed the day at.
  const sampledSeries = () => [
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
  ];

  it('names the chart and summarizes the range and latest values', () => {
    renderWith(sampledSeries());

    expect(within(element).getByRole('img', {
      name: 'Burndown chart',
      description: 'Burndown chart data: 10/12/2026 – 10/23/2026. Story points: 3, Guideline: 4 story points.',
    })).toBeInTheDocument();
  });

  it('tabulates one row per day by the value each series closed at', () => {
    renderWith(sampledSeries());

    const table = within(element).getByRole('table', { name: 'Burndown chart: data' });

    expect(tableColumns(table)).toEqual(['Date', 'Story points', 'Guideline (story points)']);
    expect(tableRows(table)).toEqual([
      ['10/12/2026', '5', '6'],
      ['10/13/2026', '3', '4'],
    ]);
  });

  it('orders the table columns the way the legend reads', () => {
    renderWith([
      ...sampledSeries(),
      { id: 'projection', label: 'Projection', data: [point('2026-10-13T12:00:00.000Z', 3)] },
    ]);

    expect(tableColumns(describedTable())).toEqual(['Date', 'Story points', 'Projection', 'Guideline (story points)']);
  });

  // Havana repeats 00:00 on 2026-11-01, so the first two points share a local date.
  it('keeps a repeated local midnight in one row', () => {
    zone = 'America/Havana';

    renderWith([{
      id: 'remaining',
      label: 'Story points',
      data: [
        point('2026-11-01T04:59:59.999Z', 8),
        point('2026-11-01T05:59:59.999Z', 7),
        point('2026-11-01T17:00:00.000Z', 3),
      ],
    }]);

    expect(tableRows(describedTable())).toEqual([['11/01/2026', '3']]);
  });

  it("names each day in the viewer's zone west of UTC", () => {
    zone = 'America/New_York';

    renderWith([{ id: 'remaining', label: 'Story points', data: [point('2026-11-02T03:00:00.000Z', 5)] }]);

    expect(tableRows(describedTable())).toEqual([['11/01/2026', '5']]);
  });

  it('leaves a cell empty for a period a series has no value in', () => {
    renderWith([
      { id: 'remaining', label: 'Story points', data: [point('2026-10-12T23:59:59.999Z', 8)] },
      {
        id: 'guideline',
        label: 'Guideline',
        data: [point('2026-10-12T23:59:59.999Z', 8), point('2026-10-13T23:59:59.999Z', 4)],
      },
    ]);

    expect(tableRows(describedTable())).toEqual([
      ['10/12/2026', '8', '8'],
      ['10/13/2026', '', '4'],
    ]);
  });

  // The days are the reader's rather than UTC's: east of UTC these two instants fall either side
  // of a local midnight, so they are two days and not one.
  it('buckets periods in the OpenProject zone', () => {
    zone = 'Asia/Kolkata';

    renderWith([
      {
        id: 'remaining',
        label: 'Story points',
        data: [point('2026-10-12T10:00:00.000Z', 8), point('2026-10-12T20:00:00.000Z', 5)],
      },
    ]);

    expect(tableRows(describedTable())).toEqual([
      ['10/12/2026', '8'],
      ['10/13/2026', '5'],
    ]);
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

  // The lines that carry no background do not fill, and remaining still does.
  it('fills the remaining area down to the axis and nothing else', () => {
    renderWith([
      { id: 'remaining', label: 'Story points', data: [point('2026-10-12T09:00:00.000Z', 8)] },
      { id: 'guideline', label: 'Guideline', data: [point('2026-10-12T23:59:59.999Z', 6)] },
    ]);

    expect(fixture.componentInstance.lineChartData().datasets.map((dataset) => dataset.fill))
      .toEqual([true, false]);
  });

  it('adds a point-less series so the non-working days get a legend entry that toggles them', () => {
    renderWith(seriesWithAPointAt('2026-10-12T09:00:00.000Z'), 'hour', [{ from: '2026-10-17', to: '2026-10-18' }]);

    const standIn = fixture.componentInstance.lineChartData().datasets[1];

    expect(standIn.data).toEqual([]);
    expect(standIn.label).toEqual('js.sprint_charts.non_working_day');
  });

  it('leaves the non-working stand-in out when there are no bands to paint', () => {
    renderWith(seriesWithAPointAt('2026-10-12T09:00:00.000Z'));

    expect(fixture.componentInstance.lineChartData().datasets).toHaveLength(1);
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

  it('titles the y axis in story points', () => {
    renderWith(seriesWithAPointAt('2026-10-12T09:00:00.000Z'));

    expect(yAxisTitle()).toEqual('Story points');
  });

  describe('in estimated time', () => {
    beforeEach(() => {
      renderWith([
        {
          id: 'remaining',
          label: 'Remaining estimated time',
          data: [point('2026-10-12T09:00:00.000Z', 21.25), point('2026-10-12T23:59:59.999Z', 20)],
        },
      ], 'hour', [], 'time');
    });

    it('titles the y axis in estimated time', () => {
      expect(yAxisTitle()).toEqual('Estimated time');
    });

    it('labels the axis in multiples of a working day', () => {
      const labels = renderedYAxisLabels();

      expect(labels.length).toBeGreaterThan(1);
      expect(labels.filter((label) => label % 8 !== 0)).toEqual([]);
    });

    it('formats the axis labels as durations', () => {
      const formatYTick = fixture.componentInstance.lineChartOptions().scales!.y!.ticks!.callback as unknown as (value:number) => string;

      expect(formatYTick(16)).toEqual('16h');
    });

    it('formats the tooltip values as durations', () => {
      const formatLabel = fixture.componentInstance.lineChartOptions().plugins!.tooltip!.callbacks!.label as unknown as (item:object) => string;

      expect(formatLabel({ dataset: { label: 'Remaining estimated time' }, parsed: { y: 21.25 } }))
        .toEqual('Remaining estimated time: 21.25h');
    });

    it('tabulates durations in estimated time', () => {
      expect(tableRows(describedTable())).toEqual([['10/12/2026', '20h']]);
    });
  });

  it('does not render chart semantics without data', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(within(element).queryByRole('img')).not.toBeInTheDocument();
    expect(within(element).queryByRole('table')).not.toBeInTheDocument();
  });
});

describe('BurndownChartComponent as a custom element', () => {
  const payload = JSON.stringify({
    step: 'hour',
    range: { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' },
    series: [
      { id: 'remaining', label: 'Story points', data: [{ x: '2026-10-12T23:59:59.999Z', y: 5 }] },
      { id: 'guideline', label: 'Guideline', data: [{ x: '2026-10-12T23:59:59.999Z', y: 6 }] },
    ],
  });
  let custom:TestCustomElement;

  beforeEach(async () => {
    zone = 'UTC';
    await configureTestingModule();
  });

  afterEach(() => custom.element.remove());

  it('renders the chart from the chart-data attribute', async () => {
    custom = await defineTestCustomElement(BurndownChartComponent, { 'chart-data': payload });

    expect(custom.element.querySelector('canvas')).not.toBeNull();
    expect(tableRows(within(custom.element).getByRole('table'))[0]).toEqual(['10/12/2026', '5', '6']);
  });

  it('falls back to empty data once the chart-data attribute is removed', async () => {
    custom = await defineTestCustomElement(BurndownChartComponent, { 'chart-data': payload });

    await custom.remove('chart-data');

    expect(custom.element.querySelector('canvas')).toBeNull();
  });

  it('renders the empty state without the attribute', async () => {
    custom = await defineTestCustomElement(BurndownChartComponent, {});

    expect(custom.element.querySelector('canvas')).toBeNull();
  });
});
