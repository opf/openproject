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
import {
  Chart, ChartData, ChartDataset, ChartOptions, LegendItem, PointStyle, TooltipItem,
} from 'chart.js';
import 'chartjs-adapter-luxon';
import moment from 'moment-timezone';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import NonWorkingDaysPlugin, {
  NonWorkingInterval, nonWorkingDaysColor,
} from 'core-app/shared/components/charts/plugin.non-working-days';
import 'core-app/shared/components/charts/interaction.series-at-x';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

interface BurndownPoint {
  x:string;
  y:number;
}

// The non-working days are one of these too, standing in for the bands a plugin paints. It brings
// no points, so chart.js draws nothing for it, but it earns the legend entry and the visibility
// that make it behave like the rest.
type SeriesKey = 'remaining'|'guideline'|'projection'|'non-working-days';

const NON_WORKING_KEY = 'non-working-days' satisfies SeriesKey;

interface BurndownSeries {
  id:SeriesKey;
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

// Chart.js takes a swatch shape per legend item but the decision to honour it at all is global,
// hence usePointStyle on the labels.
const SWATCH_WIDTH = 24;

interface SeriesColor {
  border:string;
  background?:string;
}

interface SeriesStyle {
  swatch:PointStyle;
  borderDash:number[];
  borderWidth:number;
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
      background: remainingColorBackground(),
    }),
  },
  projection: {
    swatch: 'line',
    borderDash: [6, 4],
    borderWidth: 1,
    order: 2,
    color: () => ({ border: remainingColor() }),
  },
  [NON_WORKING_KEY]: {
    swatch: 'rect',
    borderDash: [],
    borderWidth: 0,
    color: () => ({ border: nonWorkingDaysColor(), background: nonWorkingDaysColor() }),
  },
  guideline: {
    swatch: 'line',
    borderDash: [],
    borderWidth: 2,
    order: 1,
    pointHoverRadius: 0,
    color: () => ({ border: guidelineColor() }),
  },
};

function seriesRank(key:SeriesKey|undefined):number {
  const readingOrder = Object.keys(SERIES_STYLE);
  const rank = readingOrder.indexOf(key ?? '');

  return rank === -1 ? readingOrder.length : rank;
}

function legendStyle(key:SeriesKey|undefined):Partial<LegendItem> {
  if (key === undefined) {
    return {};
  }

  const { swatch, borderDash, borderWidth } = SERIES_STYLE[key];

  return { pointStyle: swatch, lineDash: borderDash, lineWidth: borderWidth };
}

// The projection continues the remaining series, so the two share a color.
function remainingColor():string {
  return getCSSVariable('--display-red-scale-6', '#c50d28');
}

function remainingColorBackground():string {
  return getCSSVariable('--display-red-scale-2', '#fda5a7');
}

