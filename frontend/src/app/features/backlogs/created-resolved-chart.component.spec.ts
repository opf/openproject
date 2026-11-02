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
import { CreatedResolvedComponent } from 'core-app/features/backlogs/created-resolved-chart.component';

describe('CreatedResolvedComponent', () => {
  let fixture:ComponentFixture<CreatedResolvedComponent>;
  let element:HTMLElement;
  let zone:string;

  const i18nStub = {
    locale: 'en',
    t: (key:string) => key,
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
  };

  // The window is the server's, not the series' extent, so it is stated rather than derived.
  const range = { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' };

  const chartData = (series:unknown[], nonWorkingIntervals:unknown[] = [], step:'day'|'hour' = 'hour') =>
    JSON.stringify({ step, range, series, nonWorkingIntervals });

  const point = (x:string, y:number) => ({ x, y });

  beforeEach(async () => {
    zone = 'UTC';

    await TestBed.configureTestingModule({
      imports: [CreatedResolvedComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        { provide: ConfigurationService, useValue: configurationStub },
        TimezoneService,
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(CreatedResolvedComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWith = (series:unknown[], nonWorkingIntervals:unknown[] = [], step:'day'|'hour' = 'hour') => {
    fixture.componentRef.setInput('chartData', chartData(series, nonWorkingIntervals, step));
    fixture.detectChanges();
  };

  const bothSeries = () => [
    { id: 'created', label: 'Created work packages', data: [point('2026-10-12T09:00:00.000Z', 2)] },
    { id: 'resolved', label: 'Resolved work packages', data: [point('2026-10-12T09:00:00.000Z', 1)] },
  ];

  const datasets = () => fixture.componentInstance.lineChartData().datasets;

  const options = () => fixture.componentInstance.lineChartOptions();

  // What chart.js put on the axis, rather than what it was asked for. ng2-charts builds the chart
  // on an input change that follows its own ngOnInit, which one round of change detection does not
  // reach, so it is asked to build it here.
  const renderedYAxisLabels = () => {
    const directive = fixture.debugElement.query(By.directive(BaseChartDirective))
      .injector.get(BaseChartDirective);

    return directive.render()!.scales.y.ticks.map((tick) => tick.value);
  };

  it('renders a canvas once a series carries points', () => {
    renderWith(bothSeries());

    expect(element.querySelector('canvas')).not.toBeNull();
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

    expect(resolved.label).toEqual('Resolved work packages');
    // Resolved is drawn on top of created, which it never exceeds.
    expect(resolved.order).toEqual(0);
  });

  // A count is a step function; interpolating draws totals that never existed.
  it('steps both counted series rather than interpolating between ticks', () => {
    renderWith(bothSeries());

    expect(datasets().map((dataset) => dataset.stepped)).toEqual(['after', 'after']);
  });

  // A work package is atomic. A sprint holding one of them used to be drawn against an axis
  // offering 0.2 and 0.4 of it, because chart.js fits its steps to the range it is given.
  it('labels the axis in whole work packages', () => {
    renderWith([
      { id: 'created', label: 'Created work packages', data: [point('2026-10-12T09:00:00.000Z', 1)] },
    ]);

    const labels = renderedYAxisLabels();

    expect(labels.length).toBeGreaterThan(1);
    expect(labels.filter((label) => !Number.isInteger(label))).toEqual([]);
  });

  it('adds a point-less series so the non-working days get a legend entry that toggles them', () => {
    renderWith(bothSeries(), [{ from: '2026-10-17', to: '2026-10-18' }]);

    const standIn = datasets()[2];

    expect(standIn.data).toEqual([]);
    expect(standIn.label).toEqual('js.sprint_charts.non_working_day');
  });

  it('leaves the non-working stand-in out when there are no bands to paint', () => {
    renderWith(bothSeries());

    expect(datasets()).toHaveLength(2);
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
