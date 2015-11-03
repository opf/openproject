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
  .directive('inplaceEditorDisplayPane', inplaceEditorDisplayPane);

function inplaceEditorDisplayPane(EditableFieldsState, $timeout, I18n) {
  return {
    replace: true,
    transclude: true,
    require: '^workPackageField',
    templateUrl: '/components/inplace-edit/directives/display-pane/display-pane.directive.html',
    controller: InplaceEditorDisplayPaneController,
    controllerAs: 'displayPaneController',

    link: function(scope, element, attrs, fieldController) {
      var field = scope.field;

      scope.fieldController = fieldController;
      scope.editableFieldsState = EditableFieldsState;

      scope.$watchCollection('editableFieldsState.workPackage.form', function() {
        var strategy = field.getInplaceDisplayStrategy();

        if (strategy !== scope.displayStrategy) {
          scope.displayStrategy = strategy;
          scope.templateUrl = '/templates/inplace-edit/display/fields/' + strategy +'.html';
        }
      });

      scope.$watch('editableFieldsState.errors', function(errors) {
        if (errors && errors[field.name] && field.isEditable()) {
          scope.displayPaneController.startEditing();
        }
      }, true);

      scope.$watch('fieldController.isEditing', function(isEditing, oldIsEditing) {
        if (!isEditing && !fieldController.lockFocus) {
          $timeout(function() {
            if (oldIsEditing) {
              // check old value to not trigger focus on the first time
              element.find('.inplace-editing--trigger-link').focus();
            }
            element.find('.inplace-edit--read-value a').off('click').on('click', function(e) {
              e.stopPropagation();
            });
          });
        }

        fieldController.lockFocus = false;
      });
    }
  };
}
inplaceEditorDisplayPane.$inject = ['EditableFieldsState', '$timeout', 'I18n'];


function InplaceEditorDisplayPaneController($scope, HookService) {
  var field = $scope.field;

  this.placeholder = field.placeholder;

  this.startEditing = function() {
    if (!field.isEditable()) {
      throw 'Trying to edit the non editable field "' + field.name + '"';
    }
    var fieldController = $scope.fieldController;
    fieldController.isEditing = true;
  };

  // for dynamic type that is set by plugins
  // refactor to a service method the whole extraction
  this.getDynamicDirectiveName = function() {
    return HookService.call('workPackageOverviewAttributes', {
      type: field.resource.schema.props[field.name].type,
      field: field.name,
      workPackage: field.resource
    })[0];
  };
}
InplaceEditorDisplayPaneController.$inject = ['$scope', 'HookService'];
