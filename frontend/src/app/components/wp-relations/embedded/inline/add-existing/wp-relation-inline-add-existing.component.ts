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

import {Component, Inject} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageInlineCreateComponent} from "core-components/wp-inline-create/wp-inline-create.component";
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {WpRelationInlineCreateServiceInterface} from "core-components/wp-relations/embedded/wp-relation-inline-create.service.interface";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {ApiV3Filter} from "core-components/api/api-v3/api-v3-filter-builder";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {RelationResource} from "core-app/modules/hal/resources/relation-resource";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Component({
  templateUrl: './wp-relation-inline-add-existing.component.html'
})
export class WpRelationInlineAddExistingComponent {
  public selectedWpId:string;
  public isDisabled = false;

  public queryFilters = this.buildQueryFilters();

  public text = {
    abort: this.I18n.t('js.relation_buttons.abort'),
  };

  constructor(protected readonly parent:WorkPackageInlineCreateComponent,
              @Inject(WorkPackageInlineCreateService) protected readonly wpInlineCreate:WpRelationInlineCreateServiceInterface,
              protected wpCacheService:WorkPackageCacheService,
              protected wpRelations:WorkPackageRelationsService,
              protected notificationService:WorkPackageNotificationService,
              protected halEvents:HalEventsService,
              protected urlParamsHelper:UrlParamsHelperService,
              protected querySpace:IsolatedQuerySpace,
              protected readonly I18n:I18nService) {
  }

  public addExisting() {
    if (_.isNil(this.selectedWpId)) {
      return;
    }

    const newRelationId = this.selectedWpId;
    this.isDisabled = true;

    this.wpInlineCreate.add(this.workPackage, newRelationId)
      .then(() => {
        this.wpCacheService.loadWorkPackage(this.workPackage.id!, true);

        this.halEvents.push(this.workPackage, {
          eventType: 'association',
          relatedWorkPackage: newRelationId,
          relationType: this.relationType,
        });

        this.isDisabled = false;
        this.wpInlineCreate.newInlineWorkPackageReferenced.next(newRelationId);
        this.cancel();
      })
      .catch((err:any) => {
        this.notificationService.handleRawError(err, this.workPackage);
        this.isDisabled = false;
        this.cancel();
      });
  }

  public onSelected(workPackage?:WorkPackageResource) {
    if (workPackage) {
      this.selectedWpId = workPackage.id!;
      this.addExisting();
    }
  }

  public get relationType() {
    return this.wpInlineCreate.relationType;
  }

  public get workPackage() {
    return this.wpInlineCreate.referenceTarget!;
  }

  public cancel() {
    this.parent.resetRow();
  }

  private buildQueryFilters():ApiV3Filter[] {
    const query = this.querySpace.query.value;

    if (!query) {
      return [];
    }

    const relationTypes = RelationResource.RELATION_TYPES(true);
    let filters = query.filters.filter(filter => {
      let id = this.urlParamsHelper.buildV3GetFilterIdFromFilter(filter);
      return relationTypes.indexOf(id) === -1;
    });

    return this.urlParamsHelper.buildV3GetFilters(filters);
  }
}
