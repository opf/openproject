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
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { jsonAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';
import { NonWorkingInterval } from 'core-app/shared/components/charts/plugin.non-working-days';
import { ChartDescription, ChartDescriptionRow } from 'core-app/shared/components/charts/description/chart-description';
import { calendarDate, calendarDaysSpanned, weekStartDate } from 'core-common/local-datetime';
import {
  ChartStep, YTicks, formattedTick, timeChartOptions,
} from 'core-app/shared/components/charts/options.time-chart';

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
  unit?:'story_points'|'time';
  step:ChartStep;
  range:ChartedRange;
  series:ChartSeries<Key>[];
  nonWorkingIntervals?:NonWorkingInterval[];
}

export interface SeriesColor {
  border:string;
  background?:string;
}

// Define how to paint the area between this series and another one. Depending on whether which series is ahead,
// a different color can be chosen. The colors are read on demand for the reason the series colors are.
export interface SeriesBand<Key extends string> {
  to:Key;
  above:() => string;
  below:() => string;
}

export interface SeriesStyle<Key extends string = string> {
  swatch:PointStyle;
  borderWidth:number;
  borderDash?:number[];
  order?:number;
  stepped?:'after';
  fill?:boolean;
  band?:SeriesBand<Key>;
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

const MAX_DAILY_SPAN_IN_DAYS = 31;

type Period = 'day'|'week';

const PERIOD_COLUMN_KEYS = {
  day: 'js.chart.description.date',
  week: 'js.chart.description.week',
} satisfies Record<Period, string>;

// True of every line, and overridable by any of them: the points are never drawn, but they stay
// wide enough to be found by a cursor that is not exactly on one. Chart.js reads a missing `fill`
// off the background color, so a line that is not meant to fill has to say so.
const SERIES_DEFAULTS:Omit<Partial<SeriesStyle>, 'swatch'|'color'> = {
  pointRadius: 0,
  pointHitRadius: 8,
  fill: false,
};

const EMPTY_SERIES_CHART_DATA:SeriesChartData<never> = {
  step: 'day',
  range: { from: '1970-01-01T00:00:00.000Z', to: '1970-01-01T00:00:00.000Z' },
  series: [],
};

@Directive()
export abstract class SeriesChartComponent<Key extends string> {
  readonly i18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);
  readonly configurationService = inject(ConfigurationService);

  readonly chartData = input<SeriesChartData<Key>, SeriesChartData<Key>|string|null|undefined>(EMPTY_SERIES_CHART_DATA, {
    transform: jsonAttribute<SeriesChartData<Key>>(EMPTY_SERIES_CHART_DATA),
  });

  // Everything that tells the series apart, so that a line and its swatch cannot drift. The order
  // the entries are declared in is the order the legend and the tooltip read them in. A chart
  // drawn over a span too long for single days to mean anything leaves the non-working ones out.
  protected abstract readonly seriesStyle:Record<Key, SeriesStyle<Key>>
  & Partial<Record<NonWorkingKey, SeriesStyle<Key>>>;

  protected get yAxisTitle():string {
    return this.i18n.t(`js.sprint_charts.y_axis_title.${this.chartData().unit ?? 'story_points'}`);
  }

  protected abstract readonly chartLabel:string;

  // Series whose label already names the unit, which the description would otherwise repeat.
  protected readonly seriesNamingUnit:ReadonlySet<string> = new Set();

  protected abstract readonly interaction:ChartOptions<'line'>['interaction'];

  protected readonly nonWorkingIntervals = computed(() => this.chartData().nonWorkingIntervals ?? []);

