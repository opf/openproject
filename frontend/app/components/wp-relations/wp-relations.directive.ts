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
import {Observable} from "rxjs";

export class WorkPackageRelationsController {
  public relationGroups:RelatedWorkPackagesGroup;
  public workPackage:WorkPackageResourceInterface;
  public canAddRelation:boolean = !!this.workPackage.addRelation;

  // By default, group by relation type
  public groupByWorkPackageType = false;
  public currentRelations: RelatedWorkPackage[] = [];

  constructor(protected $scope:ng.IScope,
              protected $q:ng.IQService,
              protected $state:ng.ui.IState,
              protected I18n:op.I18n,
              protected wpCacheService:WorkPackageCacheService) {

    // Reload the current relations after a change, causing loadRelations to re-run
    this.$scope.$on('wp-relations.changed', () => {
      this.workPackage.updateLinkedResources('relations');
    });

    // Listen for changes to this WP.
    this.wpCacheService
      .loadWorkPackage(<number> this.workPackage.id)
      .observe(this.$scope)
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.workPackage.relations.$load().then(this.loadRelations.bind(this));
      });
  }

  protected getRelatedWorkPackages(workPackageIds:number[]) {
    let observablesToGetZipped = workPackageIds.map(wpId => this.wpCacheService.loadWorkPackage(wpId).observe(this.$scope));

    if (observablesToGetZipped.length > 1) {
      return Observable
        .zip
        .apply(Observable, observablesToGetZipped);
    }

    return observablesToGetZipped[0];
  }

  protected getRelatedWorkPackageId(relation) {
    let direction = (relation.to.href === this.workPackage.href) ? 'from' : 'to';
    return parseInt(relation[direction].href.split('/').pop());
  }

  public toggleGroupBy() {
    this.groupByWorkPackageType = !this.groupByWorkPackageType;
    this.buildRelationGroups();
  }

  protected buildRelationGroups() {
    if (!angular.isDefined(this.currentRelations)) {
      return;
    }

    this.relationGroups = <RelatedWorkPackagesGroup> _.groupBy(this.currentRelations, (wp) => {
      if (this.groupByWorkPackageType) {
        return wp.type.name;
      } else {
        var normalizedType = wp.relatedBy.normalizedType(this.workPackage);
        return this.I18n.t('js.relation_labels.' + normalizedType);
      }
    });
  }

  protected loadRelations():void {
    var relatedWpIds = [];
    var relations = [];

    if (this.workPackage.relations.elements.length === 0) {
      this.currentRelations = [];
      return this.buildRelationGroups();
    }

    this.workPackage.relations.elements.forEach(relation => {
      const relatedWpId = this.getRelatedWorkPackageId(relation);
      relatedWpIds.push(relatedWpId);
      relations[relatedWpId] = relation;
    });

    this.getRelatedWorkPackages(relatedWpIds)
      .take(1)
      .subscribe(relatedWorkPackages => {
        if (!angular.isArray(relatedWorkPackages)) {
          relatedWorkPackages = [relatedWorkPackages];
        }

        this.currentRelations = relatedWorkPackages.map((wp) => {
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
