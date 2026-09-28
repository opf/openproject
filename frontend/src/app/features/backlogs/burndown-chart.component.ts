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
import { Chart, ChartData, ChartDataset, ChartEvent, ChartOptions, LegendElement, LegendItem, TooltipItem } from 'chart.js';
import 'chartjs-adapter-luxon';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import NonWorkingDaysPlugin, { NonWorkingDaysPluginOptions, NonWorkingInterval } from 'core-app/shared/components/charts/plugin.non-working-days';
import 'core-app/shared/components/charts/interaction.series-at-x';
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
  step:'day'|'hour';
  series:BurndownSeries[];
  nonWorkingIntervals:NonWorkingInterval[];
}

// Keeps the tallest step clear of the top of the plot area.
const Y_AXIS_HEADROOM = 1.1;

const MINUTE_IN_MS = 60 * 1000;

// The legend and the tooltip both read in the order a reader meets the series: what is left,
// where that is heading, the days nothing was expected on, and what was planned. Datasets carry
// the order they have to be drawn in instead, so neither list can be taken from them.
const NON_WORKING_LEGEND_KEY = 'non-working-days';
const SERIES_ORDER:string[] = ['remaining', 'projection', NON_WORKING_LEGEND_KEY, 'guideline'];

function seriesRank(key:string|undefined):number {
  const rank = SERIES_ORDER.indexOf(key ?? '');

  return rank === -1 ? SERIES_ORDER.length : rank;
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

  // Both bounds are taken across every series, so that hiding one does not refit the axes to
  // what is left.
  private readonly chartedRange = computed(() => {
    const times = this.parsed().series.flatMap((series) => series.data.map((point) => Date.parse(point.x)));

    return times.length === 0 ? {} : { min: Math.min(...times), max: Math.max(...times) };
  });

  private readonly yAxisMaximum = computed(() => {
    const values = this.parsed().series.flatMap((series) => series.data.map((point) => point.y));

    return values.length === 0 ? undefined : Math.max(...values) * Y_AXIS_HEADROOM;
  });

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => ({
    maintainAspectRatio: false,
    interaction: { mode: 'series-at-x', intersect: false },
    scales: {
      x: {
        type: 'time',
        ...this.chartedRange(),
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
        suggestedMax: this.yAxisMaximum(),
      },
    },
    plugins: {
      // Registered globally by the other charts, it would otherwise reassign the colours
      // this chart sets deliberately, on every layout.
      'primer-colors': { enabled: false },
      'non-working-days': {
        intervals: this.parsed().nonWorkingIntervals,
        zone: this.timezoneService.userTimezone(),
      },
      legend: {
        position: 'bottom',
        labels: { generateLabels: (chart) => this.legendLabels(chart) },
        onClick: (event, item, legend) => this.toggleLegendItem(event, item, legend),
      },
      tooltip: {
        itemSort: (a, b) => this.datasetRank(a.datasetIndex) - this.datasetRank(b.datasetIndex),
        callbacks: {
          title: (items) => this.tooltipTitle(items),
          label: (item) => this.tooltipLabel(item),
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
          borderWidth: 1,
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
          pointHoverRadius: 0,
          borderColor: cssVariable('--fgColor-muted', '#59636e'),
          borderWidth: 2,
        };
    }
  }

  // The guideline is sampled by day, so its own timestamp would not name the moment being
  // hovered. Remaining carries that wherever it still runs, and the projection takes over at the
  // instant it stops -- without that second choice the header jumps to the end of the day just
  // as the cursor crosses the junction, since the guideline sorts first among the items.
  private tooltipTitle(items:TooltipItem<'line'>[]):string {
    const { series } = this.parsed();
    const at = (id:BurndownSeries['id']) => items.find((item) => series[item.datasetIndex]?.id === id);
    const dated = at('remaining') ?? at('projection') ?? items[0];

    return this.formattedTick(Number(dated.parsed.x));
  }

  // Ticks sit at the end of the period they carry, so 09:59:59.999 is what the 9 o'clock hour
  // left behind. Naming it 10:00 is what a reader expects, and rounding to the minute does that
  // without disturbing the interval's own bounds, which are exact instants rather than period
  // ends. A day end must be truncated instead: rounding it would land on the following date.
  private formattedTick(timestamp:number):string {
    if (this.parsed().step === 'day') {
      return this.timezoneService.formattedDate(new Date(timestamp).toISOString());
    }

    const roundedToMinute = Math.round(timestamp / MINUTE_IN_MS) * MINUTE_IN_MS;

    return this.timezoneService.formattedDatetime(new Date(roundedToMinute).toISOString());
  }

  // Remaining is a sum of whole story points, while the two projected series divide them
  // across working days and would otherwise read to full float precision.
  private tooltipLabel(item:TooltipItem<'line'>):string {
    const { series } = this.parsed();
    const value = series[item.datasetIndex]?.id === 'remaining'
      ? item.formattedValue
      : (item.parsed.y ?? 0).toLocaleString(undefined, { maximumFractionDigits: 1 });

    return `${item.dataset.label ?? ''}: ${value}`;
  }

  private legendLabels(chart:Chart):LegendItem[] {
    const labels = Chart.defaults.plugins.legend.labels.generateLabels(chart);

    if (this.parsed().nonWorkingIntervals.length > 0) {
      labels.push(this.nonWorkingLegendItem(chart));
    }

    return labels.sort((a, b) => this.legendRank(a) - this.legendRank(b));
  }

  private nonWorkingLegendItem(chart:Chart):LegendItem {
    const bandColor = cssVariable('--borderColor-muted', '#d0d7de');

    return {
      text: this.i18n.t('js.burndown.non_working_day'),
      fillStyle: bandColor,
      strokeStyle: bandColor,
      lineWidth: 0,
      hidden: this.nonWorkingOptions(chart).hidden ?? false,
    };
  }

  // The bands carry no dataset index, which is also how the toggle tells them apart.
  private legendRank(item:LegendItem):number {
    return item.datasetIndex === undefined
      ? seriesRank(NON_WORKING_LEGEND_KEY)
      : this.datasetRank(item.datasetIndex);
  }

  private datasetRank(datasetIndex:number):number {
    return seriesRank(this.parsed().series[datasetIndex]?.id);
  }

  // The bands are drawn by a plugin rather than a dataset, so their entry carries no dataset
  // index and has to toggle the plugin's own visibility.
  private toggleLegendItem(event:ChartEvent, item:LegendItem, legend:LegendElement<'line'>):void {
    if (item.datasetIndex !== undefined) {
      Chart.defaults.plugins.legend.onClick.call(legend, event, item, legend);
      return;
    }

    const options = this.nonWorkingOptions(legend.chart);
    options.hidden = !options.hidden;
    legend.chart.update();
  }

  private nonWorkingOptions(chart:Chart):NonWorkingDaysPluginOptions {
    return (chart.options.plugins?.['non-working-days'] ?? {}) as NonWorkingDaysPluginOptions;
  }
}
