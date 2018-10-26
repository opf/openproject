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

import {Component} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageInlineCreateComponent} from "core-components/wp-inline-create/wp-inline-create.component";
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";

@Component({
  templateUrl: './wp-inline-add-existing-child.component.html'
})
export class WorkPackageInlineAddExistingChildComponent {
  public selectedWpId:string;
  public isDisabled = false;

  public text = {
    save: this.I18n.t('js.relation_buttons.save'),
    abort: this.I18n.t('js.relation_buttons.abort'),
    addNewChild: this.I18n.t('js.relation_buttons.add_new_child'),
    addExistingChild: this.I18n.t('js.relation_buttons.add_existing_child')
  };

  constructor(protected readonly parent:WorkPackageInlineCreateComponent,
              protected readonly wpInlineCreate:WorkPackageInlineCreateService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpRelations:WorkPackageRelationsService,
              protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected readonly I18n:I18nService) {
  }

  public addExistingChild() {
    if (_.isNil(this.selectedWpId)) {
      return;
    }

    const newChildId = this.selectedWpId;
    this.isDisabled = true;

    this.wpRelationsHierarchyService
      .addExistingChildWp(this.workPackage, newChildId)
      .then(() => {
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
        this.isDisabled = false;
        this.wpInlineCreate.newInlineWorkPackageReferenced.next(newChildId);
        this.cancel();
      })
      .catch((err:any) => {
        this.wpNotificationsService.handleRawError(err, this.workPackage);
        this.isDisabled = false;
        this.cancel();
      });
  }

  public updateSelectedId(workPackageId:string) {
    this.selectedWpId = workPackageId;
  }

  public get workPackage() {
    return this.wpInlineCreate.referenceTarget!;
  }


  public cancel() {
    this.parent.resetRow();
  }
}
