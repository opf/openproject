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

import { ChangeDetectionStrategy, Component, computed } from '@angular/core';
import { ChartOptions, TooltipItem } from 'chart.js';
import moment from 'moment-timezone';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import NonWorkingDaysPlugin, { nonWorkingDaysColor } from 'core-app/shared/components/charts/plugin.non-working-days';
import 'core-app/shared/components/charts/interaction.series-at-x';
import {
  NON_WORKING_KEY, NonWorkingKey, SeriesChartComponent, SeriesStyle,
} from 'core-app/shared/components/charts/component.series-chart';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

type SeriesKey = 'remaining'|'guideline'|'projection';

// ORDER IS SIGNIFICANT: the legend and the tooltip read in the order these are declared, which
// is the order a reader meets them -- what is left, where that is heading, the days nothing was
// expected on, and what was planned. Reordering this list reorders both.
// It is not the order the lines are drawn in: datasets are drawn from the highest `order` down,
// so that the filled remaining area sits under the lines, which runs the other way.
const SERIES_STYLE:Record<SeriesKey|NonWorkingKey, SeriesStyle> = {
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
export class BurndownChartComponent extends SeriesChartComponent<SeriesKey> {
  readonly chartDescriptionId = generateId('burndown-chart-description');
  readonly chartLabel = this.i18n.t('js.burndown_chart.chart_label');

  protected readonly seriesStyle = SERIES_STYLE;

  protected readonly yAxisTitle = this.i18n.t('js.burndown_chart.story_points');

  protected readonly interaction:ChartOptions<'line'>['interaction'] = { mode: 'series-at-x', intersect: false };

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

  // For ongoing sprints, the remaining data series does not cover the whole of the graph.
  // There is a junction where the projection series takes over.
  // The tooltip's title is taken from remaining as long as possible and will only fall back
  // to projection. That way, the finer granularity is offered as long as it is available.
  // The remaining series has the finest granularity of all the data series (by hour - sometimes by day).
  protected override tooltipTitle(items:TooltipItem<'line'>[]):string {
    const itemFor = (id:SeriesKey) => items.find((item) => this.seriesId(item.datasetIndex) === id);
    const dated = itemFor('remaining') ?? itemFor('projection') ?? items.at(0);

    return dated ? this.formattedTick(dated) : '';
  }

  private formatValue(value:number):string {
    return new Intl.NumberFormat(this.i18n.locale, { maximumFractionDigits: 2 }).format(value);
  }
}
