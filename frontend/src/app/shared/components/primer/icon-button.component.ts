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

/* eslint-disable @angular-eslint/component-selector */

import { Component, input } from '@angular/core';
import { IconModule } from '../icon/icon.module';
import { PrimerBaseButtonDirective } from './base-button.directive';
import { DynamicIconName } from './dynamic-icon-map';
import { DynamicIconDirective } from './dynamic-icon.directive';
import { OpTooltipDirective } from './tooltip.directive';

export type PrimerIconButtonScheme = 'default' | 'primary' | 'secondary' | 'danger' | 'invisible';
type Size = 'small' | 'medium' | 'large';

@Component({
  selector: 'button[primerIconButton]',
  template: '<svg octicon size="small" class="Button-visual" [icon]="icon()"></svg>',
  imports: [DynamicIconDirective, IconModule],
  hostDirectives: [
    { directive: PrimerBaseButtonDirective, inputs: ['type', 'block', 'disabled', 'inactive'] },
    { directive: OpTooltipDirective, inputs: ['label', 'description', 'showTooltip', 'tooltipId', 'tooltip-direction'] },
  ],
  host: {
    class: 'Button Button--iconOnly',
    '[class.Button--small]': "size() === 'small'",
    '[class.Button--medium]': "size() === 'medium'",
    '[class.Button--large]': "size() === 'large'",
    '[class.Button--primary]': "scheme() === 'primary'",
    '[class.Button--secondary]': "scheme() === 'default' || scheme() === 'secondary'",
    '[class.Button--danger]': "scheme() === 'danger'",
    '[class.Button--invisible]': "scheme() === 'invisible'",
  },
})
export class PrimerIconButtonComponent {
  readonly icon = input.required<DynamicIconName>();
  readonly scheme = input<PrimerIconButtonScheme>('default');
  readonly size = input<Size>('medium');

  /**
   * Names the button for assistive technology, as its only content is an
   * icon. Shown as a tooltip unless `showTooltip` is false.
   */
  readonly label = input.required<string>();
}
