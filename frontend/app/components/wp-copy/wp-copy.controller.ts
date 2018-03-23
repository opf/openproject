// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {take} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageChangeset} from 'core-components/wp-edit-form/work-package-changeset';
import {WorkPackageCreateController} from 'core-components/wp-new/wp-create.controller';

export class WorkPackageCopyController extends WorkPackageCreateController {
  protected async newWorkPackageFromParams(stateParams:any) {
    return new Promise<WorkPackageChangeset>((resolve, reject) => {
      this.wpCacheService.loadWorkPackage(stateParams.copiedFromWorkPackageId)
        .values$()
        .pipe(
          take(1)
        )
        .subscribe(
          async (wp:WorkPackageResource) => this.createCopyFrom(wp).then(resolve),
          reject);
    });
  }

  private async createCopyFrom(wp:WorkPackageResource) {
    const changeset = this.wpEditing.changesetFor(wp);
    return changeset.getForm().then((form:any) => {
      return this.wpCreate.copyWorkPackage(form, wp.project.identifier);
    });
  }
}
