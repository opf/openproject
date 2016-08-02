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

import {WorkPackageRelationGroup} from './wp-relation-group.service';
import {wpTabsModule} from '../../../angular-modules';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {ErrorResource} from '../../api/api-v3/hal-resources/error-resource.service';

var $q:ng.IQService;
var HalResource;
var PathHelper:any;
var wpCacheService:WorkPackageCacheService;
var wpNotificationsService:WorkPackageNotificationService;

export class WorkPackageParentRelationGroup extends WorkPackageRelationGroup {
  public get canAddRelation():boolean {
    return !!this.workPackage.changeParent;
  }

  public canRemoveRelation():boolean {
    return this.canAddRelation;
  }

  public getRelatedWorkPackage(relation) {
    return relation.$load();
  }

  public addWpRelation(wpId:number) {
    return this.changeParent(wpId).then(() => {
      if (this.workPackage.parent) {
        this.workPackage.parent.$load().then(parent => {
          this.relations[0] = parent;
        });
      }
    });
  }

  public removeWpRelation() {
    return this.changeParent(null).then(() => {
      this.relations.pop();
      return 0;
    });
  }

  protected changeParent(parentId:number) {
    var params = {
      parentId: parentId,
      lockVersion: this.workPackage.lockVersion
    };

    return this.workPackage.changeParent(params)
      .then((wp) => {
        this.workPackage = wp;
        return wpCacheService.updateWorkPackage(wp);
      })
      .catch(error => {
        if (error instanceof ErrorResource) {
          wpNotificationsService.showError(error, this.workPackage);
        }
        else {
          wpNotificationsService.showGeneralError();
        }
      });
  }

  protected init() {
    if (this.workPackage.parent) {
      this.workPackage.parent.$load().then(parent => this.relations.push(parent));
    }
  }
}

function wpParentRelationGroupService(...args) {
  [$q, HalResource, PathHelper, wpCacheService, wpNotificationsService] = args;
  return WorkPackageParentRelationGroup;
}

wpParentRelationGroupService.$inject = [
  '$q', 'HalResource', 'PathHelper', 'wpCacheService', 'wpNotificationsService'
];

wpTabsModule.factory('WorkPackageParentRelationGroup', wpParentRelationGroupService);
