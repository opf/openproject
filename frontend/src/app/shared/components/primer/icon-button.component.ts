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

/* eslint-disable @angular-eslint/component-selector, @angular-eslint/no-input-rename */

import { booleanAttribute, ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import { IconModule } from '../icon/icon.module';
import { AbstractBaseButtonDirective } from './abstract-base-button.directive';
import { PrimerBaseButtonDirective } from './base-button.directive';
import { DynamicIconDirective } from './dynamic-icon.directive';
import { TooltipDirection } from './tooltip-direction';
import { OpTooltipDirective } from './tooltip.directive';

type Scheme = 'default' | 'primary' | 'secondary' | 'danger' | 'invisible';
type Size = 'small' | 'medium' | 'large';

@Component({
  selector: 'primer-icon-button',
  templateUrl: './icon-button.component.html',
  imports: [PrimerBaseButtonDirective, OpTooltipDirective, DynamicIconDirective, IconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PrimerIconButtonComponent extends AbstractBaseButtonDirective {
  readonly buttonId = input(generateId('icon-button'));
  readonly buttonClass = input('', { alias: 'button-class' });

  readonly icon = input.required<string>();
  readonly scheme = input<Scheme>('default');
  readonly size = input<Size>('medium');

  /**
   * String that can be read by assistive technology. A label should be short
   * and concise. See the accessibility section for more information.
   */
  readonly label = input.required<string>();

  /**
   * String that can be read by assistive technology. A description can be
   * longer as it is intended to provide more context and information. See the
   * accessibility section for more information.
   */
  readonly description = input<string>();

  /**
   * Whether or not to show a tooltip when this button is hovered. Tooltips
   * should only be hidden if the aria label is redundant, i.e. if the icon has
   * a widely understood definition.
   *
   * @default true
   */
  readonly showTooltip = input(true, { transform: booleanAttribute });
  readonly tooltipId = input(generateId('tooltip'));
  readonly tooltipDirection = input<TooltipDirection>('s', { alias: 'tooltip-direction' });

  readonly clicked = output();
}
