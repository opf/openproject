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
import {
  Chart, ChartData, ChartDataset, ChartEvent, ChartOptions, LegendElement, LegendItem, PointStyle, TooltipItem,
} from 'chart.js';
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

const NON_WORKING_LEGEND_KEY = 'non-working-days';

type SeriesKey = BurndownSeries['id']|typeof NON_WORKING_LEGEND_KEY;

// Chart.js takes a swatch shape per legend item but the decision to honour it at all is global,
// hence usePointStyle on the labels.
const SWATCH_WIDTH = 24;

interface SeriesColor {
  border:string;
  background?:string;
}

// Every property but +swatch+ and +color+ is named as chart.js names it, so that a dataset can
// take them as they stand.
interface SeriesStyle {
  // An area for the one that was measured, a bare line for the two that are only ever a line.
  swatch:PointStyle;
  borderDash:number[];
  borderWidth:number;
  order?:number;
  stepped?:'after';
  fill?:boolean;
  pointRadius?:number;
  pointHitRadius?:number;
  pointHoverRadius?:number;
  // Read on demand rather than held as a value, because the colours come off the document and
  // would otherwise freeze at import time, before the stylesheet resolves and against whichever
  // theme is in force. The non-working days are painted by a plugin and coloured there.
  color?:() => SeriesColor;
}

// True of every line, and overridable by any of them: the points are never drawn, but they stay
// wide enough to be found by a cursor that is not exactly on one.
const SERIES_DEFAULTS:Omit<Partial<SeriesStyle>, 'swatch'|'color'> = {
  pointRadius: 0,
  pointHitRadius: 8,
};

// Everything that tells the series apart, so that a line and its swatch cannot drift.
//
// ORDER IS SIGNIFICANT: the legend and the tooltip read in the order these are declared, which
// is the order a reader meets them -- what is left, where that is heading, the days nothing was
// expected on, and what was planned. Reordering this list reorders both.
// It is not the order the lines are drawn in: datasets are drawn from the highest `order` down,
// so that the filled remaining area sits under the lines, which runs the other way.
const SERIES_STYLE:Record<SeriesKey, SeriesStyle> = {
  remaining: {
    swatch: 'rect',
    borderDash: [],
    borderWidth: 1,
    order: 3,
    stepped: 'after',
    fill: true,
    color: () => ({
      border: remainingColor(),
      background: cssVariable('--display-red-scale-2', '#fda5a7'),
    }),
  },
  projection: {
    swatch: 'line',
    borderDash: [6, 4],
    borderWidth: 1,
    order: 2,
    color: () => ({ border: remainingColor() }),
  },
  [NON_WORKING_LEGEND_KEY]: {
    swatch: 'rect',
    borderDash: [],
    borderWidth: 0,
  },
  guideline: {
    swatch: 'line',
    borderDash: [],
    borderWidth: 2,
    order: 1,
    pointHoverRadius: 0,
    color: () => ({ border: cssVariable('--fgColor-muted', '#59636e') }),
  },
};

function seriesRank(key:SeriesKey|undefined):number {
  const readingOrder = Object.keys(SERIES_STYLE);
  const rank = readingOrder.indexOf(key ?? '');

  return rank === -1 ? readingOrder.length : rank;
}

