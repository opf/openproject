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

import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TooltipDirection } from './tooltip-direction';

export type TooltipType = 'label' | 'description';

@Component({
  selector: 'tool-tip[op-tooltip]',
  template: '{{ text() }}',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'sr-only position-absolute',
    popover: 'manual',
    '[attr.data-type]': 'type()',
    '[attr.data-direction]': 'direction()',
    '[attr.aria-hidden]': "type() === 'label' ? 'true' : null",
    '[attr.id]': 'tooltipId()',
    '[attr.for]': 'forId()',
  },
})
export class OpTooltipComponent {
  readonly forId = input.required<string>();
  readonly tooltipId = input.required<string>();
  readonly type = input.required<TooltipType>();
  readonly direction = input.required<TooltipDirection>();
  readonly text = input.required<string>();
}
