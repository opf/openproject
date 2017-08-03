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

import {wpDirectivesModule} from "../../angular-modules";
import {scopedObservable} from "../../helpers/angular-rx-utils";
import {WorkPackageResourceInterface} from "../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageCreateController} from "../wp-create/wp-create.controller";
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';

export class WorkPackageCopyController extends WorkPackageCreateController {
  protected newWorkPackageFromParams(stateParams:any) {
    var deferred = this.$q.defer();

    scopedObservable(
      this.$scope,
      this.wpCacheService.loadWorkPackage(stateParams.copiedFromWorkPackageId).values$())
      .take(1)
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.createCopyFrom(wp).then((changeset:WorkPackageChangeset) => {
          deferred.resolve(changeset);
        });
      });

    return deferred.promise;
  }

  private createCopyFrom(wp:WorkPackageResourceInterface) {
    const changeset = this.wpEditing.changesetFor(wp);
    return changeset.getForm().then((form:any) => {
      return this.wpCreate.copyWorkPackage(form, wp.project.identifier);
    });
  }
}

wpDirectivesModule.controller('WorkPackageCopyController', WorkPackageCopyController);
