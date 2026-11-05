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

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-add-to-planner-button',
  templateUrl: './wp-add-to-planner-button.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageAddToPlannerButtonComponent {
  readonly I18n = inject(I18nService);
  readonly pathHelper = inject(PathHelperService);

  @Input() public workPackage:WorkPackageResource;

  public buttonTitle = this.I18n.t('js.planner.add_to_planner');

  get dialogPath():string {
    const query = new URLSearchParams({ work_package_id: this.workPackage.id! });
    return `${this.pathHelper.staticBase}/planner/tasks/new_dialog?${query.toString()}`;
  }
}
