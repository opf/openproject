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

import {
  Component,
  Inject,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageInlineCreateComponent } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WpRelationInlineCreateServiceInterface } from 'core-app/features/work-packages/components/wp-relations/embedded/wp-relation-inline-create.service.interface';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

@Component({
  templateUrl: './wp-relation-inline-add-existing.component.html',
})
export class WpRelationInlineAddExistingComponent {
  public selectedWpId:string;

  public isDisabled = false;

  public queryFilters:IAPIFilter[] = this.buildQueryFilters();

  public text = {
    abort: this.I18n.t('js.relation_buttons.abort'),
  };

  constructor(
    protected readonly parent:WorkPackageInlineCreateComponent,
    @Inject(WorkPackageInlineCreateService) protected readonly wpInlineCreate:WpRelationInlineCreateServiceInterface,
    protected apiV3Service:ApiV3Service,
    protected wpRelations:WorkPackageRelationsService,
    protected notificationService:WorkPackageNotificationService,
    protected halEvents:HalEventsService,
    protected urlParamsHelper:UrlParamsHelperService,
    protected querySpace:IsolatedQuerySpace,
    protected readonly I18n:I18nService,
  ) {}

  public addExisting() {
    if (_.isNil(this.selectedWpId)) {
      return;
    }

    const newRelationId = this.selectedWpId;
    this.isDisabled = true;

    this.wpInlineCreate.add(this.workPackage, newRelationId)
      .then(() => {
        void this
          .apiV3Service
          .work_packages
          .id(this.workPackage)
          .refresh();

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
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
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

  private buildQueryFilters():IAPIFilter[] {
    const query = this.querySpace.query.value;

    if (!query) {
      return [];
    }

    const relationTypes = RelationResource.RELATION_TYPES(true);
    const filters = query.filters.filter((filter) => {
      const id = this.urlParamsHelper.buildV3GetFilterIdFromFilter(filter);
      return relationTypes.indexOf(id) === -1;
    });

    const iApiFilters:IAPIFilter[] = [];

    filters.forEach((filter) => {
      iApiFilters.push({
        name: filter.id,
        operator: filter.operator.id,
        values: filter.values.map((f) => (typeof f === 'string' ? f : f.id)),
      });
    });

    return iApiFilters;
  }
}
