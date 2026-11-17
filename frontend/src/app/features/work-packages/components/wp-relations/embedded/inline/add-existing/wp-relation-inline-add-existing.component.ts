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

import { queryFilterValueId } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { Component, DestroyRef, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageInlineCreateService,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import {
  WorkPackageInlineCreateComponent,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import {
  WorkPackageRelationsService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import {
  WpRelationInlineCreateServiceInterface,
} from 'core-app/features/work-packages/components/wp-relations/embedded/wp-relation-inline-create.service.interface';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { IAPIFilter } from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  templateUrl: './wp-relation-inline-add-existing.component.html',
  standalone: false,
})
export class WpRelationInlineAddExistingComponent {
  protected readonly parent = inject(WorkPackageInlineCreateComponent);
  protected readonly wpInlineCreate = inject(WorkPackageInlineCreateService) as WpRelationInlineCreateServiceInterface;
  protected apiV3Service = inject(ApiV3Service);
  protected wpRelations = inject(WorkPackageRelationsService);
  protected notificationService = inject(WorkPackageNotificationService);
  protected halEvents = inject(HalEventsService);
  protected urlParamsHelper = inject(UrlParamsHelperService);
  protected querySpace = inject(IsolatedQuerySpace);
  protected readonly I18n = inject(I18nService);

  private readonly destroyRef = inject(DestroyRef);

  public selectedWpId:string;

  public isDisabled = false;

  public queryFilters:IAPIFilter[] = this.buildQueryFilters();

  public text = {
    abort: this.I18n.t('js.relation_buttons.abort'),
  };

  public addExisting() {
    if (this.selectedWpId == null) {
      return;
    }

    const newRelationId = this.selectedWpId;
    const { workPackage, relationType } = this;
    const isCurrent = () => !this.destroyRef.destroyed
      && this.wpInlineCreate.referenceTarget?.id === workPackage.id
      && this.relationType === relationType;

    this.isDisabled = true;

    void this.wpInlineCreate.add(workPackage, newRelationId)
      .then(() => {
        void this
          .apiV3Service
          .work_packages
          .id(workPackage)
          .refresh();

        this.halEvents.push(workPackage, {
          eventType: 'association',
          relatedWorkPackage: newRelationId,
          relationType,
        });

        this.isDisabled = false;
        if (isCurrent()) {
          this.wpInlineCreate.newInlineWorkPackageReferenced.next(newRelationId);
        }
      })
      .catch((err:unknown) => this.notificationService.handleRawError(err, workPackage))
      .finally(() => {
        this.isDisabled = false;
        if (isCurrent()) {
          this.cancel();
        }
      });
  }

  public onSelected(workPackage:unknown) {
    if (!(workPackage instanceof WorkPackageResource) || workPackage.id === null) {
      return;
    }

    this.selectedWpId = workPackage.id;
    this.addExisting();
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
      return !relationTypes.includes(id);
    });

    const iApiFilters:IAPIFilter[] = [];

    filters.forEach((filter) => {
      iApiFilters.push({
        name: filter.id,
        operator: filter.operator.id as FilterOperator,
        values: filter.values.flatMap(value => queryFilterValueId(value) ?? []),
      });
    });

    return iApiFilters;
  }
}
