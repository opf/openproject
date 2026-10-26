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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import NonWorkingDaysPlugin, {
  NonWorkingInterval, nonWorkingDaysColor,
} from 'core-app/shared/components/charts/plugin.non-working-days';
import { ChartStep, formattedTick, timeChartOptions } from 'core-app/shared/components/charts/options.time-chart';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

interface CountPoint {
  x:string;
  y:number;
}

// The non-working days are one of these too, standing in for the bands a plugin paints. It brings
// no points, so chart.js draws nothing for it, but it earns the legend entry and the visibility
// that make it behave like the rest.
type SeriesKey = 'created'|'resolved'|'non-working-days';

const NON_WORKING_KEY = 'non-working-days' satisfies SeriesKey;

interface CountSeries {
  id:SeriesKey;
  label:string;
  data:CountPoint[];
}

type CountDataset = ChartDataset<'line', CountPoint[]>;

interface ChartedRange {
  from:string;
  to:string;
}

interface CreatedResolvedChartData {
  step:ChartStep;
  range:ChartedRange;
  series:CountSeries[];
  nonWorkingIntervals:NonWorkingInterval[];
}

// Keeps the tallest step clear of the top of the plot area.
const Y_AXIS_HEADROOM = 1.1;

// Chart.js takes a swatch shape per legend item but the decision to honour it at all is global,
// hence usePointStyle on the labels.
const SWATCH_WIDTH = 24;

interface SeriesColor {
  border:string;
  background:string;
}

interface SeriesStyle {
  swatch:PointStyle;
  borderWidth:number;
  order?:number;
  stepped?:'after';
  fill?:boolean;
  pointRadius?:number;
  pointHitRadius?:number;
  // Read on demand rather than held as a value: the colors come off the document, which at import
  // time has no stylesheet resolved yet for them to freeze against.
  color:() => SeriesColor;
}

// True of both counted series: the points are never drawn, but they stay wide enough to be found
// by a cursor that is not exactly on one.
const SERIES_DEFAULTS:Omit<Partial<SeriesStyle>, 'swatch'|'color'> = {
  pointRadius: 0,
  pointHitRadius: 8,
};

// Everything that tells the series apart, so that a line and its swatch cannot drift.
//
// ORDER IS SIGNIFICANT: the legend and the tooltip read in the order these are declared. It is
// not the order the lines are drawn in -- resolved never exceeds created, so it takes the lower
// `order` to be drawn on top and stay visible.
//
// A count is a step function: four work packages hold from the moment the fourth arrived until
// the fifth does, so both series are stepped rather than interpolated through counts that never
// existed.
const SERIES_STYLE:Record<SeriesKey, SeriesStyle> = {
  created: {
    swatch: 'rect',
    borderWidth: 1,
    order: 1,
    stepped: 'after',
    fill: true,
    color: () => ({
      border: getCSSVariable('--display-red-scale-4', '#e5484d'),
      background: getCSSVariable('--display-red-scale-2', '#fda5a7'),
    }),
  },
  resolved: {
    swatch: 'rect',
    borderWidth: 1,
    order: 0,
    stepped: 'after',
    fill: true,
    color: () => ({
      border: getCSSVariable('--display-green-scale-4', '#30a46c'),
      background: getCSSVariable('--display-green-scale-2', '#b1efc8'),
    }),
  },
  [NON_WORKING_KEY]: {
    swatch: 'rect',
    borderWidth: 0,
    color: () => ({ border: nonWorkingDaysColor(), background: nonWorkingDaysColor() }),
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

  const { swatch, borderWidth } = SERIES_STYLE[key];

  return { pointStyle: swatch, lineWidth: borderWidth };
}

@Component({
  selector: 'op-created-resolved-chart',
  templateUrl: './created-resolved-chart.component.html',
  imports: [BaseChartDirective, NoResultsComponent],
  providers: [provideCharts(withDefaultRegisterables(NonWorkingDaysPlugin))],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CreatedResolvedComponent {
  readonly i18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);

  readonly chartData = input.required<string>();

  private readonly parsedInput = computed(() => JSON.parse(this.chartData()) as CreatedResolvedChartData);

  // The non-working days join the series they are drawn among, without data points but present,
  // so that the legend and its toggle reach them through chart.js.
  private readonly series = computed<CountSeries[]>(() => {
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

  readonly lineChartData = computed<ChartData<'line', CountPoint[]>>(() => ({
    datasets: this.series().map((series) => this.datasetFor(series)),
  }));

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
        yTitle: this.i18n.t('js.created_resolved_chart.work_packages'),
        suggestedMax: this.yAxisMaximum(),
        formatDate: (iso) => this.timezoneService.formattedDatetimeAsDate(iso),
      }),
      // Both series are counted at the same ticks, so they share every x value, which is what
      // index matching needs. The burndown reaches for 'series-at-x' because its series are
      // sampled at different rates; these are not.
      interaction: { mode: 'index', intersect: false },
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
          },
        },
      },
    };
  });

  // Everything the style holds but the swatch, which belongs to the legend, is already a dataset
  // property under its own name.
  private datasetFor(series:CountSeries):CountDataset {
    const { swatch: _swatch, color, ...dataset } = SERIES_STYLE[series.id];
    const { border, background } = color();

    return {
      label: series.label,
      data: series.data,
      ...SERIES_DEFAULTS,
      ...dataset,
      borderColor: border,
      backgroundColor: background,
    };
  }

  private tooltipTitle(items:TooltipItem<'line'>[]):string {
    const dated = items.at(0);

    return dated ? formattedTick(Number(dated.parsed.x), this.parsedInput().step, this.timezoneService) : '';
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
}
