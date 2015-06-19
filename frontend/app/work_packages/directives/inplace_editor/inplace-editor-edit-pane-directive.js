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

module.exports = function(
  WorkPackageFieldService,
  EditableFieldsState,
  FocusHelper,
  $timeout,
  ApiHelper) {
  return {
    transclude: true,
    replace: true,
    scope: true,
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/edit_pane.html',
    controllerAs: 'editPaneController',
    controller: function($scope, WorkPackageService) {
      var vm = this;
      var acknowledgedValidationErrors = ['required', 'number'];

      this.submit = function(notify) {
        var fieldController = $scope.fieldController;
        var pendingFormChanges = getPendingFormChanges();
        pendingFormChanges[fieldController.field] = fieldController.writeValue;
        if (vm.editForm.$invalid) {
          var detectedViolations = [];
          acknowledgedValidationErrors.forEach(function(error) {
            if (vm.editForm.$error[error]) {
              detectedViolations.push(I18n.t('js.inplace.errors.' + error, {
                field: fieldController.getLabel()
              }));
            }
          });
          if (detectedViolations.length) {
            EditableFieldsState.errors = EditableFieldsState.errors || {};
            EditableFieldsState.errors[fieldController.field] = detectedViolations.join(' ');
            return false;
          }
        }
        fieldController.state.isBusy = true;
        WorkPackageService.loadWorkPackageForm(EditableFieldsState.workPackage).then(
          function(form) {
            EditableFieldsState.workPackage.form = form;
            if (_.isEmpty(form.embedded.validationErrors.props)) {
              var result = WorkPackageService.updateWorkPackage(
                EditableFieldsState.workPackage,
                notify
              );
              result.then(angular.bind(this, function() {
                $scope.$emit(
                  'workPackageRefreshRequired',
                  function() {
                    fieldController.state.isBusy = false;
                    fieldController.isEditing = false;
                    fieldController.updateWriteValue();
                    EditableFieldsState.errors = null;
                  }
                );
              })).catch(setFailure);
            } else {
              afterError();
              EditableFieldsState.errors = {};
               _.forEach(form.embedded.validationErrors.props, function(error, field) {
                if(field === 'startDate' || field === 'dueDate') {
                  EditableFieldsState.errors['date'] = error.message;
                } else {
                  EditableFieldsState.errors[field] = error.message;
                }
              });
            }
          }).catch(setFailure);


      };

      this.discardEditing = function() {
        $scope.fieldController.isEditing = false;
        delete getPendingFormChanges()[$scope.fieldController.field];
        $scope.fieldController.updateWriteValue();
        if (
          EditableFieldsState.errors &&
          EditableFieldsState.errors.hasOwnProperty($scope.fieldController.field)
        ) {
          delete EditableFieldsState.errors[$scope.fieldController.field];
        }
      };

      this.isActive = function() {
        return $scope.fieldController.field === EditableFieldsState.activeField;
      };

      this.markActive = function() {
        EditableFieldsState.activeField = $scope.fieldController.field;
      };

      this.getPendingFormChanges = getPendingFormChanges;

      function getPendingFormChanges() {
        var form = EditableFieldsState.workPackage.form;
        form.pendingChanges = form.pendingChanges || angular.copy(form.embedded.payload.props);
        return form.pendingChanges;
      }

      function afterError() {
        $scope.fieldController.state.isBusy = false;
        $scope.focusInput();
      }
      function setFailure(e) {
        afterError();
        EditableFieldsState.errors = {
          '_common': ApiHelper.getErrorMessage(e)
        };
      }
    },
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      scope.editableFieldsState = EditableFieldsState;

      scope.editPaneController.isRequired = WorkPackageFieldService.isRequired(
        EditableFieldsState.workPackage,
        fieldController.field
      );

      scope.$watchCollection('editableFieldsState.workPackage.form', function(form) {
        var strategy = WorkPackageFieldService.getInplaceEditStrategy(
          EditableFieldsState.workPackage,
          fieldController.field
        );

        if (fieldController.field === 'date' && strategy === 'date') {
          form.pendingChanges = scope.editPaneController.getPendingFormChanges();
          form.pendingChanges['startDate'] =
          form.pendingChanges['dueDate'] =
          fieldController.writeValue ? fieldController.writeValue['dueDate'] : null;
        }

        if (strategy !== scope.strategy) {
          scope.strategy = strategy;
          scope.templateUrl = '/templates/components/inplace_editor/editable/' +
            scope.strategy + '.html';
          fieldController.updateWriteValue();
        }
      });

      scope.focusInput = function() {
        $timeout(function() {
          var inputElement = element.find('.focus-input');
          FocusHelper.focus(inputElement);
          inputElement.triggerHandler('keyup');
          scope.editPaneController.markActive();
          inputElement.off('focus.inplace').on('focus.inplace', function() {
            // ♥♥♥ angular ♥♥♥
            scope.$apply(function() {
              scope.editPaneController.markActive();
            });
          });
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
          var pendingChanges = scope
            .editPaneController
            .getPendingFormChanges();
          pendingChanges[scope.fieldController.field] = writeValue;
        }
      }, true);
      scope.$on('workPackageRefreshed', function() {
        scope.editPaneController.discardEditing();
      });
      scope.$watch('editableFieldsState.errors', function(errors) {
        scope.editPaneController.error = null;
        if (!_.isEmpty(errors)) {
          // uncomment when we are sure we can bind every message to every field
          // scope
          //  .editPaneController
          //  .error = errors[scope.fieldController.field] || errors['_common'];
          scope.editPaneController.error = _.map(errors, function(error) {
            return error;
          }).join('\n');
        }
      }, true);

      scope.$watch('fieldController.isEditing', function(isEditing) {
        if (isEditing) {
          scope.focusInput();
        }
      });
    }
  };
};
