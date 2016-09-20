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

import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';

export class WorkPackageRelationsHierarchyController {
  public workPackage:WorkPackageResourceInterface;
  public parent:WorkPackageResourceInterface;
  public children:WorkPackageResourceInterface[] = [];
  public showEditForm:boolean = false;
  public workPackagePath = this.PathHelper.workPackagePath;
  public canHaveChildren = !this.workPackage.isMilestone;

  constructor(public I18n,
              protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $q:ng.IQService,
              protected PathHelper,
              protected wpCacheService:WorkPackageCacheService) {

    this.registerEventListeners();

    if (angular.isNumber(this.workPackage.parentId)) {
      this.loadParents();
    }

    if (this.workPackage.children) {
      this.loadChildren();
    }
  }

  protected loadParents() {
    this.wpCacheService.loadWorkPackage(this.workPackage.parentId)
      .take(1)
      .subscribe((parent:WorkPackageResourceInterface) => {
        this.parent = parent;
      });
  }

  protected loadChildren() {
    let relatedChildrenPromises = this.workPackage.children.map(child => child.$load());

    this.$q.all(relatedChildrenPromises).then((children:Array<WorkPackageResourceInterface>) => {
      this.children = children;
    });
  }

  protected removedChild(evt, removedChild) {
    _.remove(this.children, {'id' : removedChild.id});
    this.wpCacheService.updateWorkPackageList([this.workPackage, removedChild]);
    this.$rootScope.$emit('workPackagesRefreshInBackground');
  }

  protected addedChild(evt, addedChildWorkPackage) {
    this.children.push(addedChildWorkPackage);
    this.wpCacheService.updateWorkPackageList([this.workPackage, addedChildWorkPackage]);
    this.$rootScope.$emit('workPackagesRefreshInBackground');
  }

  private registerEventListeners() {
    this.$scope.$on('wp-relations.changedParent', this.updatedParent.bind(this));
    this.$scope.$on('wp-relations.removedChild', this.removedChild.bind(this));
    this.$scope.$on('wp-relations.addedChild', this.addedChild.bind(this));
  }

  private updatedParent(evt, changedData) {
    if (changedData.parentId !== null) {
      // parent changed
      this.wpCacheService.loadWorkPackage(changedData.parentId, true)
        .take(1)
        .subscribe((parent:WorkPackageResourceInterface) => {
          this.parent = parent;
          
          this.wpCacheService.updateWorkPackageList([this.workPackage, parent]);
          this.$rootScope.$emit('workPackagesRefreshInBackground');
        });
    } else {
      // parent deleted
      this.$rootScope.$emit('workPackagesRefreshInBackground');
      this.parent = null;
    }
    this.workPackage = changedData.updatedWp;
  }
}

function wpRelationsDirective() {
  return {
    restrict: 'E',
    replace: true,
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
