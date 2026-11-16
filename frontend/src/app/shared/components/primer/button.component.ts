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
import { PrimerIconButtonScheme } from './icon-button.component';

export type PrimerButtonScheme = PrimerIconButtonScheme|'link';
type Size = 'small'|'medium'|'large';

@Component({
  selector: 'button[primerButton]',
  templateUrl: './button.component.html',
  imports: [DynamicIconDirective, IconModule],
  hostDirectives: [
    { directive: PrimerBaseButtonDirective, inputs: ['type', 'block', 'disabled', 'inactive'] },
  ],
  host: {
    class: 'Button',
    '[class.Button--small]': "size() === 'small'",
    '[class.Button--medium]': "size() === 'medium'",
    '[class.Button--large]': "size() === 'large'",
    '[class.Button--primary]': "scheme() === 'primary'",
    '[class.Button--secondary]': "scheme() === 'default' || scheme() === 'secondary'",
    '[class.Button--danger]': "scheme() === 'danger'",
    '[class.Button--invisible]': "scheme() === 'invisible'",
    '[class.Button--link]': "scheme() === 'link'",
  },
})
export class PrimerButtonComponent {
  readonly scheme = input<PrimerButtonScheme>('default');
  readonly size = input<Size>('medium');
  readonly leadingIcon = input<DynamicIconName>();
}
