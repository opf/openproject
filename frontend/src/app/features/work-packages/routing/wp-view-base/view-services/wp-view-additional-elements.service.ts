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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Injectable } from '@angular/core';
import {
  RelationsStateValue,
  WorkPackageRelationsService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageViewHierarchiesService } from './wp-view-hierarchy.service';
import { WorkPackageViewColumnsService } from './wp-view-columns.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ShareResource } from 'core-app/features/hal/resources/share-resource';
import { map } from 'rxjs/operators';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class WorkPackageViewAdditionalElementsService {
  constructor(
    readonly querySpace:IsolatedQuerySpace,
    readonly wpTableHierarchies:WorkPackageViewHierarchiesService,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly notificationService:WorkPackageNotificationService,
    readonly halResourceService:HalResourceService,
    readonly apiV3Service:ApiV3Service,
    readonly schemaCache:SchemaCacheService,
    readonly wpRelations:WorkPackageRelationsService,
  ) {
  }

  public initialize(query:QueryResource, results:WorkPackageCollectionResource):void {
    const rows = results.elements;
    const workPackageIds = rows.map((el) => el.id!);

    // Add relations to the stack
    Promise.all([
      this.requireInvolvedRelations(workPackageIds),
      this.requireHierarchyElements(rows),
      this.requireWorkPackageShares(workPackageIds),
      this.requireSumsSchema(results),
    ]).then((wpResults:string[][]) => {
      this.loadAdditional(_.flatten(wpResults));
    });
  }

  private loadAdditional(wpIds:string[]) {
    this
      .apiV3Service
      .work_packages
      .requireAll(wpIds)
      .then(() => {
        this.querySpace.additionalRequiredWorkPackages.putValue(null, 'All required work packages are loaded');
      })
      .catch((e) => {
        this.querySpace.additionalRequiredWorkPackages.putValue(null, 'Failure loading required work packages');
        this.notificationService.handleRawError(e);
      });
  }

  /**
   * Requires both the relation resource of the given work package ids as well
   * as the `to` work packages returned from the relations
   */
  private requireInvolvedRelations(rows:string[]):Promise<string[]> {
    if (!this.wpTableColumns.hasRelationColumns()) {
      return Promise.resolve([]);
    }
    return this.wpRelations
      .requireAll(rows)
      .then(() => {
        const ids = this.getInvolvedWorkPackages(rows.map((id) => this.wpRelations.state(id).value!));
        return _.flatten(ids);
      });
  }

  /**
   * Return the id of all ancestors for visible rows in the table.
   * @param rows
   * @return {string[]}
   */
  private requireHierarchyElements(rows:WorkPackageResource[]):Promise<string[]> {
    if (!this.wpTableHierarchies.isEnabled) {
      return Promise.resolve([]);
    }

    const resultIds = rows.map((el:WorkPackageResource) => (el.id as string | number).toString());
    const ids = _.flatten(rows.map((el) => el.ancestorIds))
      .filter((id) => !resultIds.includes(id));

    return Promise.resolve(ids);
  }

  /**
   * From a set of relations state values, return all involved IDs.
   * @param states
   * @return {string[]}
   */
  private getInvolvedWorkPackages(states:RelationsStateValue[]) {
    const ids:string[] = [];
    _.each(states, (relations:RelationsStateValue) => {
      _.each(relations, (resource:RelationResource) => {
        ids.push(resource.ids.from, resource.ids.to);
      });
    });

    return ids;
  }

  private requireSumsSchema(results:WorkPackageCollectionResource):Promise<string[]> {
    if (results.sumsSchema) {
      return this
        .schemaCache
        .ensureLoaded(results.sumsSchema.href!)
        .then(() => []);
    }

    return Promise.resolve([]);
  }

  private requireWorkPackageShares(wpIds:string[]):Promise<string[]> {
    if (!this.wpTableColumns.hasShareColumn()) { return Promise.resolve([]); }
    if (wpIds.length === 0) { return Promise.resolve([]); }

    const filters = new ApiV3FilterBuilder()
      .add('entityType', '=', ['WorkPackage'])
      .add('entityId', '=', wpIds);

    const workPackageShareRequest = this
      .apiV3Service
      .shares
      .filtered(filters, { pageSize: '-1' })
      .getPaginatedResults()
      .pipe(
        map((elements) => {
          const shares = elements as ShareResource[];

          const sharedWpIds = _.uniq(shares.map((share) => share.entity.id as string));

          sharedWpIds.forEach((wpId) => {
            this
              .querySpace
              .workPackageSharesCache
              .get(wpId)
              .putValue(shares.filter((share) => share.entity.id === wpId));
          });

          return [];
        }),
      );

      return firstValueFrom(workPackageShareRequest);
  }
}
