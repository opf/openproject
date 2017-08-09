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

import {Observable} from 'rxjs';
import {wpDirectivesModule} from '../../angular-modules';
import {scopedObservable} from '../../helpers/angular-rx-utils';
import {RelationResourceInterface} from '../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {RelatedWorkPackagesGroup} from './wp-relations.interfaces';
import {RelationsStateValue, WorkPackageRelationsService} from './wp-relations.service';

export class WorkPackageRelationsController {
  public relationGroups:RelatedWorkPackagesGroup;
  public workPackage:WorkPackageResourceInterface;
  public canAddRelation:boolean = !!this.workPackage.addRelation;

  // By default, group by relation type
  public groupByWorkPackageType = false;
  public currentRelations:RelationResourceInterface[] = [];

  constructor(protected $scope:ng.IScope,
              protected $q:ng.IQService,
              protected $state:ng.ui.IState,
              protected I18n:op.I18n,
              protected wpRelations:WorkPackageRelationsService,
              protected wpCacheService:WorkPackageCacheService) {

    this.wpRelations.require(this.workPackage.id, true);
    scopedObservable(this.$scope,
      this.wpRelations.state(this.workPackage.id).values$())
      .subscribe((relations:RelationsStateValue) => {
        this.loadedRelations(relations);
      });

    // Listen for changes to this WP.
    scopedObservable(this.$scope,
      this.wpCacheService.loadWorkPackage(this.workPackage.id).values$())
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
      });
  }

  protected getRelatedWorkPackages(workPackageIds:string[]) {
    let observablesToGetZipped = workPackageIds.map(wpId => {
      return scopedObservable(this.$scope, this.wpCacheService.loadWorkPackage(wpId).values$());
    });

    if (observablesToGetZipped.length > 1) {
      return Observable
        .zip
        .apply(Observable, observablesToGetZipped);
    }

    return observablesToGetZipped[0];
  }

  protected getRelatedWorkPackageId(relation:RelationResourceInterface):string {
    const involved = relation.ids;
    return (relation.to.href === this.workPackage.href) ? involved.from : involved.to;
  }

  public toggleGroupBy() {
    this.groupByWorkPackageType = !this.groupByWorkPackageType;
    this.buildRelationGroups();
  }

  protected buildRelationGroups() {
    if (!angular.isDefined(this.currentRelations)) {
      return;
    }

    this.relationGroups = <RelatedWorkPackagesGroup> _.groupBy(this.currentRelations,
      (wp:WorkPackageResourceInterface) => {
        if (this.groupByWorkPackageType) {
          return wp.type.name;
        } else {
          var normalizedType = (wp.relatedBy as RelationResourceInterface).normalizedType(this.workPackage);
          return this.I18n.t('js.relation_labels.' + normalizedType);
        }
      });
  }

  protected loadedRelations(stateValues:RelationsStateValue):void {
    var relatedWpIds:string[] = [];
    var relations:{ [wpId:string]:any } = [];

    if (_.size(stateValues) === 0) {
      this.currentRelations = [];
      return this.buildRelationGroups();
    }

    _.each(stateValues, (relation:RelationResourceInterface) => {
      const relatedWpId = this.getRelatedWorkPackageId(relation);
      relatedWpIds.push(relatedWpId);
      relations[relatedWpId] = relation;
    });

    this.getRelatedWorkPackages(relatedWpIds)
      .take(1)
      .subscribe((relatedWorkPackages:any) => {
        if (!angular.isArray(relatedWorkPackages)) {
          relatedWorkPackages = [relatedWorkPackages];
        }

        this.currentRelations = relatedWorkPackages.map((wp:WorkPackageResourceInterface) => {
          wp.relatedBy = relations[wp.id];
          return wp;
        });

        this.buildRelationGroups();
      });
  }
}

function wpRelationsDirective() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/wp-relations/wp-relations.template.html',

    scope: {
      workPackage: '='
    },

    controller: WorkPackageRelationsController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpRelations', wpRelationsDirective);
