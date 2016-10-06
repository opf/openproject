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

import {wpDirectivesModule} from '../../angular-modules';
import {RelatedWorkPackage, RelatedWorkPackagesGroup} from './wp-relations.interfaces';

import {
  WorkPackageResourceInterface,
  WorkPackageResource
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';

export class WorkPackageRelationsController {
  public relationGroups:RelatedWorkPackagesGroup;
  public workPackage:WorkPackageResourceInterface;
  public canAddRelation:boolean = !!this.workPackage.addRelation;

  public currentRelations: RelatedWorkPackage[] = [];

  constructor(protected $scope:ng.IScope,
              protected $q:ng.IQService,
              protected $state:ng.ui.IState,
              protected wpCacheService:WorkPackageCacheService) {

    this.registerEventListeners();

    if (this.workPackage.relations && !this.workPackage.relations.$loaded) {
      this.workPackage.relations.$load().then(() => {
        if (this.workPackage.relations.count > 0) {
          this.loadRelations();
        }
      });
    } else if (this.workPackage.relations && this.workPackage.relations.count > 0) {
      this.loadRelations();
    }
  }

  protected removeSingleRelation(evt, relation) {
    this.currentRelations = _.remove(this.currentRelations, (latestRelation) => {
      return latestRelation.relatedBy.$href !== relation.$href;
    });

    this.buildRelationGroups();
  }


  protected getRelatedWorkPackages(workPackageIds:number[]) {
    let observablesToGetZipped = workPackageIds.map(wpId => this.wpCacheService.loadWorkPackage(wpId).observe(this.$scope));

    if (observablesToGetZipped.length > 1) {
      return Rx.Observable
        .zip
        .apply(Rx.Observable, observablesToGetZipped);
    }

    return observablesToGetZipped[0];
  }

  protected getRelatedWorkPackageId(relation) {
    let direction = (relation.relatedTo.href === this.workPackage.href) ? 'relatedFrom' : 'relatedTo';
    return parseInt(relation[direction].href.split('/').pop());
  }

  protected buildRelationGroups() {
    if (angular.isDefined(this.currentRelations)) {
      this.relationGroups = <RelatedWorkPackagesGroup> _.groupBy(this.currentRelations, (wp) => wp.type.name);
    }
  }

  protected addSingleRelation(evt, relation) {
    var relatedWorkPackageId = [this.getRelatedWorkPackageId(relation)];
    this.getRelatedWorkPackages(relatedWorkPackageId)
      .take(1)
      .subscribe((relatedWorkPackage:RelatedWorkPackage) => {
        relatedWorkPackage.relatedBy = relation;
        this.currentRelations.push(relatedWorkPackage);
        this.buildRelationGroups();
      });
  }

  protected loadRelations():void {
    var relatedWpIds = [];
    var relations = [];

    this.workPackage.relations.elements.forEach(relation => {
      const relatedWpId = this.getRelatedWorkPackageId(relation);
      relatedWpIds.push(relatedWpId);
      relations[relatedWpId] = relation;
    });

    this.getRelatedWorkPackages(relatedWpIds)
      .take(1)
      .subscribe(relatedWorkPackages => {
        if (angular.isArray(relatedWorkPackages)) {
          this.currentRelations = relatedWorkPackages.map((wp) => {
            wp.relatedBy = relations[wp.id];
            return wp;
          });
        }
        else {
          relatedWorkPackages.relatedBy = relations[relatedWorkPackages.id];
          this.currentRelations[0] = relatedWorkPackages;
        }

        this.buildRelationGroups();
      });
  }

  private registerEventListeners() {
    this.$scope.$on('wp-relations.added', this.addSingleRelation.bind(this));
    this.$scope.$on('wp-relations.removed', this.removeSingleRelation.bind(this));
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
