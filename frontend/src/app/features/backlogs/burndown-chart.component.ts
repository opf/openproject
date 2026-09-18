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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Signal, computed, inject, input } from '@angular/core';
import { Chart, ChartData, ChartDataset, ChartOptions, LegendItem } from 'chart.js';
import 'chartjs-adapter-luxon';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import NonWorkingDaysPlugin, { NonWorkingInterval } from 'core-app/shared/components/charts/plugin.non-working-days';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';

interface BurndownPoint {
  x:string;
  y:number;
}

interface BurndownSeries {
  id:'remaining'|'guideline'|'projection';
  label:string;
  data:BurndownPoint[];
}

type BurndownDataset = ChartDataset<'line', BurndownPoint[]>;

interface BurndownChartData {
  series:BurndownSeries[];
  nonWorkingIntervals:NonWorkingInterval[];
}

function cssVariable(name:string, fallback:string):string {
  return getComputedStyle(document.body).getPropertyValue(name).trim() || fallback;
}

// The projection continues the remaining series, so the two share a colour.
function remainingColor():string {
  return cssVariable('--display-red-scale-6', '#c50d28');
}

@Component({
  selector: 'op-burndown-chart',
  templateUrl: './burndown-chart.component.html',
  imports: [BaseChartDirective, NoResultsComponent],
  providers: [provideCharts(withDefaultRegisterables(NonWorkingDaysPlugin))],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BurndownChartComponent {
  readonly i18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);

  readonly chartData = input.required<string>();

  private readonly parsed = computed(() => JSON.parse(this.chartData()) as BurndownChartData);

  readonly hasChartData = computed(() => this.parsed().series.some((series) => series.data.length > 0));

  readonly lineChartData = computed<ChartData<'line', BurndownPoint[]>>(() => ({
    datasets: this.parsed().series.map((series) => this.datasetFor(series)),
  }));

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => ({
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    scales: {
      x: {
        type: 'time',
        adapters: { date: { zone: this.timezoneService.userTimezone() } },
        time: { unit: 'day' },
        ticks: {
          // getDateFormat() yields a moment token string, which the luxon adapter would
          // misread, so the label is formatted here rather than through displayFormats.
          callback: (value:string|number) => this.timezoneService.formattedDate(new Date(Number(value)).toISOString()),
        },
      },
      y: {
        title: { display: true, text: this.i18n.t('js.burndown.story_points') },
        beginAtZero: true,
      },
    },
    plugins: {
      // Registered globally by the other charts, it would otherwise reassign the colours
      // this chart sets deliberately, on every layout.
      'primer-colors': { enabled: false },
      'non-working-days': { intervals: this.parsed().nonWorkingIntervals },
      legend: {
        position: 'bottom',
        labels: { generateLabels: (chart) => this.legendLabels(chart) },
      },
      tooltip: {
        callbacks: {
          title: (items) => this.timezoneService.formattedDatetime(new Date(Number(items[0].parsed.x)).toISOString()),
        },
      },
    },
  }));

  // Datasets are drawn from the highest order down, so the filled remaining area has to sit
  // above the lines in order for them to end up drawn over it.
  private datasetFor(series:BurndownSeries):BurndownDataset {
    const shared = {
      label: series.label,
      data: series.data,
      pointRadius: 0,
      pointHitRadius: 8,
    };

    switch (series.id) {
      case 'remaining':
        return {
          ...shared,
          order: 3,
          stepped: 'after',
          fill: true,
          borderColor: remainingColor(),
          backgroundColor: cssVariable('--display-red-scale-2', '#fda5a7'),
          borderWidth: 2,
        };
      case 'projection':
        return {
          ...shared,
          order: 2,
          borderColor: remainingColor(),
          borderDash: [6, 4],
          borderWidth: 1,
        };
      default:
        return {
          ...shared,
          order: 1,
          borderColor: cssVariable('--fgColor-muted', '#59636e'),
          borderWidth: 2,
        };
    }
  }

  private legendLabels(chart:Chart):LegendItem[] {
    const datasetLabels = Chart.defaults.plugins.legend.labels.generateLabels(chart);

    if (this.parsed().nonWorkingIntervals.length === 0) {
      return datasetLabels;
    }

    const bandColor = cssVariable('--borderColor-muted', '#d0d7de');

    return [
      ...datasetLabels,
      {
        text: this.i18n.t('js.burndown.non_working_day'),
        fillStyle: bandColor,
        strokeStyle: bandColor,
        lineWidth: 0,
      },
    ];
  }
}
