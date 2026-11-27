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

import {
  Directive, ViewContainerRef, inject, input, inputBinding,
} from '@angular/core';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import { ChartDescription } from 'core-app/shared/components/charts/description/chart-description';
import { ChartDescriptionContentComponent } from 'core-app/shared/components/charts/description/chart-description-content.component';

@Directive({
  selector: '[opChartDescription]',
  host: {
    role: 'img',
    '[attr.aria-label]': 'opChartDescription().label',
    '[attr.aria-describedby]': 'summaryId',
  },
})
export class ChartDescriptionDirective {
  readonly opChartDescription = input.required<ChartDescription>();

  protected readonly summaryId = generateId('op-chart-description-summary');

  private readonly content = inject(ViewContainerRef).createComponent(ChartDescriptionContentComponent, {
    bindings: [
      inputBinding('summaryId', () => this.summaryId),
      inputBinding('description', this.opChartDescription),
    ],
  });
}
