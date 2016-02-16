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
  .module('openproject.workPackages.directives')
  .directive('wpTd', wpTd);

function wpTd(){
  return {
    restrict: 'E',
    templateUrl: '/components/wp-table/wp-td/wp-td.directive.html',

    scope: {
      workPackage: '=',
      projectIdentifier: '=',
      column: '=',
      displayType: '@',
      displayEmpty: '@'
    },

    bindToController: true,
    controller: WorkPackageTdController,
    controllerAs: 'vm'
  };
}

function WorkPackageTdController($scope, PathHelper, WorkPackagesHelper) {
  var vm = this;
  
  vm.displayType = vm.displayType || 'text';

  $scope.$watch(dataAvailable, setColumnData);
  $scope.$watch('vm.workPackage', setColumnData, true);

  function dataAvailable() {
    if (!vm.workPackage) return false;

    if (vm.column.custom_field) {
      return customValueAvailable();
    }

    return vm.workPackage.hasOwnProperty(vm.column.name);
  }

  function customValueAvailable() {
    var customFieldId = vm.column.custom_field.id;

    return vm.workPackage.custom_values &&
      vm.workPackage.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customFieldId;
      }).length;
  }

  function setColumnData() {
    setDisplayText(getFormattedColumnValue());

    if (vm.column.meta_data.link.display) {
      var id = WorkPackagesHelper.getColumnDataId(vm.workPackage, vm.column)
      if (id) {
        displayDataAsLink(id);
      }
    } else {
      setCustomDisplayType();
    }
  }

  function getFormattedColumnValue() {
    var custom_field = vm.column.custom_field;

    if (custom_field) {
      return WorkPackagesHelper.getFormattedCustomValue(vm.workPackage, custom_field);

    } else {
      return WorkPackagesHelper.getFormattedColumnData(vm.workPackage, vm.column);
    }
  }

  function setDisplayText(value) {
    vm.displayText = vm.displayEmpty || '';

    if (typeof value === 'number' || value){
      vm.displayText = value;
    }
  }

  function setCustomDisplayType() {
    if (vm.column.name === 'done_ratio') vm.displayType = 'progress_bar';
  }

  function displayDataAsLink(id) {
    var linkMeta = vm.column.meta_data.link;

    if (linkMeta.model_type === 'work_package') {
      var projectId = vm.projectIdentifier || '';

      vm.displayType = 'ref';
      vm.stateRef = "work-packages.show.activity({projectPath: '" + projectId +
            "', workPackageId: " + id + "})";

    } else {
      vm.displayType = 'link';
      vm.url = getLinkFor(id, linkMeta);
    }
  }

  function getLinkFor(id, linkMeta){
    var types = {
      get user() {
        if (vm.workPackage[vm.column.name] && vm.workPackage[vm.column.name].type == 'Group') {
          vm.displayType = 'text';

          return '';
        }

        return PathHelper.userPath(id);
      },

      get version() {
        return PathHelper.versionPath(id);
      },

      get project() {
        return PathHelper.projectPath(id);
      }
    };

    return types[linkMeta.model_type] || '';
  }
}
