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

import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableRelationColumns} from '../wp-table-relation-columns';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableColumnsService} from './wp-table-columns.service';
import {TableStateStates, WorkPackageTableBaseService} from './wp-table-base.service';
import {RelationResource} from '../../api/api-v3/hal-resources/relation-resource.service';
import {
  QueryColumn, queryColumnTypes, RelationQueryColumn,
  TypeRelationQueryColumn
} from '../../wp-query/query-column';
import {IQService} from 'angular';
import {HalRequestService} from '../../api/api-v3/hal-request/hal-request.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {
  RelationsStateValue,
  WorkPackageRelationsService
} from '../../wp-relations/wp-relations.service';
import {WorkPackageTableHierarchiesService} from './wp-table-hierarchy.service';

export class WorkPackageTableAdditionalElementsService {

  constructor(public states:States,
              public wpTableHierarchies:WorkPackageTableHierarchiesService,
              public wpTableColumns:WorkPackageTableColumnsService,
              public $q:IQService,
              public halRequest:HalRequestService,
              public wpCacheService:WorkPackageCacheService,
              public wpRelations:WorkPackageRelationsService) {
  }

  public initialize(rows:WorkPackageResourceInterface[]) {
    // Add relations to the stack
    Promise.all([
      this.requireInvolvedRelations(rows.map(el => el.id)),
      this.requireHierarchyElements(rows)
    ]).then((results:string[][]) => {
      this.loadAdditional(_.flatten(results));
    });
  }

  private loadAdditional(wpIds:string[]) {
    this.wpCacheService.requireAll(wpIds)
      .then(() => {
        this.states.table.additionalRequiredWorkPackages.putValue(null, 'All required work packages are loaded');
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
      .requireAll(rows, true)
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
  private requireHierarchyElements(rows:WorkPackageResourceInterface[]):Promise<string[]> {
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
}

opServicesModule.service('wpTableAdditionalElements', WorkPackageTableAdditionalElementsService);
