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

import {wpDirectivesModule} from "../../../angular-modules";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";

export class WorkPackageRelationsHierarchyController {
  public workPackage:WorkPackageResourceInterface;
  public showEditForm:boolean = false;
  public workPackagePath = this.PathHelper.workPackagePath;
  public canHaveChildren = !this.workPackage.isMilestone;
  public canModifyHierarchy = !!this.workPackage.changeParent;
  public canAddRelation = !!this.workPackage.addRelation;

  constructor(protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $q:ng.IQService,
              protected wpCacheService:WorkPackageCacheService,
              protected PathHelper:op.PathHelper,
              protected I18n:op.I18n) {

    scopedObservable(
      this.$scope,
      this.wpCacheService.loadWorkPackage(this.workPackage.id).values$())
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.loadParent();
        this.loadChildren();
      });
  }

  public text = {
    hierarchyHeadline: this.I18n.t('js.relations_hierarchy.hierarchy_headline')
  };

  protected loadChildren() {
    if (this.workPackage.children) {
      this.workPackage.children.map(child => child.$load());
    }
  }

  protected loadParent() {
    if (!this.workPackage.parent) {
      return;
    }

    scopedObservable(
      this.$scope,
      this.wpCacheService.loadWorkPackage(this.workPackage.parent.id).values$())
      .take(1)
      .subscribe((parent:WorkPackageResourceInterface) => {
        this.workPackage.parent = parent;
      });
  }
}

function wpRelationsDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.template.html',

    scope: {
      workPackage: '=',
      relationType: '@'
    },

    controller: WorkPackageRelationsHierarchyController,
    controllerAs: '$ctrl',
    bindToController: true,
  };
}

wpDirectivesModule.directive('wpRelationsHierarchy', wpRelationsDirective);
