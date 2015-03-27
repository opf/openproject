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

module.exports = function(WorkPackageFieldService, EditableFieldsState, FocusHelper, $timeout, ApiHelper) {
  return {
    transclude: true,
    replace: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/edit_pane.html',
    controllerAs: 'editPaneController',
    controller: function($scope, WorkPackageService) {
      this.submit = function(notify) {
        var fieldController = $scope.fieldController;
        fieldController.isBusy = true;
        var pendingFormChanges = getPendingFormChanges();
        pendingFormChanges[fieldController.field] = fieldController.writeValue;
        var result = WorkPackageService.updateWorkPackage(EditableFieldsState.workPackage, notify);
        result.then(angular.bind(this, function() {
          $scope.$emit(
            'workPackageRefreshRequired',
            function(workPackage) {
              fieldController.isBusy = false;
              fieldController.isEditing = false;
              fieldController.updateWriteValue();
              this.error = null;
            }
          );
        }));
        result.catch(angular.bind(this, function(e) {
          fieldController.isBusy = false;
          this.error = ApiHelper.getErrorMessage(e);
          $scope.focusInput();
        }));

      };

      this.discardEditing = function() {
        $scope.fieldController.isEditing = false;
        var form = EditableFieldsState.workPackage.form;
        delete getPendingFormChanges()[$scope.fieldController.field];
        $scope.fieldController.updateWriteValue();
      };

      this.getPendingFormChanges = getPendingFormChanges;

      function getPendingFormChanges() {
        var form = EditableFieldsState.workPackage.form;
        form.pendingChanges = form.pendingChanges || angular.copy(form.embedded.payload.props);
        return form.pendingChanges;
      }
    },
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      scope.templateUrl = '/templates/components/inplace_editor/editable/' +
      WorkPackageFieldService.getInplaceEditStrategy(
        EditableFieldsState.workPackage,
        fieldController.field
      ) +
      '.html';

      scope.focusInput = function() {
        $timeout(function() {
          var inputElement = element.find('.focus-input');
          FocusHelper.focus(inputElement);
          inputElement.triggerHandler('keyup');
        });
      };

      element.bind('keydown keypress', function(e) {
        if (e.keyCode == 27) {
          scope.$apply(function() {
            scope.editPaneController.discardEditing();
          });
        }
      });

      scope.$watch('fieldController.writeValue', function(writeValue) {
        if (scope.fieldController.isEditing) {
          scope.editPaneController.getPendingFormChanges()[scope.fieldController.field] = writeValue;
        }
      }, true);

      scope.$watch('fieldController.isEditing', function(isEditing) {
        if (isEditing) {
          scope.editPaneController.error = null;
          scope.focusInput();
        }
      });
    }
  };
};
