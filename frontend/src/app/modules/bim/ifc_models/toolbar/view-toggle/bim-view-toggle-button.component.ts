// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {ChangeDetectionStrategy, Component} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {BimViewService} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";


@Component({
  template: `
    <ng-container *ngIf="(view$ | async) as current">
      <button class="button"
              id="bim-view-toggle-button"
              bimViewDropdown>
        <op-icon icon-classes="button--icon {{bimView.icon[current]}}"></op-icon>
        <span class="button--text"
              aria-hidden="true"
              [textContent]="bimView.text[current]">
        </span>
        <op-icon icon-classes="button--icon icon-small icon-pulldown"></op-icon>
      </button>
    </ng-container>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'bim-view-toggle-button'
})
export class BimViewToggleButtonComponent {

  view$ = this.bimView.view$;

  constructor(readonly I18n:I18nService,
              readonly bimView:BimViewService) {
  }
}
