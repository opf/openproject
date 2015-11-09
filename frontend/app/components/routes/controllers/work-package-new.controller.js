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

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageNewController', WorkPackageNewController);

function WorkPackageNewController($scope, $rootScope, $state, $stateParams, PathHelper,
    WorkPackagesOverviewService, WorkPackageFieldService, WorkPackageService, EditableFieldsState,
    WorkPackagesDisplayHelper, NotificationsService) {

  var vm = this;

  vm.groupedFields = [];
  vm.hideEmptyFields = true;

  vm.cancel = cancel;

  vm.loaderPromise = null;

  vm.isFieldHideable = WorkPackagesDisplayHelper.isFieldHideableOnCreate;
  vm.isGroupHideable = function(groups, group, wp) {
    // custom wrapper for injecting a special callback
    return WorkPackagesDisplayHelper.isGroupHideable(groups, group, wp, vm.isFieldHideable);
  };
  vm.getLabel = WorkPackagesDisplayHelper.getLabel;
  vm.isSpecified = WorkPackagesDisplayHelper.isSpecified;
  vm.isEditable = WorkPackagesDisplayHelper.isEditable;
  vm.hasNiceStar = WorkPackagesDisplayHelper.hasNiceStar;
  vm.showToggleButton = WorkPackagesDisplayHelper.showToggleButton;

  vm.notifyCreation = function() {
    NotificationsService.addSuccess(I18n.t('js.notice_successful_create'));
  };

  activate();

  function activate() {
    EditableFieldsState.forcedEditState = true;
    EditableFieldsState.editAll.state = true;
    var data = {};
    if (angular.isDefined($stateParams.type)) {
      data = {
        _links: {
          type: {
            href: PathHelper.apiV3TypePath($stateParams.type)
          }
        }
      };
    }
    vm.loaderPromise = WorkPackageService.initializeWorkPackage($scope.projectIdentifier, data)
    .then(function(wp) {
      vm.workPackage = wp;
      WorkPackagesDisplayHelper.setFocus();
      $scope.workPackage = wp;
      $scope.$watchCollection('vm.workPackage.form', function() {
        vm.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
        var schema = WorkPackageFieldService.getSchema(vm.workPackage);
        var otherGroup = _.find(vm.groupedFields, { groupName: 'other' });
        otherGroup.attributes = [];
        _.forEach(schema.props, function(prop, propName) {
          if (propName.match(/^customField/)) {
            otherGroup.attributes.push(propName);
          }
        });
        otherGroup.attributes.sort(function(a, b) {
          var getLabel = function(field) {
            return vm.getLabel(vm.workPackage, field);
          };
          var left = getLabel(a).toLowerCase(),
              right = getLabel(b).toLowerCase();
          return left.localeCompare(right);
        });
      });
    });

    $scope.$on('workPackageUpdatedInEditor', function(e, workPackage) {
      $state.go('work-packages.list.details.overview', {workPackageId: workPackage.props.id});
    });
  }

  function cancel() {
    if ($rootScope.previousState && $rootScope.previousState.name) {
      vm.loaderPromise = $state.go($rootScope.previousState.name, $rootScope.previousState.params);
    } else {
      vm.loaderPromise = $state.go('^');
    }
  }
}
