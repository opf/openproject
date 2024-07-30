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

import { take } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCreateComponent } from 'core-app/features/work-packages/components/wp-new/wp-create.component';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';

import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { Directive } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@Directive()
export class WorkPackageCopyController extends WorkPackageCreateComponent {
  private __initialized_at:number;

  private copiedWorkPackageId:string;

  /** Are we in the copying substates ? */
  public copying = true;

  @InjectField() wpRelations:WorkPackageRelationsService;

  @InjectField() halEditing:HalResourceEditingService;

  ngOnInit() {
    super.ngOnInit();

    this.wpCreate.onNewWorkPackage()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((wp:WorkPackageResource) => {
        if (wp.__initialized_at === this.__initialized_at) {
          this.wpRelations.addCommonRelation(wp.id!, 'relates', this.copiedWorkPackageId);
        }
      });
  }

  protected createdWorkPackage() {
    this.copiedWorkPackageId = this.stateParams.copiedFromWorkPackageId;
    return new Promise<WorkPackageChangeset>((resolve, reject) => {
      this
        .apiV3Service
        .work_packages
        .id(this.copiedWorkPackageId)
        .get()
        .pipe(
          take(1),
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
    const sourceChangeset:WorkPackageChangeset = this.halEditing.changeFor(wp);

    return this.wpCreate
      .copyWorkPackage(sourceChangeset)
      .then((copyChangeset) => {
        this.__initialized_at = copyChangeset.pristineResource.__initialized_at;

        this
          .apiV3Service
          .work_packages
          .cache
          .updateWorkPackage(copyChangeset.pristineResource, true);

        this.halEditing.updateValue('new', copyChangeset);

        return copyChangeset;
      });
  }
}