function guidelineColor():string {
  return getCSSVariable('--fgColor-muted', '#59636e');
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
  readonly chartDescriptionId = generateId('burndown-chart-description');
  readonly chartLabel = this.i18n.t('js.burndown_chart.chart_label');

  private readonly parsedInput = computed(() => JSON.parse(this.chartData()) as BurndownChartData);

  // The non-working days join the series they are drawn among, without data points but present, so that the legend and
  // its toggle reach them through chart.js.
  private readonly series = computed<BurndownSeries[]>(() => {
    const { series, nonWorkingIntervals } = this.parsedInput();

    if (nonWorkingIntervals.length === 0) {
      return series;
    }

    return [...series, { id: NON_WORKING_KEY, label: this.i18n.t('js.burndown_chart.non_working_day'), data: [] }];
  });

  private readonly nonWorkingDatasetIndex = computed(() => {
    const index = this.series().findIndex((series) => series.id === NON_WORKING_KEY);

    return index === -1 ? undefined : index;
  });

  readonly hasChartData = computed(() => this.series().some((series) => series.data.length > 0));

  readonly lineChartData = computed<ChartData<'line', BurndownPoint[]>>(() => ({
    datasets: this.series().map((series) => this.datasetFor(series)),
  }));

  // Spoken a day at a time, however finely the series are sampled. Each one is reported by the
  // value it closed at, so an hourly Remaining series says what the day ended on rather than
  // reading out two dozen numbers, and a series sampled daily already has only that one.
  readonly chartDescription = computed(() => {
    const closing = this.closingValuesPerDay();
    const days = [...new Set(closing.flatMap(({ byDay }) => [...byDay.keys()]))].sort();

    const described = days.map((day, index) => {
      const values = closing.flatMap(({ label, byDay }) => {
        const value = byDay.get(day);

        return value === undefined
          ? []
          : this.i18n.t('js.burndown_chart.chart_value', { label, value: this.formatValue(value) });
      });

      return this.i18n.t('js.burndown_chart.chart_day', { day: index + 1, values: values.join(', ') });
    });

    return this.i18n.t('js.burndown_chart.chart_summary', { days: described.join('; ') });
  });

  // The series run ascending in x, so writing each point under its day leaves the last one written
  // -- the value the day closed at -- as the one that stands for it.
  private closingValuesPerDay():{ label:string, byDay:Map<string, number> }[] {
    const zone = this.timezoneService.userTimezone();

    return this.series()
      .filter((series) => series.data.length > 0)
      .map((series) => {
        const byDay = new Map<string, number>();

        series.data.forEach((point) => byDay.set(moment.tz(point.x, zone).format('YYYY-MM-DD'), point.y));

        return { label: series.label, byDay };
      });
  }

  // Both bounds are taken across every series, so that hiding one does not refit the axes to
  // what is left.
  private readonly chartedRange = computed(() => {
    const times = this.series().flatMap((series) => series.data.map((point) => Date.parse(point.x)));

    return times.length === 0 ? {} : { min: Math.min(...times), max: Math.max(...times) };
  });

  private readonly yAxisMaximum = computed(() => {
    const values = this.series().flatMap((series) => series.data.map((point) => point.y));

    return values.length === 0 ? undefined : Math.max(...values) * Y_AXIS_HEADROOM;
  });

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => {
    // The axis positions the series and the non-working days are painted between two of its
    // instants, so both have to agree on where a day begins and ends.
    const zone = this.timezoneService.userTimezone();

    const fontColor = getCSSVariable('--body-font-color', '#333333');
    const gridColor = getCSSVariable('--borderColor-muted', '#d0d7de');

    return {
      maintainAspectRatio: false,
      color: fontColor,
      interaction: { mode: 'series-at-x', intersect: false },
      scales: {
        x: {
          type: 'time',
          ...this.chartedRange(),
          adapters: { date: { zone } },
          time: { unit: 'day' },
          ticks: {
            color: fontColor,
            callback: (value:string|number) => this.formattedInstant(Number(value), this.timezoneService.getDateFormat()),
          },
          grid: { color: gridColor },
          border: { color: fontColor },
        },
        y: {
          title: { display: true, text: this.i18n.t('js.burndown_chart.story_points'), color: fontColor },
          ticks: { color: fontColor },
          grid: { color: gridColor },
          border: { color: fontColor },
          beginAtZero: true,
          suggestedMax: this.yAxisMaximum(),
        },
      },
      plugins: {
        // Registered globally by the other charts, it would otherwise reassign the colors
        // this chart sets deliberately, on every layout.
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
    const itemFor = (id:BurndownSeries['id']) => items.find((item) => this.seriesId(item.datasetIndex) === id);
    const dated = itemFor('remaining') ?? itemFor('projection') ?? items.at(0);

    return dated ? this.formattedTick(Number(dated.parsed.x)) : '';
  }

  // Ticks sit at the end of the period they describe, so 09:59:59.999 is what the 9 o'clock hour
  // left behind and 23:59:59.999 what the day did. The axis draws such a tick on the boundary it
  // closes, the hour as 10:00, the day as the date that follows.
  private formattedTick(timestamp:number):string {
    const roundedToMinute = Math.round(timestamp / MINUTE_IN_MS) * MINUTE_IN_MS;
    const dateFormat = this.timezoneService.getDateFormat();
    const format = this.parsedInput().step === 'day'
      ? dateFormat
      : `${dateFormat} ${this.timezoneService.getTimeFormat()}`;

    return this.formattedInstant(roundedToMinute, format);
  }

  // Said in the zone the reader picked in OpenProject, which the axis also positions by, so that
  // a label and the point under it name the same moment, however the browser is set.
  //
  // TimezoneService#formattedDate cannot do this: it parses through moment without a zone, which
  // lands on the browser's. That is right for the 'YYYY-MM-DD' strings it is meant for, where
  // there is no zone to apply, and wrong for an instant.
  private formattedInstant(timestamp:number, format:string):string {
    return moment.tz(timestamp, this.timezoneService.userTimezone()).format(format);
  }

  // Guideline and projection divide story points across working days, so they are cut to one
  // decimal. Remaining only ever holds whole story points, which this leaves as they are.
  private tooltipLabel(item:TooltipItem<'line'>):string {
    const value = (item.parsed.y ?? 0).toLocaleString(undefined, { maximumFractionDigits: 1 });

    return `${item.dataset.label ?? ''}: ${value}`;
  }

  private legendLabels(chart:Chart):LegendItem[] {
    return Chart.defaults.plugins.legend.labels.generateLabels(chart)
      .map((label) => ({ ...label, ...legendStyle(this.seriesId(label.datasetIndex)) }))
      .sort((a, b) => this.datasetRank(a.datasetIndex) - this.datasetRank(b.datasetIndex));
  }

  private seriesId(datasetIndex:number|undefined):SeriesKey|undefined {
    return datasetIndex === undefined ? undefined : this.series()[datasetIndex]?.id;
  }

  private datasetRank(datasetIndex:number|undefined):number {
    return seriesRank(this.seriesId(datasetIndex));
  }

  private formatValue(value:number):string {
    return new Intl.NumberFormat(this.i18n.locale, { maximumFractionDigits: 2 }).format(value);
  }
}
