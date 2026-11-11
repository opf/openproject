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
import { CartesianScaleOptions } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { BurnupChartComponent } from 'core-app/features/backlogs/burnup-chart.component';

describe('BurnupChartComponent', () => {
  let fixture:ComponentFixture<BurnupChartComponent>;
  let element:HTMLElement;

  const i18nStub = {
    locale: 'en',
    t(key:string, options:Record<string, string|number> = {}) {
      const translations:Record<string, string> = {
        'js.burnup_chart.chart_day': `Day ${options.day}: ${options.values}`,
        'js.burnup_chart.chart_label': 'Burnup chart',
        'js.burnup_chart.chart_summary': `Burnup chart data: ${options.days}.`,
        'js.burnup_chart.chart_value': `${options.label}: ${options.value}`,
        'js.sprint_charts.y_axis_title.story_points': 'Story points',
        'js.sprint_charts.y_axis_title.time': 'Estimated time',
        'js.sprint_charts.non_working_day': 'Non-working day',
      };

      return translations[key] ?? key;
    },
  };

  const configurationStub = {
    isTimezoneSet: () => true,
    timezone: () => 'UTC',
    dateFormatPresent: () => true,
    dateFormat: () => 'MM/DD/YYYY',
    timeFormatPresent: () => true,
    timeFormat: () => 'hh:mm A',
    durationFormat: () => 'hours_only',
    hoursPerDay: () => 8,
    daysPerMonth: () => 20,
  };

  const point = (x:string, y:number) => ({ x, y });

  const completed = { id: 'completed', label: 'Completed work', data: [point('2026-10-12T09:00:00.000Z', 0)] };
  const scope = { id: 'scope', label: 'Total work scope', data: [point('2026-10-12T09:00:00.000Z', 10)] };
  const projection = {
    id: 'projection',
    label: 'Total work scope (projection)',
    data: [point('2026-10-14T12:00:00.000Z', 10), point('2026-10-23T23:59:59.999Z', 10)],
  };
  const guideline = {
    id: 'guideline',
    label: 'Guideline',
    data: [point('2026-10-12T09:00:00.000Z', 0), point('2026-10-23T23:59:59.999Z', 10)],
  };

  const renderWith = (
    series:unknown[],
    nonWorkingIntervals:unknown[] = [],
    unit:'story_points'|'time' = 'story_points',
  ) => {
    fixture.componentRef.setInput('chartData', JSON.stringify({
      unit,
      step: 'hour',
      range: { from: '2026-10-12T00:00:00.000Z', to: '2026-10-23T23:59:59.999Z' },
      series,
      nonWorkingIntervals,
    }));
    fixture.detectChanges();
  };

  const datasetLabeled = (label:string) => fixture.componentInstance.lineChartData().datasets
    .find((dataset) => dataset.label === label)!;

  // ng2-charts builds the chart on an input change that follows its own ngOnInit, which one round
  // of change detection does not reach, so it is asked to build it here.
  const renderedChart = () => fixture.debugElement.query(By.directive(BaseChartDirective))
    .injector.get(BaseChartDirective)
    .render()!;

  const yAxisTitle = () => (fixture.componentInstance.lineChartOptions().scales!.y as CartesianScaleOptions).title.text;

  const describedBy = (host:HTMLElement) => {
    const id = host.querySelector('canvas')!.getAttribute('aria-describedby')!;

    return host.querySelector<HTMLElement>(`#${id}`)!;
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BurnupChartComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        { provide: ConfigurationService, useValue: configurationStub },
        TimezoneService,
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BurnupChartComponent);
    element = fixture.nativeElement as HTMLElement;
  });

  it('describes each day by the value its series closed at', () => {
    renderWith([
      {
        ...completed,
        data: [point('2026-10-12T09:00:00.000Z', 0), point('2026-10-12T23:59:59.999Z', 3)],
      },
      {
        ...scope,
        data: [point('2026-10-12T23:59:59.999Z', 10), point('2026-10-13T12:00:00.000Z', 12)],
      },
    ]);

    const canvas = element.querySelector('canvas')!;

    expect(canvas).toHaveAccessibleName('Burnup chart');
    expect(describedBy(element)).toHaveTextContent(
      'Burnup chart data: Day 1: Completed work: 3, Total work scope: 10; Day 2: Total work scope: 12.',
    );
  });

  it('reads the legend in the order of the mockup', () => {
    renderWith([completed, scope, projection, guideline], [{ from: '2026-10-17', to: '2026-10-18' }]);

    expect(renderedChart().legend!.legendItems!.map((item) => item.text)).toEqual([
      'Completed work',
      'Non-working day',
      'Total work scope',
      'Total work scope (projection)',
      'Guideline',
    ]);
  });

  it('fills the completed work as a stepped area', () => {
    renderWith([completed, scope, projection, guideline]);

    expect(datasetLabeled('Completed work')).toEqual(expect.objectContaining({ fill: true, stepped: 'after' }));
  });

  it('draws the scope as a stepped line continued by a dashed projection', () => {
    renderWith([completed, scope, projection, guideline]);

    expect(datasetLabeled('Total work scope')).toEqual(expect.objectContaining({ stepped: 'after' }));
    expect(datasetLabeled('Total work scope').fill).toBeFalsy();
    expect(datasetLabeled('Total work scope (projection)').borderDash).toEqual([6, 4]);
    expect(datasetLabeled('Total work scope (projection)').borderColor)
      .toEqual(datasetLabeled('Total work scope').borderColor);
  });

  // The projection opens where the scope stops, so a cursor at that instant finds both. Its title
  // comes from the scope, whose hourly ticks name the moment more finely.
  it('takes the tooltip title from the scope rather than the projection', () => {
    renderWith([completed, scope, projection, guideline]);

    const { plugins } = fixture.componentInstance.lineChartOptions();
    const title = plugins?.tooltip?.callbacks?.title as unknown as
      (items:{ datasetIndex:number, parsed:{ x:number } }[]) => string;

    expect(title([
      { datasetIndex: 2, parsed: { x: Date.parse('2026-10-15T00:00:00.000Z') } },
      { datasetIndex: 1, parsed: { x: Date.parse('2026-10-14T11:59:59.999Z') } },
    ])).toEqual('10/14/2026 12:00 PM');
  });

  it('labels the axis in whole story points', () => {
    renderWith([
      { ...scope, data: [point('2026-10-12T09:00:00.000Z', 1)] },
      { ...guideline, data: [point('2026-10-12T23:59:59.999Z', 0.4), point('2026-10-13T23:59:59.999Z', 0.8)] },
    ]);

    const labels = renderedChart().scales.y.ticks.map((tick) => tick.value);

    expect(labels.length).toBeGreaterThan(1);
    expect(labels.filter((label) => !Number.isInteger(label))).toEqual([]);
  });

  it('titles the y axis in story points', () => {
    renderWith([completed, scope]);

    expect(yAxisTitle()).toEqual('Story points');
  });

  describe('in estimated time', () => {
    beforeEach(() => {
      renderWith([
        { ...completed, data: [point('2026-10-12T09:00:00.000Z', 0), point('2026-10-12T23:59:59.999Z', 2.5)] },
        { ...scope, data: [point('2026-10-12T09:00:00.000Z', 21.25), point('2026-10-12T23:59:59.999Z', 20)] },
      ], [], 'time');
    });

    it('titles the y axis in estimated time', () => {
      expect(yAxisTitle()).toEqual('Estimated time');
    });

    it('labels the axis in multiples of a working day', () => {
      const labels = renderedChart().scales.y.ticks.map((tick) => tick.value);

      expect(labels.length).toBeGreaterThan(1);
      expect(labels.filter((label) => label % 8 !== 0)).toEqual([]);
    });

    it('formats the axis labels as durations', () => {
      const formatYTick = fixture.componentInstance.lineChartOptions().scales!.y!.ticks!.callback as unknown as (value:number) => string;

      expect(formatYTick(16)).toEqual('16h');
    });

    it('formats the tooltip values as durations', () => {
      const formatLabel = fixture.componentInstance.lineChartOptions().plugins!.tooltip!.callbacks!.label as unknown as (item:object) => string;

      expect(formatLabel({ dataset: { label: 'Total work scope' }, parsed: { y: 21.25 } }))
        .toEqual('Total work scope: 21.25h');
    });

    it('describes each day in durations', () => {
      expect(describedBy(element)).toHaveTextContent(
        'Burnup chart data: Day 1: Completed work: 2.5h, Total work scope: 20h.',
      );
    });
  });

  it('does not render chart semantics without data', () => {
    renderWith([]);

    expect(element.querySelector('canvas')).toBeNull();
    expect(element.querySelector(`#${fixture.componentInstance.chartDescriptionId}`)).toBeNull();
  });
});
