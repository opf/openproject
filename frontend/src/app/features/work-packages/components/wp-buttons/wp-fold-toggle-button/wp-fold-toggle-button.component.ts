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

import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  template: `
    <op-action-menu wpGroupToggleDropdown [label]="label">
      <button class="button"
              id="wp-fold-toggle-button"
              type="button"
              opActionMenuTrigger
              opTooltip
              [label]="label">
        <op-icon icon-classes="button--icon icon-outline" />
        <span class="button--text"></span>
        <op-icon icon-classes="button--icon icon-small icon-pulldown" />
      </button>
    </op-action-menu>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-fold-toggle-view-button',
  standalone: false,
})
export class WorkPackageFoldToggleButtonComponent {
  readonly label = inject(I18nService).t('js.work_packages.label_collapse_expand_groups');
}
