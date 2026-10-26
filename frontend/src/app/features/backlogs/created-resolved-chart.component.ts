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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ChartOptions } from 'chart.js';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import NonWorkingDaysPlugin, { nonWorkingDaysColor } from 'core-app/shared/components/charts/plugin.non-working-days';
import {
  NON_WORKING_KEY, NonWorkingKey, SeriesChartComponent, SeriesStyle,
} from 'core-app/shared/components/charts/component.series-chart';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

type SeriesKey = 'created'|'resolved';

// ORDER IS SIGNIFICANT: the legend and the tooltip read in the order these are declared. It is
// not the order the lines are drawn in -- resolved never exceeds created, so it takes the lower
// `order` to be drawn on top and stay visible.
//
// A count is a step function: four work packages hold from the moment the fourth arrived until
// the fifth does, so both series are stepped rather than interpolated through counts that never
// existed.
const SERIES_STYLE:Record<SeriesKey|NonWorkingKey, SeriesStyle> = {
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

@Component({
  selector: 'op-created-resolved-chart',
  templateUrl: './created-resolved-chart.component.html',
  imports: [BaseChartDirective, NoResultsComponent],
  providers: [provideCharts(withDefaultRegisterables(NonWorkingDaysPlugin))],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CreatedResolvedComponent extends SeriesChartComponent<SeriesKey> {
  protected readonly seriesStyle = SERIES_STYLE;

  protected readonly yAxisTitle = this.i18n.t('js.created_resolved_chart.work_packages');

  // Both series are counted at the same ticks, so they share every x value, which is what index
  // matching needs. The burndown reaches for 'series-at-x' because its series are sampled at
  // different rates; these are not.
  protected readonly interaction:ChartOptions<'line'>['interaction'] = { mode: 'index', intersect: false };
}
