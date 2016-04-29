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

import {wpControllersModule} from "../../../angular-modules";

function OverviewPanelController($scope,
                                 I18n,
                                 WorkPackagesOverviewService,
                                 WorkPackageFieldService,
                                 inplaceEditAll,
                                 WorkPackagesDisplayHelper,
                                 NotificationsService,
                                 WorkPackageAttachmentsService) {
  var vm = this;

  vm.groupedFields = [];
  vm.hideEmptyFields = true;
  vm.I18n = I18n;

  //Show all attributes in Edit-Mode
  $scope.$watch(function () {
    return inplaceEditAll.state;
  }, function (newState, oldState) {
    if (newState !== oldState) {
      vm.hideEmptyFields = !newState;
    }
  });

  vm.shouldHideGroup = function (group) {
    return WorkPackagesDisplayHelper.shouldHideGroup(vm.hideEmptyFields,
      vm.groupedFields,
      group,
      vm.workPackage);
  };
  vm.isFieldHideable = WorkPackagesDisplayHelper.isFieldHideable;
  vm.getLabel = WorkPackagesDisplayHelper.getLabel;
  vm.isSpecified = WorkPackagesDisplayHelper.isSpecified;
  vm.hasNiceStar = WorkPackagesDisplayHelper.hasNiceStar;
  vm.showToggleButton = WorkPackagesDisplayHelper.showToggleButton;
  vm.filesExist = false;
  activate();

  WorkPackageAttachmentsService.hasAttachments(vm.workPackage).then(function (bool) {
    vm.filesExist = bool;
  });

  function activate() {
    $scope.$watch('workPackage.schema', function (schema) {
      if (schema) {
        WorkPackagesDisplayHelper.setFocus();
        vm.workPackage = $scope.workPackage;
      }
    });
    vm.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();

    $scope.$watchCollection('vm.workPackage.form', function () {
      var schema = WorkPackageFieldService.getSchema(vm.workPackage);
      var otherGroup:any = _.find(vm.groupedFields, {groupName: 'other'});
      otherGroup.attributes = [];

      _.forEach(schema.props, function (prop, propName) {
        if (propName.match(/^customField/)) {
          otherGroup.attributes.push(propName);
        }
      });

      otherGroup.attributes.sort(function (a, b) {
        var getLabel = field => vm.getLabel(vm.workPackage, field);
        var left = getLabel(a).toLowerCase();
        var right = getLabel(b).toLowerCase();
        
        return left.localeCompare(right);
      });
    });
    $scope.$on('workPackageUpdatedInEditor', function () {
      NotificationsService.addSuccess(I18n.t('js.notice_successful_update'));
    });
  }
}

wpControllersModule.controller('OverviewPanelController', OverviewPanelController);

