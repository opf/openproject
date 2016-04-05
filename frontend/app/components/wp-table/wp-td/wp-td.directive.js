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
    replace: true,
    templateUrl: '/components/wp-table/wp-td/wp-td.directive.html',

    scope: {
      schema: '=',
      object: '=',
      attribute: '='
    },

    bindToController: true,
    controller: WorkPackageTdController,
    controllerAs: 'vm'
  };
}

function WorkPackageTdController($scope, I18n, PathHelper, WorkPackagesHelper) {
  var vm = this;
      vm.displayText = I18n.t('js.work_packages.placeholders.default');

  function setDisplayType() {
    // TODO: alter backend so that percentageDone has the type
    // 'Percent' already
    if (vm.attribute === 'percentageDone') {
      vm.displayType = 'Percent';
    } else if (vm.attribute === 'id') {
      // Show a link to the work package for the ID
      vm.displayType = 'SelfLink';
      vm.displayLink = PathHelper.workPackagePath(vm.object.id);
    } else {
      vm.displayType = vm.schema[vm.attribute].type;
    }
  }

  function updateAttribute() {
    if (!vm.schema[vm.attribute]) {
      return;
    }

    if (!vm.object[vm.attribute] ) {
      vm.displayText = I18n.t('js.work_packages.placeholders.default');
      return;
    }

    setDisplayType();

    var text = vm.object[vm.attribute].value ||
                vm.object[vm.attribute].name ||
                vm.object[vm.attribute];

    vm.displayText = WorkPackagesHelper.formatValue(text, vm.displayType);
  }

  $scope.$watch('vm.object.' + vm.attribute, updateAttribute);
  $scope.$watch('vm.schema.$loaded', updateAttribute);
}
