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

import { Component, Signal, computed, input } from '@angular/core';
import { ChartData, ChartOptions, Plugin } from 'chart.js';
import { color } from 'chart.js/helpers';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import PrimerColorsPlugin from 'core-app/shared/components/work-package-graphs/plugin.primer-colors';
import { generateId, getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

interface SprintWorkPackageGraphData {
  labels:string[];
  data:number[];
  colors:(string|null)[];
  summary:string;
  statusColumnTitle:string;
  countColumnTitle:string;
}

// A bar is filled the way `hl_background_muted_styles` fills a status badge -- its own color,
// faded, behind its own outline -- but stronger than the 0.18 a badge uses, which a bar this
// large washes out.
const MUTED_FILL_OPACITY = 0.5;

// A status is not obliged to carry a color.
const UNCOLORED_STATUS_FALLBACK = '--display-gray-scale-6';

// Nothing here follows the data, so the options are built once rather than tracked.
function barChartOptions():ChartOptions<'bar'> {
  const fontColor = getCSSVariable('--body-font-color');
  const gridColor = getCSSVariable('--borderColor-muted');

  return {
    responsive: true,
    maintainAspectRatio: false,
    color: fontColor,
    scales: {
      x: {
        grid: { color: gridColor },
        ticks: { color: fontColor },
      },
      y: {
        beginAtZero: true,
        grace: '10%',
        grid: { color: gridColor },
        ticks: { color: fontColor, precision: 0 },
      },
    },
    plugins: {
      // The bars bring their own colors, which the plugin would otherwise paint over.
      'primer-colors': { enabled: false },
      legend: { display: false },
      datalabels: {
        anchor: 'center',
        align: 'top',
        color: fontColor,
        font: { weight: 'bold', size: 14 },
      },
    },
  };
}

@Component({
  selector: 'op-sprint-work-package-graph',
  templateUrl: './sprint-work-package-graph.component.html',
  imports: [BaseChartDirective],
  providers: [provideCharts(withDefaultRegisterables(PrimerColorsPlugin))],
})
export class SprintWorkPackageGraphComponent {
  readonly chartData = input.required<string>();

  readonly plugins:Plugin<'bar'>[] = [ChartDataLabels];

  readonly summaryId = generateId('op-sprint-work-package-graph-summary');
  readonly tableId = generateId('op-sprint-work-package-graph-table');

  readonly parsedData:Signal<SprintWorkPackageGraphData> = computed(
    () => JSON.parse(this.chartData()) as SprintWorkPackageGraphData,
  );

  // One bar per status, carrying the color that status carries everywhere else in the product.
  readonly barChartData:Signal<ChartData<'bar'>> = computed<ChartData<'bar'>>(() => {
    const { labels, data, colors } = this.parsedData();
    const borderColor = colors.map((statusColor) => statusColor ?? getCSSVariable(UNCOLORED_STATUS_FALLBACK, '#59636e'));

    return {
      labels,
      datasets: [{
        data,
        backgroundColor: borderColor.map((barColor) => color(barColor).alpha(MUTED_FILL_OPACITY).rgbString()),
        borderColor,
        borderWidth: 1,
      }],
    };
  });

  readonly barChartOptions:ChartOptions<'bar'> = barChartOptions();
}
