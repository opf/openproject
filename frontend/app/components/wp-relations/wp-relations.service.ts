
//-- copyright
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
//++

import {InputState} from "reactivestates";
import {wpDirectivesModule} from "../../angular-modules";
import {HalRequestService} from "../api/api-v3/hal-request/hal-request.service";
import {CollectionResource} from "../api/api-v3/hal-resources/collection-resource.service";
import {RelationResource, RelationResourceInterface} from "../api/api-v3/hal-resources/relation-resource.service";
import {WorkPackageResourceInterface} from "../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageStates} from "../work-package-states.service";
import {WorkPackageCacheService} from "../work-packages/work-package-cache.service";
import {WorkPackageNotificationService} from "../wp-edit/wp-notification.service";
import {WorkPackageTableRefreshService} from "../wp-table/wp-table-refresh-request.service";

export type RelationsStateValue = {[id:number]:RelationResource};

export class WorkPackageRelationsService {

  constructor(protected wpStates:WorkPackageStates,
              protected halRequest:HalRequestService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpTableRefresh: WorkPackageTableRefreshService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected I18n:op.I18n,
              protected PathHelper:any,
              protected NotificationsService:any) {
  }

  /**
   * Return the relation state for the given work package ID.
   */
  public relationState(workPackageId: string): InputState<RelationsStateValue> {
    return this.wpStates.relations.get(workPackageId);
  }

  /**
   * Require the relations of the given singular work package to be loaded into its state.
   */
  public require(workPackage:WorkPackageResourceInterface, force:boolean = false) {
    const state = this.relationState(workPackage.id);

    if (force) {
      state.clear();
    }

    if (state.isPristine()) {
      workPackage.relations.$load(true).then((collection:CollectionResource) => {
        if (collection.elements.length > 0) {
          this.mergeIntoStates(collection.elements as RelationResource[]);
        } else {
          this.relationState(workPackage.id).putValue({}, 'Received empty response from singular relations');
        }
      });
    }
  }

  /**
   * Require the relations of a set of involved work packages loaded into the states.
   */
  public requireInvolved(workPackageIds:string[]) {
    this.relationsRequest(workPackageIds).then((elements:RelationResource[]) => {
      this.mergeIntoStates(elements);
    });
  }

  public addCommonRelation(workPackage:WorkPackageResourceInterface,
                           relationType:string,
                           relatedWpId:string) {
    const params = {
      _links: {
        from: { href: workPackage.href },
        to: { href: this.PathHelper.apiV3WorkPackagePath(relatedWpId) }
      },
      type: relationType
    };

    return workPackage.addRelation(params).then((relation:RelationResourceInterface) => {
      this.mergeIntoStates([relation]);
      this.wpTableRefresh.request(true, `Adding relation (${relation.ids.from} to ${relation.ids.to})`);
      return relation;
    });
  }

  public getRelationTypes(rejectParentChild?:boolean):any[] {
    let relationTypes = RelationResource.TYPES();

    if (rejectParentChild) {
      _.pull(relationTypes, 'parent', 'children');
    }

    return relationTypes.map((key:string) => {
      return { name: key, label: this.I18n.t('js.relation_labels.' + key) };
    });
  }

  /**
   * Update the given relation
   */
  public updateRelation(workPackageId:string, relation:RelationResourceInterface, params:any) {
    return relation.updateImmediately(params)
    .then((savedRelation:RelationResourceInterface) => {
      this.mergeIntoStates([savedRelation]);
      this.wpTableRefresh.request(true, `Updating relation (${relation.ids.from} to ${relation.ids.to})`);
      return savedRelation;
    });
  }


  /**
   * Remove the given relation.
   */
  public removeRelation(relation:RelationResourceInterface) {
    return relation.delete().then(() => {
      _.each(relation.ids, (member:string) => {
        const state = this.relationState(member);
        const currentValue = state.value!;

          if (currentValue !== null) {
            delete currentValue[relation.id];
            state.putValue(currentValue);
          }
      });
      this.wpTableRefresh.request(true, `Removing relation (${relation.ids.from} to ${relation.ids.to})`);
    });
  }

  /**
   * Merge a set of relations into the associated states
   */
  private mergeIntoStates(elements:RelationResource[]) {
    const stateValues = this.accumulateRelationsFromCollection(elements);
    _.each(stateValues, (relations:RelationResource[], workPackageId:string) => {
      this.merge(workPackageId, relations);
    });
  }

  /**
   *
   * We don't know how many values we're getting for a single work package
   * So accumlate the state values before pushing them once.
   */
  private accumulateRelationsFromCollection(relations:RelationResource[]) {
    const stateValues:{[workPackageId:string]:RelationResource[]} = {};

    relations.forEach((relation:RelationResource) => {
      const involved = relation.ids;

      if (!stateValues[involved.from]) {
        stateValues[involved.from] = [];
      }
      if (!stateValues[involved.to]) {
        stateValues[involved.to] = [];
      }

      stateValues[involved.from].push(relation);
      stateValues[involved.to].push(relation);
    });

    return stateValues;
  }

  /**
   * Merge an object of relations into the associated state or create it, if empty.
   */
  private merge(workPackageId:string, newRelations:RelationResource[]) {
    const state = this.relationState(workPackageId);
    let relationsToInsert = _.keyBy(newRelations, r => r.id);
    let current = state.value!;

    if (current !== null) {
      relationsToInsert = _.assign(current, relationsToInsert);
    }

    state.putValue(relationsToInsert, 'Initializing relations state.');
  }


  private relationsRequest(workPackageIds:string[]):ng.IPromise<RelationResource[]> {
    let validIds = _.filter(workPackageIds, id => /\d+/.test(id));

    return this.halRequest.get(
      '/api/v3/relations',
      {
        filters: JSON.stringify([{ involved: {operator: '=', values: validIds }}])
      },
      {
        caching: { enabled: false }
      }).then((collection:CollectionResource) => {
        return collection.elements;
    });
  }
}

wpDirectivesModule.service('wpRelations', WorkPackageRelationsService);
