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
      displayEmpty: '@',
      schema: '=',
      object: '=',
      resource: '=',
      attribute: '='
    },

    bindToController: true,
    controller: WorkPackageTdController,
    controllerAs: 'vm'
  };
}

function WorkPackageTdController($scope, PathHelper, WorkPackagesHelper) {
  var vm = this;

  if (vm.workPackage) {
    vm.workPackage.getSchema().then(function(schema) {
      if (schema[vm.column.name] && vm.column.name === 'percentageDone') {
        // TODO: Check if we might alter the wp schema
        vm.displayType = 'Percent';
      }
      else if (schema[vm.column.name]) {
        vm.displayType = schema[vm.column.name].type;
      }
      else {
        vm.displayType = 'String';
      }

      setText(vm.displayType);
    });
  }

  if (vm.schema) {
    if (!vm.schema[vm.attribute] || !vm.object[vm.attribute] ) { return; }

    vm.displayType = vm.schema[vm.attribute].type;

    var text = vm.object[vm.attribute].value ||
                vm.object[vm.attribute].name ||
                vm.object[vm.attribute];

    vm.displayText = WorkPackagesHelper.formatValue(text, vm.displayType);
  }

  function setText(type) {
    if (vm.workPackage[vm.column.name] === null || vm.workPackage[vm.column.name] === undefined) {
      vm.displayText = '';
    }
    else if (vm.workPackage[vm.column.name].value !== undefined) {
      vm.displayText = WorkPackagesHelper.formatValue(vm.workPackage[vm.column.name].value, type);
    }
    else if (vm.workPackage[vm.column.name].name !== undefined) {
      vm.displayText = WorkPackagesHelper.formatValue(vm.workPackage[vm.column.name].name, type);
    }
    else {
      vm.displayText = WorkPackagesHelper.formatValue(vm.workPackage[vm.column.name], type);
    }
  }
}