  // The non-working days join the series they are drawn among, without data points but present, so
  // that the legend and its toggle reach them through chart.js. Only for a chart that styled them:
  // the rest have nothing to put in that legend entry and nothing to paint under it.
  protected readonly series = computed<ChartSeries<Key|NonWorkingKey>[]>(() => {
    const { series } = this.chartData();

    if (this.nonWorkingIntervals().length === 0 || this.seriesStyle[NON_WORKING_KEY] === undefined) {
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
    const { from, to } = this.chartData().range;

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
        yTicks: this.yTicks(),
        suggestedMax: this.yAxisMaximum(),
        formatDate: (iso) => this.timezoneService.formattedDatetimeAsDate(iso),
      }),
      interaction: this.interaction,
      plugins: {
        // Registered globally by the other charts, it would otherwise reassign the colors
        // these charts set deliberately, on every layout.
        'primer-colors': { enabled: false },
        'non-working-days': {
          intervals: this.nonWorkingIntervals(),
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

  protected readonly description = computed<ChartDescription>(() => {
    const label = this.chartLabel;
    const described = this.series()
      .filter((series) => series.data.length > 0)
      .sort((a, b) => this.seriesRank(a.id) - this.seriesRank(b.id));
    const { from, to } = this.chartData().range;
    const period = this.periodOf();
    const latest = described.map((series) => this.i18n.t('js.sprint_charts.description_value', {
      label: series.label,
      value: this.describedValue(series, series.data[series.data.length - 1].y),
    }));

    return {
      label,
      summary: this.i18n.t('js.sprint_charts.description_summary', {
        label,
        from: this.formattedDay(from),
        to: this.formattedDay(to),
        values: latest.join(', '),
      }),
      table: {
        caption: this.i18n.t('js.chart.description.caption', { label }),
        columns: [
          this.i18n.t(PERIOD_COLUMN_KEYS[period]),
          ...described.map((series) => this.columnHeader(series)),
        ],
        rows: this.periodRows(described, period),
      },
    };
  });

  protected tooltipTitle(items:TooltipItem<'line'>[]):string {
    const dated = items.at(0);

    return dated ? this.formattedTick(dated) : '';
  }

  protected tooltipLabel(item:TooltipItem<'line'>):string {
    return `${item.dataset.label ?? ''}: ${this.formatValue(item.parsed.y ?? 0)}`;
  }

  private namesUnitFor(series:ChartSeries<Key|NonWorkingKey>):boolean {
    return this.chartData().unit === 'story_points' && !this.seriesNamingUnit.has(series.id);
  }

  private columnHeader(series:ChartSeries<Key|NonWorkingKey>):string {
    if (!this.namesUnitFor(series)) {
      return series.label;
    }

    const unit = this.i18n.t('js.sprint_charts.unit.story_points');

    return this.i18n.t('js.sprint_charts.column_with_unit', { label: series.label, unit });
  }

  private describedValue(series:ChartSeries<Key|NonWorkingKey>, value:number):string {
    if (!this.namesUnitFor(series)) {
      return this.formatValue(value);
    }

    return this.i18n.t('js.sprint_charts.value_with_unit.story_points', { count: value, value: this.formatValue(value) });
  }

  private formatValue(value:number):string {
    if (this.chartData().unit === 'time') {
      return this.timezoneService.formattedChronicDurationFromHours(value);
    }

    return new Intl.NumberFormat(this.i18n.locale, { maximumFractionDigits: 2 }).format(value);
  }

  private yTicks():YTicks {
    if (this.chartData().unit === 'time') {
      return { stepSize: this.configurationService.hoursPerDay(), format: (value) => this.formatValue(value) };
    }

    return {};
  }

  protected formattedTick(item:TooltipItem<'line'>):string {
    return formattedTick(Number(item.parsed.x), this.chartData().step, this.timezoneService);
  }

  protected seriesId(datasetIndex:number|undefined):Key|NonWorkingKey|undefined {
    return datasetIndex === undefined ? undefined : this.series()[datasetIndex]?.id;
  }

  private periodOf():Period {
    const zone = this.timezoneService.userTimezone();
    const { from, to } = this.chartData().range;
    const firstDay = calendarDate(from, zone);
    const lastDay = calendarDate(to, zone);
    const spanned = firstDay === null || lastDay === null ? null : calendarDaysSpanned(firstDay, lastDay);

    return spanned !== null && spanned > MAX_DAILY_SPAN_IN_DAYS ? 'week' : 'day';
  }

  private formattedDay(instant:string):string {
    const day = calendarDate(instant, this.timezoneService.userTimezone());

    return day === null ? this.timezoneService.formattedDatetimeAsDate(instant) : this.timezoneService.formattedDate(day);
  }

  // Each series is reported by the value it closed the period at, so an hourly series says what
  // the day (or week) ended on rather than reading out every sample.
  private periodRows(described:ChartSeries<Key|NonWorkingKey>[], period:Period):ChartDescriptionRow[] {
    const zone = this.timezoneService.userTimezone();
    const firstDayOfWeek = period === 'week' ? this.configurationService.startOfWeek() : undefined;
    const periodKey = (instant:string):string|null => {
      const day = calendarDate(instant, zone);

      return day === null || firstDayOfWeek === undefined ? day : weekStartDate(day, firstDayOfWeek);
    };
    const closing = described.map((series) => {
      const byPeriod = new Map<string, number>();
      series.data.forEach((point) => {
        const key = periodKey(point.x);

        if (key !== null) {
          byPeriod.set(key, point.y);
        }
      });
      return byPeriod;
    });
    const periods = [...new Set(closing.flatMap((byPeriod) => [...byPeriod.keys()]))].sort();

    return periods.map((key) => ({
      header: this.timezoneService.formattedDate(key),
      cells: closing.map((byPeriod) => {
        const value = byPeriod.get(key);
        return value === undefined ? '' : this.formatValue(value);
      }),
    }));
  }

  // Everything the style holds but the swatch, which belongs to the legend, is already a dataset
  // property under its own name.
  private datasetFor(series:ChartSeries<Key|NonWorkingKey>):ChartDataset<'line', SeriesPoint[]> {
    const {
      swatch: _swatch, color, band, ...dataset
    } = this.seriesStyle[series.id];
    const datasetColor = color?.();

    return {
      label: series.label,
      data: series.data,
      ...SERIES_DEFAULTS,
      ...dataset,
      ...this.bandFill(band),
      borderColor: datasetColor?.border,
      backgroundColor: datasetColor?.background,
    };
  }

  private bandFill(band:SeriesBand<Key>|undefined):Pick<ChartDataset<'line'>, 'fill'>|undefined {
    if (band === undefined) {
      return undefined;
    }

    const target = this.series().findIndex((series) => series.id === band.to);

    return { fill: target === -1 ? false : { target, above: band.above(), below: band.below() } };
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
