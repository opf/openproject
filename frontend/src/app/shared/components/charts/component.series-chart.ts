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

// What the sprint report's charts are, apart from the series they draw: a payload of time-stamped
// points over a window the server fixes, styled per series, with the non-working days among them,
// a legend and a tooltip that read in the same order, and the axes of `options.time-chart`.
//
// Shared rather than copied, for the same reason the axis skeleton is: two charts read side by
// side stop being comparable as soon as one of them orders, rounds or colors a little differently.
//
// What is left to a chart is what actually differs: its series keys and their styling, the
// interaction mode, the y axis title, and which point a tooltip takes its header from.

import { Directive, Signal, computed, inject, input } from '@angular/core';
import {
  Chart, ChartData, ChartDataset, ChartOptions, LegendItem, PointStyle, TooltipItem,
} from 'chart.js';
import 'chartjs-adapter-luxon';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { NonWorkingInterval } from 'core-app/shared/components/charts/plugin.non-working-days';
import { ChartStep, formattedTick, timeChartOptions } from 'core-app/shared/components/charts/options.time-chart';

export interface SeriesPoint {
  x:string;
  y:number;
}

// The non-working days are a series too, standing in for the bands a plugin paints. It brings no
// points, so chart.js draws nothing for it, but it earns the legend entry and the visibility that
// make it behave like the rest. A chart therefore names only its own keys and styles this one
// alongside them.
export const NON_WORKING_KEY = 'non-working-days';

export type NonWorkingKey = typeof NON_WORKING_KEY;

export interface ChartSeries<Key extends string> {
  id:Key;
  label:string;
  data:SeriesPoint[];
}

export interface ChartedRange {
  from:string;
  to:string;
}

export interface SeriesChartData<Key extends string> {
  step:ChartStep;
  range:ChartedRange;
  series:ChartSeries<Key>[];
  nonWorkingIntervals:NonWorkingInterval[];
}

export interface SeriesColor {
  border:string;
  background?:string;
}

export interface SeriesStyle {
  swatch:PointStyle;
  borderWidth:number;
  borderDash?:number[];
  order?:number;
  stepped?:'after';
  fill?:boolean;
  pointRadius?:number;
  pointHitRadius?:number;
  pointHoverRadius?:number;
  // Read on demand rather than held as a value: the colors come off the document, which at import
  // time has no stylesheet resolved yet for them to freeze against. Being a call does not make them
  // follow a theme switched afterwards -- that waits for the datasets to be built again.
  color?:() => SeriesColor;
}

// Keeps the tallest point clear of the top of the plot area.
const Y_AXIS_HEADROOM = 1.1;

// Chart.js takes a swatch shape per legend item but the decision to honor it at all is global,
// hence usePointStyle on the labels.
const SWATCH_WIDTH = 24;

// True of every line, and overridable by any of them: the points are never drawn, but they stay
// wide enough to be found by a cursor that is not exactly on one.
const SERIES_DEFAULTS:Omit<Partial<SeriesStyle>, 'swatch'|'color'> = {
  pointRadius: 0,
  pointHitRadius: 8,
};

