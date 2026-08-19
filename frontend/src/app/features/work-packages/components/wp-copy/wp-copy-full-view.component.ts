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
import { WorkPackageCopyController } from 'core-app/features/work-packages/components/wp-copy/wp-copy.controller';

@Component({
  selector: 'wp-copy-full-view',
  host: { class: 'work-packages-page--ui-view' },
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: '../wp-new/wp-new-full-view.html',
  standalone: false,
})
export class WorkPackageCopyFullViewComponent extends WorkPackageCopyController {
  public successState = 'work-packages.show';

  breadcrumbItems() {
    const items = [];
    if (this.currentProjectService?.identifier) {
      items.push({
        href: this.pathHelper.projectPath(this.currentProjectService.identifier),
        text: this.currentProjectService.name,
      });
    }
    items.push({
        href: this.pathHelper.workPackagesPath(this.currentProjectService.identifier),
        text: this.I18n.t('js.label_work_package_plural'),
      });
    items.push({
        href: this.pathHelper.projectWorkPackagePath(this.currentProjectService.identifier!, this.stateParams.copiedFromWorkPackageId as string),
        text: this.newWorkPackage.subject,
      });
    items.push(I18n.t('js.button_duplicate'));

    return items;
  }
}
