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

function inplaceEditorDropDown(EditableFieldsState, FocusHelper) {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    require: '^workPackageField',
    templateUrl: '/components/inplace-edit/directives/field-edit/edit-drop-down/' +
      'edit-drop-down.directive.html',

    controller: InplaceEditorDropDownController,
    controllerAs: 'customEditorController',

    link: function(scope, element, attrs, fieldController) {
      var field = scope.field;

      fieldController.state.isBusy = true;

      scope.emptyField = !scope.field.isRequired();

      scope.customEditorController.updateAllowedValues(field.name).then(function() {
        fieldController.state.isBusy = false;

        if (!EditableFieldsState.forcedEditState) {
          EditableFieldsState.editAll.state || FocusHelper.focusUiSelect(element);
        }
      });
    }
  };
}
inplaceEditorDropDown.$inject = ['EditableFieldsState', 'FocusHelper'];

function InplaceEditorDropDownController($q, $scope, I18n, WorkPackageFieldConfigurationService) {

  this.allowedValues = [];

  function extractOptions(values) {
    var options = values;

    // Extract options and groups from embedded values only
    if ($scope.field.allowedValuesEmbedded()) {
       options = _.map(values, function(item) {
        return _.extend({}, item._links.self, {
          name: item._links.self.title,
          group: WorkPackageFieldConfigurationService
                   .getDropDownOptionGroup($scope.field.name, item)
        });
      });
    }

    return options;
  }

  this.updateAllowedValues = function(field) {
    var customEditorController = this;

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

          if (!$scope.field.isRequired()) {
            options = addEmptyOption(options);
          }

          addHrefTracker(options);

          customEditorController.allowedValues = options;

          resolve();
        });
    });
  };

  var addEmptyOption = function(values) {
    var emptyOption = { props: { href: null,
                                 name: $scope.field.placeholder } };

    if (!$scope.field.isRequired()) {
      var arrayWithEmptyOption = [emptyOption.props];

      values = arrayWithEmptyOption.concat(values);

      if ($scope.field.value === null) {
        $scope.field.value = emptyOption;
      }
    }

    return values;
  };

  // We have to maintain a separate property just to track the object by
  // in the template. This is due to angular aparently not being able to
  // track correclty with a field having null as it's value. It does work for
  // 'null' (String) however.
  var addHrefTracker = function(values) {
    _.forEach(values, function(value) {
      value.hrefTracker = String(value.href);
    });

    $scope.field.value.props.hrefTracker = String($scope.field.value.props.href);
  };
}
InplaceEditorDropDownController.$inject = ['$q', '$scope', 'I18n',
  'WorkPackageFieldConfigurationService'];
