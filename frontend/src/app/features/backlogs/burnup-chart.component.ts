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
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import { generateId, getCSSVariable } from 'core-app/shared/helpers/dom-helpers';
import NonWorkingDaysPlugin, { nonWorkingDaysColor } from 'core-app/shared/components/charts/plugin.non-working-days';
import 'core-app/shared/components/charts/interaction.series-at-x';
import {
  NON_WORKING_KEY, NonWorkingKey, SeriesChartComponent, SeriesStyle,
} from 'core-app/shared/components/charts/component.series-chart';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';

type SeriesKey = 'completed'|'scope'|'projection'|'guideline';

function scopeColor():string {
  return getCSSVariable('--display-red-scale-6', '#c50d28');
}

const SERIES_STYLE:Record<SeriesKey|NonWorkingKey, SeriesStyle<SeriesKey>> = {
  completed: {
    swatch: 'rect',
    borderWidth: 1,
    order: 4,
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
  scope: {
    swatch: 'line',
    borderWidth: 2,
    order: 2,
    stepped: 'after',
    color: () => ({ border: scopeColor() }),
  },
  projection: {
    swatch: 'line',
    borderDash: [6, 4],
    borderWidth: 2,
    order: 3,
    color: () => ({ border: scopeColor() }),
  },
  guideline: {
    swatch: 'line',
    borderWidth: 2,
    order: 1,
    pointHoverRadius: 0,
    color: () => ({ border: getCSSVariable('--fgColor-muted', '#59636e') }),
  },
};

@Component({
  selector: 'op-burnup-chart',
  templateUrl: './burnup-chart.component.html',
  imports: [BaseChartDirective, NoResultsComponent],
  providers: [provideCharts(withDefaultRegisterables(NonWorkingDaysPlugin))],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BurnupChartComponent extends SeriesChartComponent<SeriesKey> {
  readonly chartDescriptionId = generateId('burnup-chart-description');
  readonly chartLabel = this.i18n.t('js.burnup_chart.chart_label');

  protected readonly seriesStyle = SERIES_STYLE;

  protected readonly interaction:ChartOptions<'line'>['interaction'] = { mode: 'series-at-x', intersect: false };

  readonly chartDescription = computed(() => this.describedByDay({
    summary: 'js.burnup_chart.chart_summary',
    day: 'js.burnup_chart.chart_day',
    value: 'js.burnup_chart.chart_value',
  }));

  protected override tooltipTitle(items:TooltipItem<'line'>[]):string {
    const itemFor = (id:SeriesKey) => items.find((item) => this.seriesId(item.datasetIndex) === id);
    const dated = itemFor('scope') ?? itemFor('completed') ?? itemFor('projection') ?? items.at(0);

    return dated ? this.formattedTick(dated) : '';
  }
}
