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

import { ChangeDetectionStrategy, Component, Signal, computed, inject, input } from '@angular/core';
import { ChartData, ChartOptions, Plugin } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import AverageLinePlugin from './plugin.average-line';

interface VelocityChartData {
  labels:string[];
  datasets:{ label:string, data:number[] }[];
  average:number;
  yAxisTitle:string;
}

const MAX_LABEL_LENGTH = 15;
const DATASET_COLORS = ['blue', 'green'];

function cssVariable(name:string):string {
  return getComputedStyle(document.body).getPropertyValue(name).trim();
}

function truncate(label:string):string {
  return label.length > MAX_LABEL_LENGTH ? `${label.slice(0, MAX_LABEL_LENGTH - 1)}…` : label;
}

@Component({
  selector: 'op-velocity-chart',
  templateUrl: './velocity-chart.component.html',
  imports: [BaseChartDirective],
  providers: [provideCharts(withDefaultRegisterables())],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class VelocityChartComponent {
  readonly i18n = inject(I18nService);
  readonly chartData = input.required<string>();

  readonly plugins:Plugin<'bar'>[] = [ChartDataLabels, AverageLinePlugin];

  private readonly parsedData = computed(() => JSON.parse(this.chartData()) as VelocityChartData);

  readonly barChartData:Signal<ChartData<'bar'>> = computed<ChartData<'bar'>>(() => {
    const { labels, datasets } = this.parsedData();

    return {
      labels,
      datasets: datasets.map((dataset, index) => ({
        ...dataset,
        backgroundColor: cssVariable(`--display-${DATASET_COLORS[index]}-scale-2`),
        borderColor: cssVariable(`--display-${DATASET_COLORS[index]}-scale-6`),
        borderWidth: 1,
      })),
    };
  });

  readonly barChartOptions:Signal<ChartOptions<'bar'>> = computed<ChartOptions<'bar'>>(() => {
    const { average, yAxisTitle } = this.parsedData();
    const fontColor = cssVariable('--body-font-color');
    const gridColor = cssVariable('--borderColor-muted');

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
          ticks: { color: fontColor },
          title: { display: true, text: yAxisTitle, color: fontColor },
        },
      },
      plugins: {
        'primer-colors': { enabled: false },
        legend: { position: 'bottom' },
        datalabels: {
          anchor: 'end',
          align: 'start',
          color: fontColor,
          font: { weight: 'bold' },
        },
        averageLine: {
          value: average,
          label: average.toLocaleString(this.i18n.locale, { maximumFractionDigits: 1 }),
          color: cssVariable('--fgColor-muted'),
        },
      },
    };
  });
}