function legendStyle(key:SeriesKey|undefined):Partial<LegendItem> {
  const style = SERIES_STYLE[key ?? 'remaining'];

  return { pointStyle: style.swatch, lineDash: style.borderDash, lineWidth: style.borderWidth };
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

  private readonly parsedInput = computed(() => JSON.parse(this.chartData()) as BurndownChartData);

  readonly hasChartData = computed(() => this.parsedInput().series.some((series) => series.data.length > 0));

  readonly lineChartData = computed<ChartData<'line', BurndownPoint[]>>(() => ({
    datasets: this.parsedInput().series.map((series) => this.datasetFor(series)),
  }));

  // Both bounds are taken across every series, so that hiding one does not refit the axes to
  // what is left.
  private readonly chartedRange = computed(() => {
    const times = this.parsedInput().series.flatMap((series) => series.data.map((point) => Date.parse(point.x)));

    return times.length === 0 ? {} : { min: Math.min(...times), max: Math.max(...times) };
  });

  private readonly yAxisMaximum = computed(() => {
    const values = this.parsedInput().series.flatMap((series) => series.data.map((point) => point.y));

    return values.length === 0 ? undefined : Math.max(...values) * Y_AXIS_HEADROOM;
  });

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => {
    // The axis positions the series and the non-working days are painted between two of its
    // instants, so both have to agree on where a day begins and ends.
    const zone = this.timezoneService.userTimezone();

    return {
      maintainAspectRatio: false,
      interaction: { mode: 'series-at-x', intersect: false },
      scales: {
        x: {
          type: 'time',
          ...this.chartedRange(),
          adapters: { date: { zone } },
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
          intervals: this.parsedInput().nonWorkingIntervals,
          zone,
        },
        legend: {
          position: 'bottom',
          labels: {
            usePointStyle: true,
            pointStyleWidth: SWATCH_WIDTH,
            generateLabels: (chart) => this.legendLabels(chart),
          },
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
    };
  });

  // Everything the style holds but the swatch, which belongs to the legend, is already a dataset
  // property under its own name.
  private datasetFor(series:BurndownSeries):BurndownDataset {
    const { swatch: _swatch, color, ...dataset } = SERIES_STYLE[series.id];
    const datasetColor = color?.();

    return {
      label: series.label,
      data: series.data,
      ...SERIES_DEFAULTS,
      ...dataset,
      borderColor: datasetColor?.border,
      backgroundColor: datasetColor?.background,
    };
  }

  // For ongoing sprints, the remaining data series does not cover the whole of the graph.
  // There is a junction where the projection series takes over.
  // The tooltip's title is taken from remaining as long as possible and will only fall back
  // to projection. That way, the finer granularity is offered as long as it is available.
  // The remaining series has the finest granularity of all the data series (by hour - sometimes by day).
  private tooltipTitle(items:TooltipItem<'line'>[]):string {
    const at = (id:BurndownSeries['id']) => items.find((item) => this.seriesId(item.datasetIndex) === id);
    const dated = at('remaining') ?? at('projection') ?? items[0];

    return this.formattedTick(Number(dated.parsed.x));
  }

  // Ticks sit at the end of the period they carry, so 09:59:59.999 is what the 9 o'clock hour
  // left behind. Naming it 10:00 is what a reader expects. Hours are therefore rounded.
  // A day end must be truncated instead: rounding it would land on the following date.
  private formattedTick(timestamp:number):string {
    if (this.parsedInput().step === 'day') {
      return this.timezoneService.formattedDate(new Date(timestamp).toISOString());
    }

    const roundedToMinute = Math.round(timestamp / MINUTE_IN_MS) * MINUTE_IN_MS;

    return this.timezoneService.formattedDatetime(new Date(roundedToMinute).toISOString());
  }

  // Remaining is a sum of whole story points, while the two projected series divide them
  // across working days and would otherwise read to full float precision.
  private tooltipLabel(item:TooltipItem<'line'>):string {
    const value = this.seriesId(item.datasetIndex) === 'remaining'
      ? item.formattedValue
      : (item.parsed.y ?? 0).toLocaleString(undefined, { maximumFractionDigits: 1 });

    return `${item.dataset.label ?? ''}: ${value}`;
  }

  private legendLabels(chart:Chart):LegendItem[] {
    const labels:LegendItem[] = Chart.defaults.plugins.legend.labels.generateLabels(chart)
      .map((label) => ({ ...label, ...legendStyle(this.seriesId(label.datasetIndex)) }));

    if (this.parsedInput().nonWorkingIntervals.length > 0) {
      labels.push(this.nonWorkingLegendItem(chart));
    }

    return labels.sort((a, b) => this.legendRank(a) - this.legendRank(b));
  }

  private seriesId(datasetIndex:number|undefined):BurndownSeries['id']|undefined {
    return datasetIndex === undefined ? undefined : this.parsedInput().series[datasetIndex]?.id;
  }

  private nonWorkingLegendItem(chart:Chart):LegendItem {
    const bandColor = cssVariable('--borderColor-muted', '#d0d7de');

    return {
      text: this.i18n.t('js.burndown.non_working_day'),
      ...legendStyle(NON_WORKING_LEGEND_KEY),
      fillStyle: bandColor,
      strokeStyle: bandColor,
      hidden: this.nonWorkingOptions(chart).hidden ?? false,
    };
  }

  // The non-working days carry no dataset index, which is also how the toggle tells them apart.
  private legendRank(item:LegendItem):number {
    return item.datasetIndex === undefined
      ? seriesRank(NON_WORKING_LEGEND_KEY)
      : this.datasetRank(item.datasetIndex);
  }

  private datasetRank(datasetIndex:number):number {
    return seriesRank(this.seriesId(datasetIndex));
  }

  // The non-working days are drawn by a plugin rather than a dataset, so their entry carries no dataset
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
