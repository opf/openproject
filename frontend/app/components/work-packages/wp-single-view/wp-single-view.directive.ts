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

import {opWorkPackagesModule} from "../../../angular-modules";
import {scopedObservable} from "../../../helpers/angular-rx-utils";

export class WorkPackageSingleViewController {
  public workPackage;
  public groupedFields:any[] = [];
  public hideEmptyFields:boolean = true;
  public filesExist:boolean = false;

  constructor(protected $scope,
              protected $stateParams,
              public wpSingleView,
              protected I18n,
              protected wpCacheService,
              protected NotificationsService,
              protected WorkPackagesOverviewService,
              protected WorkPackageFieldService,
              protected inplaceEditAll,
              protected WorkPackageAttachmentsService) {

    scopedObservable($scope, wpCacheService.loadWorkPackage($stateParams.workPackageId)).subscribe(wp => {
      this.workPackage = wp;
      this.workPackage.schema.$load();

      this.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();

      WorkPackageAttachmentsService.hasAttachments(this.workPackage).then(bool => {
        this.filesExist = bool;
      });

      $scope.$watch('$ctrl.workPackage.schema', schema => {
        if (schema) {
          this.wpSingleView.setFocus();
        }
      });

      $scope.$watchCollection('$ctrl.workPackage.form', () => {
        var schema = WorkPackageFieldService.getSchema(this.workPackage);
        var otherGroup:any = _.find(this.groupedFields, {groupName: 'other'});
        otherGroup.attributes = [];

        angular.forEach(schema.props, (prop, propName) => {
          if (propName.match(/^customField/)) {
            otherGroup.attributes.push(propName);
          }
        });

        otherGroup.attributes.sort((a, b) => {
          var getLabel = field => this.wpSingleView.getLabel(this.workPackage, field);
          var left = getLabel(a).toLowerCase();
          var right = getLabel(b).toLowerCase();

          return left.localeCompare(right);
        });
      });
    });

    $scope.$on('workPackageUpdatedInEditor', () => {
      NotificationsService.addSuccess(I18n.t('js.notice_successful_update'));
    }); 
  }

  public shouldHideGroup(group) {
    return this.wpSingleView.shouldHideGroup(
      this.hideEmptyFields, this.groupedFields, group, this.workPackage);
  }
}

function wpSingleViewDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/work-packages/wp-single-view/wp-single-view.directive.html',

    scope: {},
    
    bindToController: true,
    controller: WorkPackageSingleViewController,
    controllerAs: '$ctrl'
  };
}

opWorkPackagesModule.directive('wpSingleView', wpSingleViewDirective);




