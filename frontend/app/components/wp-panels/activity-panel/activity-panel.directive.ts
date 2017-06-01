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

import {wpDirectivesModule} from "../../../angular-modules";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";

export class ActivityPanelController {

  public workPackage:WorkPackageResourceInterface;
  public activities:any[] = [];
  public reverse:boolean;

  constructor(public $scope:ng.IScope,
              public wpCacheService:WorkPackageCacheService,
              public wpActivity:any) {

    this.reverse = wpActivity.order === 'asc';

    scopedObservable(
      $scope,
      wpCacheService.loadWorkPackage(this.workPackage.id).values$())
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.wpActivity.aggregateActivities(this.workPackage).then((activities:any) => {
          this.activities = activities;
        });
      });
  }

  public info(activity:any, index:any) {
    return this.wpActivity.info(this.activities, activity, index);
  }
}


function activityPanelDirective() {
  return {
    restrict: 'E',
    templateUrl: (element:ng.IAugmentedJQuery, attrs:ng.IAttributes) => {
      var path = '/components/wp-panels/activity-panel/',
        type = attrs['template'] || 'default';

      return path + 'activity-panel-' + type + '.directive.html';
    },

    scope: {
      workPackage: '='
    },

    bindToController: true,
    controller: ActivityPanelController,
    controllerAs: 'vm'
  };
}

wpDirectivesModule.directive('activityPanel', activityPanelDirective);
