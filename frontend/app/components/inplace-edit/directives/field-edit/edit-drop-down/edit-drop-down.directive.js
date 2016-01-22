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
  .module('openproject.inplace-edit')
  .directive('inplaceEditorDropDown', inplaceEditorDropDown);

function inplaceEditorDropDown(EditableFieldsState, FocusHelper, inplaceEditAll) {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    require: '^workPackageField',
    templateUrl: '/components/inplace-edit/directives/field-edit/edit-drop-down/' +
      'edit-drop-down.directive.html',

    controller: InplaceEditorDropDownController,
    controllerAs: 'customEditorController',

    link: function(scope, element) {
      var field = scope.field;

      EditableFieldsState.isBusy = true;

      scope.emptyField = !scope.field.isRequired();

      scope.customEditorController.updateAllowedValues(field.name).then(function() {
        EditableFieldsState.isBusy = false;

        if (!inplaceEditAll.state) {
          FocusHelper.focusElement(element);
        }
      });

      scope.$watch('field.value', function(value) {
        if (value === undefined) {
          scope.field.value = scope.customEditorController.emptyOption;
        }
      });
    }
  };
}

function InplaceEditorDropDownController($q, $scope, WorkPackageFieldConfigurationService) {

  var customEditorController = this;

  this.allowedValues = [];
  this.emptyOption = {
    props: { href: null },
    href: null,
    name: $scope.field.placeholder
  };

  function extractOptions(values) {
    var options = values;

    // Extract options and groups from embedded values only
    if ($scope.field.allowedValuesEmbedded()) {
       options = _.map(values, function(item) {
        return _.extend({}, item._links.self, {
          name: item._links.self.title || item.value,
          group: WorkPackageFieldConfigurationService
                   .getDropDownOptionGroup($scope.field.name, item),
          props: { href: item._links.self.href }
        });
      });
    }

    return options;
  }

  this.hasNullOption = function() {
    return !$scope.field.isRequired() ||
      $scope.field.value.href === customEditorController.emptyOption.href;
  };

  this.updateAllowedValues = function(field) {

    return $q(function(resolve) {
      $scope.field.getAllowedValues()
        .then(function(values) {
          var options;
          var sorting = WorkPackageFieldConfigurationService
            .getDropdownSortingStrategy(field);

          if (sorting !== null) {
            values = _.sortBy(values, sorting);
          }

          options = extractOptions(values);

          if ($scope.field.value === null ||
              _.find(options, { href: $scope.field.value.href }) === undefined) {
            $scope.field.value = customEditorController.emptyOption;
          }

          customEditorController.allowedValues = options;

          resolve();
        });
    });
  };
}