@Directive()
export abstract class SeriesChartComponent<Key extends string> {
  readonly i18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);

  readonly chartData = input.required<string>();

  // Everything that tells the series apart, so that a line and its swatch cannot drift. The order
  // the entries are declared in is the order the legend and the tooltip read them in.
  protected abstract readonly seriesStyle:Record<Key|NonWorkingKey, SeriesStyle>;

  protected abstract readonly yAxisTitle:string;

  protected abstract readonly interaction:ChartOptions<'line'>['interaction'];

  protected readonly parsedInput = computed(() => JSON.parse(this.chartData()) as SeriesChartData<Key>);

  // The non-working days join the series they are drawn among, without data points but present, so
  // that the legend and its toggle reach them through chart.js.
  protected readonly series = computed<ChartSeries<Key|NonWorkingKey>[]>(() => {
    const { series, nonWorkingIntervals } = this.parsedInput();

    if (nonWorkingIntervals.length === 0) {
      return series;
    }

    return [...series, { id: NON_WORKING_KEY, label: this.i18n.t('js.sprint_charts.non_working_day'), data: [] }];
  });

  private readonly nonWorkingDatasetIndex = computed(() => {
    const index = this.series().findIndex((series) => series.id === NON_WORKING_KEY);

    return index === -1 ? undefined : index;
  });

  readonly hasChartData = computed(() => this.series().some((series) => series.data.length > 0));

  readonly lineChartData = computed<ChartData<'line', SeriesPoint[]>>(() => ({
    datasets: this.series().map((series) => this.datasetFor(series)),
  }));

  // The window the server charted, which the series need not fill: the burndown's guideline reaches
  // the planned finish while counts stop at the present moment. Taken from the data instead, two
  // charts of the same sprint would span different intervals.
  private readonly chartedRange = computed(() => {
    const { from, to } = this.parsedInput().range;

    return { min: Date.parse(from), max: Date.parse(to) };
  });

  private readonly yAxisMaximum = computed(() => {
    const values = this.series().flatMap((series) => series.data.map((point) => point.y));

    return values.length === 0 ? undefined : Math.max(...values) * Y_AXIS_HEADROOM;
  });

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => {
    // The axis positions the series and the non-working days are painted between two of its
    // instants, so both have to agree on where a day begins and ends.
    const zone = this.timezoneService.userTimezone();

    return {
      ...timeChartOptions({
        zone,
        range: this.chartedRange(),
        yTitle: this.yAxisTitle,
        suggestedMax: this.yAxisMaximum(),
        formatDate: (iso) => this.timezoneService.formattedDatetimeAsDate(iso),
      }),
      interaction: this.interaction,
      plugins: {
        // Registered globally by the other charts, it would otherwise reassign the colors
        // these charts set deliberately, on every layout.
        'primer-colors': { enabled: false },
        'non-working-days': {
          intervals: this.parsedInput().nonWorkingIntervals,
          zone,
          datasetIndex: this.nonWorkingDatasetIndex(),
        },
        legend: {
          position: 'bottom',
          labels: {
            usePointStyle: true,
            pointStyleWidth: SWATCH_WIDTH,
            generateLabels: (chart) => this.legendLabels(chart),
          },
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

  protected tooltipTitle(items:TooltipItem<'line'>[]):string {
    const dated = items.at(0);

    return dated ? this.formattedTick(dated) : '';
  }

  // Values divided across working days carry a fraction; counts and story points do not, and are
  // left as they are.
  protected tooltipLabel(item:TooltipItem<'line'>):string {
    const value = (item.parsed.y ?? 0).toLocaleString(undefined, { maximumFractionDigits: 1 });

    return `${item.dataset.label ?? ''}: ${value}`;
  }

  protected formattedTick(item:TooltipItem<'line'>):string {
    return formattedTick(Number(item.parsed.x), this.parsedInput().step, this.timezoneService);
  }

  protected seriesId(datasetIndex:number|undefined):Key|NonWorkingKey|undefined {
    return datasetIndex === undefined ? undefined : this.series()[datasetIndex]?.id;
  }

  // Everything the style holds but the swatch, which belongs to the legend, is already a dataset
  // property under its own name.
  private datasetFor(series:ChartSeries<Key|NonWorkingKey>):ChartDataset<'line', SeriesPoint[]> {
    const { swatch: _swatch, color, ...dataset } = this.seriesStyle[series.id];
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

  private legendLabels(chart:Chart):LegendItem[] {
    return Chart.defaults.plugins.legend.labels.generateLabels(chart)
      .map((label) => ({ ...label, ...this.legendStyle(this.seriesId(label.datasetIndex)) }))
      .sort((a, b) => this.datasetRank(a.datasetIndex) - this.datasetRank(b.datasetIndex));
  }

  private legendStyle(key:Key|NonWorkingKey|undefined):Partial<LegendItem> {
    if (key === undefined) {
      return {};
    }

    const { swatch, borderDash, borderWidth } = this.seriesStyle[key];

    return { pointStyle: swatch, lineDash: borderDash ?? [], lineWidth: borderWidth };
  }

  private datasetRank(datasetIndex:number|undefined):number {
    return this.seriesRank(this.seriesId(datasetIndex));
  }

  private seriesRank(key:Key|NonWorkingKey|undefined):number {
    const readingOrder = Object.keys(this.seriesStyle);
    const rank = readingOrder.indexOf(key ?? '');

    return rank === -1 ? readingOrder.length : rank;
  }
}
