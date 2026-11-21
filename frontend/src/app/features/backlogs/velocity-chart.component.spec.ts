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
import { within } from '@testing-library/dom';
import { tableColumns, tableRows } from 'core-app/shared/components/charts/description/testing/chart-description-table';
import { By } from '@angular/platform-browser';
import { BaseChartDirective } from 'ng2-charts';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { VelocityChartComponent } from './velocity-chart.component';
import AverageLinePlugin, { isAverageLineVisible } from './plugin.average-line';

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

  const i18nStub = {
    locale: 'de',
    t(key:string, options:Record<string, string|number> = {}) {
      const translations:Record<string, string> = {
        'js.chart.description.caption': `${options.label}: data`,
        'js.sprint_charts.column_with_unit': `${options.label} (${options.unit})`,
        'js.sprint_charts.unit.story_points': 'story points',
        'js.velocity_chart.chart_label': 'Velocity chart',
        'js.velocity_chart.sprint_column': 'Sprint',
      };

      return translations[key] ?? key;
    },
  };

  beforeEach(async () => {
    Object.entries(cssVariables).forEach(([name, value]) => document.body.style.setProperty(name, value));

    await TestBed.configureTestingModule({
      imports: [VelocityChartComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        {
          provide: ConfigurationService,
          useValue: { durationFormat: () => 'hours_only', hoursPerDay: () => 8, daysPerMonth: () => 20 },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(VelocityChartComponent);
    element = fixture.nativeElement as HTMLElement;

    fixture.componentRef.setInput('chartData', JSON.stringify({
      unit: 'story_points',
      labels: ['Sprint 1', 'A sprint with a very long name'],
      datasets: [
        { label: 'Committed', data: [21, 13] },
        { label: 'Completed', data: [20, 9] },
      ],
      average: 14.5,
      averageLabel: 'Average',
      yAxisTitle: 'Story points',
      summary: 'Bar chart of committed and completed story points of the last 2 sprints. Average velocity: 14.5 SP.',
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

  describe('accessibility', () => {
    it('names the chart and uses the server summary as its description', () => {
      expect(within(element).getByRole('img', {
        name: 'Velocity chart',
        description: 'Bar chart of committed and completed story points of the last 2 sprints. Average velocity: 14.5 SP.',
      })).toBeInTheDocument();
    });

    it('tabulates one row per sprint', () => {
      const table = within(element).getByRole('table', { name: 'Velocity chart: data' });

      expect(tableColumns(table)).toEqual(['Sprint', 'Committed (story points)', 'Completed (story points)']);
      expect(tableRows(table)).toEqual([
        ['Sprint 1', '21', '20'],
        ['A sprint with a very long name', '13', '9'],
      ]);
    });
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
    expect(options().plugins!.averageLine).toEqual(expect.objectContaining({ value: 14.5, label: '14,5', color: '#666666' }));
  });

  it('colors the average label like the values in the bars', () => {
    expect(options().plugins!.averageLine!.labelColor).toBe(options().plugins!.datalabels!.color);
  });

  const withoutAverage = () => {
    fixture.componentRef.setInput('chartData', JSON.stringify({
      ...fixture.componentInstance.parsedData(),
      average: null,
    }));
    fixture.detectChanges();
  };

  it('draws no average line without an average', () => {
    withoutAverage();

    expect(options().plugins!.averageLine).toEqual({});
  });

  describe('legend', () => {
    const chart = () => fixture.debugElement.query(By.directive(BaseChartDirective)).injector.get(BaseChartDirective).chart!;
    const legendItems = () => chart().legend!.legendItems!;

    it('shows the datasets as boxes followed by the dashed average line', () => {
      expect(legendItems().map(({ text, pointStyle }) => [text, pointStyle])).toEqual([
        ['Committed', 'rect'],
        ['Completed', 'rect'],
        ['Average', 'line'],
      ]);
      expect(legendItems()[2]).toEqual(expect.objectContaining({ strokeStyle: '#666666', lineDash: [4, 4] }));
    });

    it('leaves out the average line without an average', () => {
      withoutAverage();
      chart().update();

      expect(legendItems().map(({ text }) => text)).toEqual(['Committed', 'Completed']);
    });

    it('still toggles datasets on click', () => {
      const legend = chart().legend!;
      legend.options.onClick.call(legend, {} as never, legendItems()[0], legend);

      expect(chart().isDatasetVisible(0)).toBe(false);
    });

    it('toggles the average line on click', () => {
      const legend = chart().legend!;
      const clickAverage = () => legend.options.onClick.call(legend, {} as never, legendItems()[2], legend);

      clickAverage();

      expect(isAverageLineVisible(chart())).toBe(false);
      expect(legendItems()[2].hidden).toBe(true);
      expect([0, 1].map((index) => chart().isDatasetVisible(index))).toEqual([true, true]);

      clickAverage();

      expect(isAverageLineVisible(chart())).toBe(true);
      expect(legendItems()[2].hidden).toBe(false);
    });
  });

  it('titles the y axis', () => {
    const yScale = options().scales!.y as { title:{ display:boolean, text:string } };

    expect(yScale.title).toEqual(expect.objectContaining({ display: true, text: 'Story points' }));
  });

  it('limits the y axis to three ticks', () => {
    expect(options().scales!.y!.ticks).toEqual(expect.objectContaining({ maxTicksLimit: 3, stepSize: undefined }));
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

  describe('with unit time', () => {
    beforeEach(() => {
      fixture.componentRef.setInput('chartData', JSON.stringify({
        ...fixture.componentInstance.parsedData(),
        unit: 'time',
        datasets: [
          { label: 'Committed', data: [21.25, 13] },
          { label: 'Completed', data: [20, 8.5] },
        ],
      }));
      fixture.detectChanges();
    });

    it('leaves the unit to the tabulated durations', () => {
      expect(tableColumns(within(element).getByRole('table'))).toEqual(['Sprint', 'Committed', 'Completed']);
    });

    it('steps the y axis ticks in multiples of a working day', () => {
      expect(options().scales!.y!.ticks).toEqual(expect.objectContaining({ stepSize: 8 }));
    });

    it('formats the y axis ticks as durations', () => {
      const yTickFormatter = options().scales!.y!.ticks!.callback as unknown as (value:number) => string;

      expect(yTickFormatter(40)).toBe('40h');
    });

    it('formats the bar labels as durations', () => {
      const barLabelFormatter = options().plugins!.datalabels!.formatter as unknown as (value:number) => string;

      expect(barLabelFormatter(21.25)).toBe('21.25h');
    });

    it('formats the tooltip values as durations', () => {
      const tooltipLabelFormatter = options().plugins!.tooltip!.callbacks!.label as unknown as (item:object) => string;

      expect(tooltipLabelFormatter({ dataset: { label: 'Committed' }, parsed: { y: 21.25 } })).toBe('Committed: 21.25h');
    });

    it('formats the average line label as a duration', () => {
      expect(options().plugins!.averageLine).toEqual(expect.objectContaining({ label: '14.5h' }));
    });

    it('formats the data table cells as durations', () => {
      const cells = within(element).getAllByRole('cell').map((cell) => cell.textContent.trim());

      expect(cells).toEqual(['21.25h', '20h', '13h', '8.5h']);
    });
  });
});
