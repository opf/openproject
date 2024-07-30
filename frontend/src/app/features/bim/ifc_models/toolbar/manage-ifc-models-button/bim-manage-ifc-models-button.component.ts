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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';

@Component({
  template: `
    <a *ngIf="manageAllowed"
       class="button"
       [href]="manageIFCPath">
      <op-icon icon-classes="button--icon icon-settings2"></op-icon>
      <span class="button--text"
            [textContent]="text.manage"
            aria-hidden="true"></span>
    </a>

  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-bcf-manage-ifc-button',
})
export class BimManageIfcModelsButtonComponent {
  text = {
    manage: this.I18n.t('js.ifc_models.models.ifc_models'),
  };

  manageAllowed = this.ifcData.allowed('manage_ifc_models');

  manageIFCPath = this.ifcData.manageIFCPath;

  constructor(readonly I18n:I18nService,
    readonly ifcData:IfcModelsDataService) {
  }
}
