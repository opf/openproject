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
import { generateId } from 'core-app/shared/helpers/dom-helpers';

@Component({
  template: `
    <button type="button"
       [attr.id]="buttonId"
       [attr.aria-labelledby]="tooltipId"
       class="button refresh-button"
       (click)="refresh()">
      <op-icon icon-classes="button--icon icon-workflow" />
    </button>
    <tool-tip
      class="sr-only position-absolute"
      [attr.for]="buttonId"
      [attr.id]="tooltipId"
      popover="manual"
      data-direction="s"
      data-type="label"
      [textContent]="text.refresh_hover"
      />
  `,
  selector: 'op-refresh-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class RefreshButtonComponent {
  readonly I18n = inject(I18nService);

  readonly buttonId = generateId('refresh-button');

  readonly tooltipId = generateId('tooltip');

  public text = {
    refresh: this.I18n.t('js.bcf.refresh'),
    refresh_hover: this.I18n.t('js.bcf.refresh_work_package'),
  };

  refresh() {
    window.location.reload();
  }
}
