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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { JsonPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, Signal, computed, inject, input } from '@angular/core';
import { ChartData, ChartOptions } from 'chart.js';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NoResultsComponent } from 'core-app/shared/components/blankslate/no-results.component';
import PrimerColorsPlugin from 'core-app/shared/components/work-package-graphs/plugin.primer-colors';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { environment } from '../../../environments/environment';

const BURNDOWN_Y_SCALE_MIN = 25;

@Component({
  selector: 'op-burndown-chart',
  templateUrl: './burndown-chart.component.html',
  imports: [BaseChartDirective, JsonPipe, NoResultsComponent],
  providers: [provideCharts(withDefaultRegisterables(PrimerColorsPlugin))],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BurndownChartComponent {
  readonly isDevMode = !environment.production;
  readonly i18n = inject(I18nService);
  readonly chartData = input.required<string>();

  readonly lineChartData = computed<ChartData<'line'>>(() => {
    const data = JSON.parse(this.chartData()) as ChartData<'line'>;
    return data;
  });

  readonly hasChartData = computed(() =>
    this.lineChartData().datasets.some((ds) => ds.data.length > 0)
  );

  readonly maxValue = computed(() => {
    return this.lineChartData().datasets
      .flatMap((dataset) => dataset.data)
      .filter((item):item is number => typeof item === 'number')
      .reduce((a, b) => Math.max(a, b), 0);
  });

  readonly lineChartOptions:Signal<ChartOptions<'line'>> = computed<ChartOptions<'line'>>(() => ({
    scales: {
      x: {
        title: {
          display: true,
          text: this.i18n.t('js.burndown.day')
        }
      },
      y: {
        title: {
          display: true,
          text: this.i18n.t('js.burndown.points')
        },
        suggestedMin: 0,
        max: this.maxValue() + BURNDOWN_Y_SCALE_MIN
      }
    },
    plugins: {
      legend: {
        position: 'top'
      }
    }
  }));
}
