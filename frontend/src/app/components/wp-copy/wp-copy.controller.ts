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
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";

export class WorkPackageCopyController extends WorkPackageCreateController {
  private __initialized_at:Number;
  private copiedWorkPackageId:string;

  private wpRelations:WorkPackageRelationsService = this.injector.get(WorkPackageRelationsService);
  protected wpEditing:WorkPackageEditingService = this.injector.get<WorkPackageEditingService>(IWorkPackageEditingServiceToken);

  ngOnInit() {
    super.ngOnInit();

    this.wpCreate.onNewWorkPackage()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((wp:WorkPackageResource) => {
        if (wp.__initialized_at === this.__initialized_at) {
          this.wpRelations.addCommonRelation(wp.id, 'relates', this.copiedWorkPackageId);
        }
      });
  }

  protected createdWorkPackage() {
    this.copiedWorkPackageId = this.stateParams.copiedFromWorkPackageId;
    return new Promise<WorkPackageChangeset>((resolve, reject) => {
      this.wpCacheService.loadWorkPackage(this.copiedWorkPackageId)
        .values$()
        .pipe(
          take(1)
        )
        .subscribe((wp:WorkPackageResource) => {
          this.createCopyFrom(wp).then(resolve, reject);
        });
    });
  }

  protected setTitle() {
    this.titleService.setFirstPart(this.I18n.t('js.work_packages.copy.title'));
  }

  private createCopyFrom(wp:WorkPackageResource) {
    return this.wpEditing
      .changesetFor(wp)
      .getForm()
      .then((form:any) =>
        this.wpCreate
          .copyWorkPackage(form, wp.project.identifier)
          .then((changeset) => {
            this.__initialized_at = changeset.workPackage.__initialized_at;

            this.wpCacheService.updateWorkPackage(changeset.workPackage);
            this.wpEditing.updateValue('new', changeset);

            return changeset;
        })
    );
  }
}
