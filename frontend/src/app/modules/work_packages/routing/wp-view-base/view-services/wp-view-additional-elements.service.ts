//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { WorkPackageViewColumnsService } from './wp-view-columns.service';
import { RelationResource } from 'core-app/modules/hal/resources/relation-resource';
import { WorkPackageViewHierarchiesService } from './wp-view-hierarchy.service';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { RelationsStateValue, WorkPackageRelationsService } from "core-components/wp-relations/wp-relations.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { WorkPackageCollectionResource } from "core-app/modules/hal/resources/wp-collection-resource";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Injectable()
export class WorkPackageViewAdditionalElementsService {

  constructor(readonly querySpace:IsolatedQuerySpace,
              readonly wpTableHierarchies:WorkPackageViewHierarchiesService,
              readonly wpTableColumns:WorkPackageViewColumnsService,
              readonly notificationService:WorkPackageNotificationService,
              readonly halResourceService:HalResourceService,
              readonly apiV3Service:APIV3Service,
              readonly schemaCache:SchemaCacheService,
              readonly wpRelations:WorkPackageRelationsService) {
  }

  public initialize(query:QueryResource, results:WorkPackageCollectionResource) {
    const rows = results.elements;

    // Add relations to the stack
    Promise.all([
      this.requireInvolvedRelations(rows.map(el => el.id!)),
      this.requireHierarchyElements(rows),
      this.requireSumsSchema(results)
    ]).then((results:string[][]) => {
      this.loadAdditional(_.flatten(results));
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
        const ids = this.getInvolvedWorkPackages(rows.map(id => {
          return this.wpRelations.state(id).value!;
        }));
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

    const ids = _.flatten(rows.map(el => el.ancestorIds));
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
        .ensureLoaded(results.sumsSchema.$href!)
        .then(() => []);
    }

    return Promise.resolve([]);
  }
}
