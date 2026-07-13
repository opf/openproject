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

import {
  ChangeDetectionStrategy,
  Component,
  Signal,
  computed,
  inject,
  input,
} from '@angular/core';
import { ChartConfiguration, ChartData } from 'chart.js';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { chartFont, chartLegend, createPieTooltipRenderer } from 'core-app/shared/components/budget-graphs/chart.config';
import PrimerColorsPlugin from 'core-app/shared/components/work-package-graphs/plugin.primer-colors';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';

@Component({
  selector: 'opce-budget-by-cost-type',
  templateUrl: './budget-by-cost-type.component.html',
  imports: [BaseChartDirective],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [provideCharts(withDefaultRegisterables(PrimerColorsPlugin))],
})
export class BudgetByCostTypeComponent {
  private readonly i18n = inject(I18nService);

  readonly chartData = input.required<string>();
  readonly currency = input<string>('€');

  readonly pieChartData = computed<ChartData<'pie'>>(() => JSON.parse(this.chartData()) as ChartData<'pie'>);
  readonly hasChartData = computed(() => this.pieChartData().datasets[0].data.length > 0);

  readonly pieChartOptions:Signal<ChartConfiguration<'pie'>['options']> = computed<ChartConfiguration<'pie'>['options']>(() => ({
    font: chartFont,
    plugins: {
      ...chartLegend,
      'primer-colors': { labelBased: true },
      tooltip: {
        enabled: false,
        external: createPieTooltipRenderer(this.formatCurrency.bind(this)),
      },
    },
  }));

  private formatCurrency(value:number):string {
    const currency = this.currency();
    try {
      return new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency,
        maximumFractionDigits: 0,
      }).format(value);
    } catch {
      return `${new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(value)} ${currency}`;
    }
  }
}
