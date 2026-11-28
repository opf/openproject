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

import { Component, Signal, computed, inject, input } from '@angular/core';
import { Chart, ChartData, ChartOptions, LegendItem, Plugin } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { ChartDescriptionDirective } from 'core-app/shared/components/charts/description/chart-description.directive';
import { ChartDescription } from 'core-app/shared/components/charts/description/chart-description';
import AverageLinePlugin, { AVERAGE_LINE_DASH, isAverageLineVisible, toggleAverageLine } from './plugin.average-line';
import { jsonAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

interface VelocityChartData {
  unit:'story_points'|'time';
  labels:string[];
  datasets:{ label:string, data:number[] }[];
  average:number|null;
  averageLabel:string;
  yAxisTitle:string;
  summary:string;
}

const EMPTY_VELOCITY_CHART_DATA:VelocityChartData = {
  unit: 'story_points',
  labels: [],
  datasets: [],
  average: null,
  averageLabel: '',
  yAxisTitle: '',
  summary: '',
};

const MAX_LABEL_LENGTH = 15;
const DATASET_COLORS = ['blue', 'green'];
const LEGEND_SYMBOL_WIDTH = 40;
const MIN_BAR_HEIGHT_FOR_INNER_LABEL = 24;

function truncate(label:string):string {
  return label.length > MAX_LABEL_LENGTH ? `${label.slice(0, MAX_LABEL_LENGTH - 1).trimEnd()}…` : label;
}

@Component({
  selector: 'op-velocity-chart',
  templateUrl: './velocity-chart.component.html',
  imports: [BaseChartDirective, ChartDescriptionDirective],
  providers: [provideCharts(withDefaultRegisterables())],
})
export class VelocityChartComponent {
  readonly i18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);
  readonly configurationService = inject(ConfigurationService);
  readonly chartData = input(EMPTY_VELOCITY_CHART_DATA, {
    transform: jsonAttribute(EMPTY_VELOCITY_CHART_DATA),
  });

  readonly plugins:Plugin<'bar'>[] = [ChartDataLabels, AverageLinePlugin];

  protected readonly description = computed<ChartDescription>(() => {
    const { labels, datasets, summary } = this.chartData();
    const label = this.i18n.t('js.velocity_chart.chart_label');

    return {
      label,
      summary,
      table: {
        caption: this.i18n.t('js.chart.description.caption', { label }),
        columns: [this.i18n.t('js.velocity_chart.sprint_column'), ...datasets.map((dataset) => this.columnHeader(dataset.label))],
        rows: labels.map((sprint, index) => ({
          header: sprint,
          cells: datasets.map((dataset) => this.formatValue(dataset.data[index])),
        })),
      },
    };
  });

  readonly barChartData:Signal<ChartData<'bar'>> = computed<ChartData<'bar'>>(() => {
    const { labels, datasets } = this.chartData();

    return {
      labels,
      datasets: datasets.map((dataset, index) => ({
        ...dataset,
        backgroundColor: getCSSVariable(`--display-${DATASET_COLORS[index]}-scale-2`),
        borderColor: getCSSVariable(`--display-${DATASET_COLORS[index]}-scale-6`),
        borderWidth: 1,
      })),
    };
  });

  readonly barChartOptions:Signal<ChartOptions<'bar'>> = computed<ChartOptions<'bar'>>(() => {
    const { unit, average, averageLabel, yAxisTitle } = this.chartData();
    const fontColor = getCSSVariable('--body-font-color');
    const gridColor = getCSSVariable('--borderColor-muted');
    const averageColor = getCSSVariable('--fgColor-muted');
    const averageLegendItems = (chart:Chart):LegendItem[] => (average === null ? [] : [{
      text: averageLabel,
      hidden: !isAverageLineVisible(chart),
      pointStyle: 'line',
      strokeStyle: averageColor,
      lineDash: AVERAGE_LINE_DASH,
      lineWidth: 1,
      fontColor,
    }]);

    return {
      responsive: true,
      maintainAspectRatio: false,
      color: fontColor,
      scales: {
        x: {
          grid: { offset: true, color: gridColor },
          ticks: {
            color: fontColor,
            callback(value) {
              return truncate(this.getLabelForValue(value as number));
            },
          },
        },
        y: {
          beginAtZero: true,
          grace: '10%',
          grid: { color: gridColor },
          ticks: {
            color: fontColor,
            maxTicksLimit: 3,
            stepSize: unit === 'time' ? this.configurationService.hoursPerDay() : undefined,
            callback: (value) => this.formatValue(Number(value)),
          },
          title: { display: true, text: yAxisTitle, color: fontColor },
        },
      },
      plugins: {
        'primer-colors': { enabled: false },
        legend: {
          position: 'bottom',
          onClick(event, item, legend) {
            if (item.datasetIndex === undefined) {
              toggleAverageLine(legend.chart);
            } else {
              Chart.defaults.plugins.legend.onClick.call(this, event, item, legend);
            }
          },
          labels: {
            usePointStyle: true,
            pointStyleWidth: LEGEND_SYMBOL_WIDTH,
            generateLabels: (chart) => [
              ...Chart.defaults.plugins.legend.labels.generateLabels(chart).map((item) => ({ ...item, pointStyle: 'rect' as const })),
              ...averageLegendItems(chart),
            ],
          },
        },
        datalabels: {
          anchor: 'end',
          align: ({ chart, dataset, dataIndex }) => {
            const yScale = chart.scales.y;
            const barHeight = yScale.getPixelForValue(0) - yScale.getPixelForValue(dataset.data[dataIndex] as number);

            return barHeight < MIN_BAR_HEIGHT_FOR_INNER_LABEL ? 'end' : 'start';
          },
          color: fontColor,
          font: { weight: 'bold' },
          formatter: (value:number) => this.formatValue(value),
        },
        tooltip: {
          callbacks: {
            label: ({ dataset, parsed }) => `${dataset.label}: ${this.formatValue(parsed.y ?? 0)}`,
          },
        },
        averageLine: average === null ? {} : {
          value: average,
          label: this.formatValue(average),
          color: averageColor,
          labelColor: fontColor,
        },
      },
    };
  });

  private columnHeader(label:string):string {
    if (this.chartData().unit !== 'story_points') {
      return label;
    }

    const unit = this.i18n.t('js.sprint_charts.unit.story_points');

    return this.i18n.t('js.sprint_charts.column_with_unit', { label, unit });
  }

  formatValue(value:number):string {
    if (this.chartData().unit === 'time') {
      return this.timezoneService.formattedChronicDurationFromHours(value);
    }

    return new Intl.NumberFormat(this.i18n.locale, { maximumFractionDigits: 2 }).format(value);
  }
}
