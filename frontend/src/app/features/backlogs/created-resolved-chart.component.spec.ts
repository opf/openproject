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
import { BaseChartDirective } from 'ng2-charts';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CreatedResolvedComponent } from 'core-app/features/backlogs/created-resolved-chart.component';
import { defineTestCustomElement, TestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

let zone:string;
let weekStart:number;

const i18nStub = {
  locale: 'en',
  t(key:string, options:Record<string, string|number> = {}) {
    const translations:Record<string, string> = {
      'js.created_resolved_chart.chart_label': 'Created vs. resolved chart',
      'js.chart.description.caption': `${options.label}: data`,
      'js.chart.description.date': 'Date',
      'js.chart.description.week': 'Week of',
      'js.sprint_charts.description_summary': `${options.label} data: ${options.from} – ${options.to}. ${options.values}.`,
      'js.sprint_charts.description_value': `${options.label}: ${options.value}`,
    };

    return translations[key] ?? key;
  },
};

// The real TimezoneService, stubbed only at its configuration, so that these examples exercise
// the zone conversion rather than a stand-in for it.
const configurationStub = {
  isTimezoneSet: () => true,
  timezone: () => zone,
  dateFormatPresent: () => true,
  dateFormat: () => 'MM/DD/YYYY',
  timeFormatPresent: () => true,
  timeFormat: () => 'hh:mm A',
  startOfWeek: () => weekStart,
};

const configureTestingModule = () => TestBed.configureTestingModule({
  imports: [CreatedResolvedComponent],
  providers: [
    { provide: I18nService, useValue: i18nStub },
    { provide: ConfigurationService, useValue: configurationStub },
    TimezoneService,
  ],
}).compileComponents();

describe('CreatedResolvedComponent', () => {
  let fixture:ComponentFixture<CreatedResolvedComponent>;
  let element:HTMLElement;

  // The window is the server's, not the series' extent, so it is stated rather than derived.
  let range = { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' };

  // Non-working days are not part of this chart's payload, which spans too many sprints for them
  // to read as anything but hatching.
  const chartData = (series:unknown[], step:'day'|'hour' = 'hour') => JSON.stringify({ step, range, series });

  const point = (x:string, y:number) => ({ x, y });

  beforeEach(async () => {
    zone = 'UTC';
    weekStart = 1;
    range = { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' };

    await configureTestingModule();

    fixture = TestBed.createComponent(CreatedResolvedComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (series:unknown[], step:'day'|'hour' = 'hour') => {
    fixture.componentRef.setInput('chartData', chartData(series, step));
    fixture.detectChanges();
  };

  const bothSeries = () => [
    { id: 'created', label: 'Created', data: [point('2026-10-12T09:00:00.000Z', 2)] },
    { id: 'resolved', label: 'Resolved', data: [point('2026-10-12T09:00:00.000Z', 1)] },
  ];

  const paleRed = '#fda5a7';

  const paleGreen = '#b1efc8';

  const datasets = () => fixture.componentInstance.lineChartData().datasets;

  const options = () => fixture.componentInstance.lineChartOptions();

  // What chart.js made of the configuration, rather than what it was asked for. ng2-charts builds
  // the chart on an input change that follows its own ngOnInit, which one round of change
  // detection does not reach, so it is asked to build it here.
  const renderedChart = () => {
    const directive = fixture.debugElement.query(By.directive(BaseChartDirective))
      .injector.get(BaseChartDirective);

    return directive.render()!;
  };

  const renderedYAxisLabels = () => renderedChart().scales.y.ticks.map((tick) => tick.value);

  it('renders a canvas once a series carries points', () => {
    renderWith(bothSeries());

    expect(element.querySelector('canvas')).not.toBeNull();
  });

  const describedTable = () => within(element).getByRole('table');

  it('names the chart', () => {
    renderWith(bothSeries());

    expect(within(element).getByRole('img', { name: 'Created vs. resolved chart' })).toBeInTheDocument();
  });

  // 2026-11-02 and 2026-11-09 are Mondays, the week start the configuration names.
  it('rolls up to weeks beyond 31 days', () => {
    range = { from: '2026-10-01T00:00:00.000Z', to: '2026-11-15T23:59:59.999Z' };

    renderWith([
      {
        id: 'created',
        label: 'Created',
        data: [
          point('2026-11-03T12:00:00.000Z', 2),
          point('2026-11-08T12:00:00.000Z', 5),
          point('2026-11-09T12:00:00.000Z', 6),
        ],
      },
    ]);

    expect(tableColumns(describedTable())).toEqual(['Week of', 'Created']);
    expect(tableRows(describedTable())).toEqual([
      ['11/02/2026', '5'],
      ['11/09/2026', '6'],
    ]);
  });

  it('keeps days at exactly 31 days', () => {
    range = { from: '2026-10-01T00:00:00.000Z', to: '2026-10-31T23:59:59.999Z' };

    renderWith([
      { id: 'created', label: 'Created', data: [point('2026-10-03T12:00:00.000Z', 2)] },
    ]);

    expect(tableColumns(describedTable())).toEqual(['Date', 'Created']);
    expect(tableRows(describedTable())).toEqual([['10/03/2026', '2']]);
  });

  // Berlin leaves summer time inside this October, so the month is an hour longer than 31 days.
  it('keeps days for a 31-day range across a daylight saving change', () => {
    zone = 'Europe/Berlin';
    range = { from: '2026-09-30T22:00:00.000Z', to: '2026-10-31T22:59:59.999Z' };

    renderWith([
      { id: 'created', label: 'Created', data: [point('2026-10-03T12:00:00.000Z', 2)] },
    ]);

    expect(tableColumns(describedTable())).toEqual(['Date', 'Created']);
    expect(tableRows(describedTable())).toEqual([['10/03/2026', '2']]);
  });

  // Havana skips 00:00 on Sunday 2026-03-08 and repeats it on Sunday 2026-11-01.
  it('keeps a week across a skipped local midnight in one row', () => {
    zone = 'America/Havana';
    range = { from: '2026-02-01T05:00:00.000Z', to: '2026-03-31T03:59:59.999Z' };

    renderWith([{
      id: 'created',
      label: 'Created',
      data: [point('2026-03-04T15:00:00.000Z', 2), point('2026-03-08T15:00:00.000Z', 4)],
    }]);

    expect(tableRows(describedTable())).toEqual([['03/02/2026', '4']]);
  });

  it.each([0, 7])('keeps a Sunday week across a repeated local midnight in one row (week start %i)', (sunday) => {
    weekStart = sunday;
    zone = 'America/Havana';
    range = { from: '2026-10-01T04:00:00.000Z', to: '2026-11-30T04:59:59.999Z' };

    renderWith([{
      id: 'created',
      label: 'Created',
      data: [point('2026-11-01T04:59:59.999Z', 8), point('2026-11-01T05:59:59.999Z', 7)],
    }]);

    expect(tableRows(describedTable())).toEqual([['11/01/2026', '7']]);
  });

  it('rolls up a 32-day range starting on a skipped midnight to weeks', () => {
    zone = 'America/Havana';
    range = { from: '2026-03-08T05:00:00.000Z', to: '2026-04-09T03:59:59.999Z' };

    renderWith([{ id: 'created', label: 'Created', data: [point('2026-03-10T12:00:00.000Z', 2)] }]);

    expect(tableColumns(describedTable())).toEqual(['Week of', 'Created']);
  });

  it('shows no results when every series is empty', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
  });

  // The payload drops a series that has no points, so styling by dataset position would color
  // the wrong line as soon as one is absent.
  it('styles a series by its id rather than its position', () => {
    renderWith([bothSeries()[1]]);

    const [resolved] = datasets();

    expect(resolved.label).toEqual('Resolved');
    expect(resolved.order).toEqual(0);
  });

  // A count holds until something changes it, so both series step rather than slope between ticks.
  it('holds each series flat until its next tick', () => {
    renderWith(bothSeries());

    expect(datasets().map((dataset) => dataset.stepped)).toEqual(['after', 'after']);
  });

  // Created paints the band and is therefore drawn first, leaving both lines above it.
  it('draws the banded series underneath the other', () => {
    renderWith(bothSeries());

    expect(datasets().map((dataset) => dataset.order)).toEqual([1, 0]);
  });

  it('fills the band between the two series, red where created leads and green where resolved does', () => {
    renderWith(bothSeries());

    const [created, resolved] = datasets();

    expect(created.fill).toEqual({ target: 1, above: paleRed, below: paleGreen });
    expect(resolved.fill).toBe(false);
  });

  it('draws its own series alone, never a non-working stand-in', () => {
    renderWith(bothSeries());

    expect(datasets().map((dataset) => dataset.label)).toEqual(['Created', 'Resolved']);
  });

  it('bands nothing when the series it would span is absent', () => {
    renderWith([bothSeries()[0]]);

    expect(datasets()[0].fill).toBe(false);
  });

  // Chart.js reads a missing fill off the background color, which would fill resolved down to
  // the axis rather than leaving the band to created.
  it('keeps a lone series from filling to the origin', () => {
    renderWith([bothSeries()[1]]);

    expect(datasets()[0].fill).toBe(false);
  });

  it('keeps each legend swatch in its own color rather than the band\'s', () => {
    renderWith(bothSeries());

    const generateLabels = options().plugins!.legend!.labels!.generateLabels!;

    expect(generateLabels(renderedChart()).map((label) => label.fillStyle)).toEqual([paleRed, paleGreen]);
  });

  // A work package is atomic. A sprint holding one of them used to be drawn against an axis
  // offering 0.2 and 0.4 of it, because chart.js fits its steps to the range it is given.
  it('labels the axis in whole work packages', () => {
    renderWith([
      { id: 'created', label: 'Created', data: [point('2026-10-12T09:00:00.000Z', 1)] },
    ]);

    const labels = renderedYAxisLabels();

    expect(labels.length).toBeGreaterThan(1);
    expect(labels.filter((label) => !Number.isInteger(label))).toEqual([]);
  });

  // Both series are counted at the same ticks, so index matching is correct here and
  // 'series-at-x' would be borrowing the burndown's mechanism without its reason.
  it('matches the two series by index', () => {
    renderWith(bothSeries());

    expect(options().interaction?.mode).toEqual('index');
  });

  // The counted series stop at the current moment while the burndown's guideline beside them
  // runs to the planned finish, so deriving the axis from the points made the two charts span
  // different intervals.
  it('spans the charted window rather than the extent of its own points', () => {
    renderWith(bothSeries());

    const { x } = options().scales ?? {};

    expect(x?.min).toEqual(Date.parse(range.from));
    expect(x?.max).toEqual(Date.parse(range.to));
  });

  it('places the axis in the OpenProject zone, not the browser one', () => {
    zone = 'Asia/Kolkata';
    renderWith(bothSeries());

    const callback = options().scales?.x?.ticks?.callback as unknown as (value:number) => string;

    // 18:30Z is the following midnight in Kolkata.
    expect(callback(Date.parse('2026-10-16T18:30:00.000Z'))).toEqual('10/17/2026');
  });
});

describe('CreatedResolvedComponent as a custom element', () => {
  const payload = JSON.stringify({
    step: 'hour',
    range: { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' },
    series: [
      { id: 'created', label: 'Created', data: [{ x: '2026-10-12T09:00:00.000Z', y: 2 }] },
      { id: 'resolved', label: 'Resolved', data: [{ x: '2026-10-12T09:00:00.000Z', y: 1 }] },
    ],
  });
  let custom:TestCustomElement;

  beforeEach(async () => {
    zone = 'UTC';
    weekStart = 1;
    await configureTestingModule();
  });

  afterEach(() => custom.element.remove());

  it('renders the chart from the chart-data attribute', async () => {
    custom = await defineTestCustomElement(CreatedResolvedComponent, { 'chart-data': payload });

    expect(custom.element.querySelector('canvas')).not.toBeNull();
    expect(tableRows(within(custom.element).getByRole('table'))).toEqual([['10/12/2026', '2', '1']]);
  });

  it('falls back to empty data once the chart-data attribute is removed', async () => {
    custom = await defineTestCustomElement(CreatedResolvedComponent, { 'chart-data': payload });

    await custom.remove('chart-data');

    expect(custom.element.querySelector('canvas')).toBeNull();
  });

  it('renders the empty state without the attribute', async () => {
    custom = await defineTestCustomElement(CreatedResolvedComponent, {});

    expect(custom.element.querySelector('canvas')).toBeNull();
  });
});
