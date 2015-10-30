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
  .directive('inplaceEditorEditPane', inplaceEditorEditPane);

function inplaceEditorEditPane(EditableFieldsState, FocusHelper, $timeout) {
  return {
    transclude: true,
    replace: true,
    require: '^workPackageField',
    templateUrl: '/components/inplace-edit/directives/edit-pane/edit-pane.directive.html',
    controllerAs: 'editPaneController',
    controller: InplaceEditorEditPaneController,
    link: function(scope, element, attrs, fieldController) {
      var field = scope.field;

      scope.fieldController = fieldController;
      scope.editableFieldsState = EditableFieldsState;

      scope.editPaneController.isRequired = function() {
        return field.isRequired();
      };

      scope.$watchCollection('editableFieldsState.workPackage.form', function(form) {
        var strategy = field.getInplaceEditStrategy();

        if (field.name === 'date' && strategy === 'date') {
          form.pendingChanges = EditableFieldsState.getPendingFormChanges();
          form.pendingChanges['startDate'] =
            form.pendingChanges['dueDate'] =
              field.value ? field.value['dueDate'] : null;
        }

        if (strategy !== scope.strategy) {
          scope.strategy = strategy;
          scope.templateUrl = '/templates/inplace-edit/edit/fields/' +
            scope.strategy + '.html';
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

      if (!EditableFieldsState.forcedEditState) {
        element.bind('keydown keypress', function(e) {
          if (e.keyCode === 27) {
            scope.$apply(function() {
              scope.editPaneController.discardEditing();
            });
          }
        });
      }

      scope.$watch('field.value', function(value) {
        if (scope.fieldController.isEditing) {
          var pendingChanges = EditableFieldsState.getPendingFormChanges();
          pendingChanges[field.name] = value;
        }
      }, true);
      scope.$on('workPackageRefreshed', function() {
        scope.editPaneController.discardEditing();
      });

      scope.$watch('fieldController.isEditing', function(isEditing) {
        var efs = EditableFieldsState;

        if (isEditing && !efs.editAll.state && !efs.forcedEditState) {
          scope.focusInput();

        } else if (efs.editAll.state && efs.editAll.isFocusField(field.name)) {
          $timeout(function () {
            var focusElement = element.find('.focus-input');
            focusElement.length && focusElement.focus()[0].select();
          });
        }
      });
    }
  };
}
inplaceEditorEditPane.$inject = ['EditableFieldsState', 'FocusHelper', '$timeout'];


function InplaceEditorEditPaneController($scope, $element, $location, $timeout, $q, $rootScope,
    WorkPackageService, EditableFieldsState, ApiHelper, NotificationsService) {

  var showErrors = function() {
    var errors  = EditableFieldsState.errors;
    if (_.isEmpty(_.keys(errors))) {
      return;
    }
    var errorMessages = _.flatten(_.map(errors), true);
    NotificationsService.addError(I18n.t('js.label_validation_error'), errorMessages);
  };

  var vm = this;
  var field = $scope.field;

  // go full retard
  var uploadPendingAttachments = function(wp) {
    $rootScope.$broadcast('uploadPendingAttachments', wp);
  };

  // Propagate submission to all active fields
  // not contained in the workPackage.form (e.g., comment)
  this.submit = function(notify) {
    EditableFieldsState.save(notify, function() {
      // Clears the location hash, as we're now
      // scrolling to somewhere else
      $location.hash(null);
      $timeout(function() {
        $element[0].scrollIntoView(false);
      });
    });
  };

  this.submitField = function(notify) {
    var submit = $q.defer();
    var fieldController = $scope.fieldController;
    var pendingFormChanges = EditableFieldsState.getPendingFormChanges();
    var detectedViolations = [];
    var handleFailure = function(e) {
      setFailure(e);
      submit.reject(e);
    };

    pendingFormChanges[field.name] = field.value;
    if (vm.editForm.$invalid) {
      var acknowledgedValidationErrors = Object.keys(vm.editForm.$error);
      acknowledgedValidationErrors.forEach(function(error) {
        if (vm.editForm.$error[error]) {
          detectedViolations.push(I18n.t('js.inplace.errors.' + error, {
            field: field.getLabel()
          }));
        }
      });
      submit.reject();
    }
    if (detectedViolations.length) {
      EditableFieldsState.errors = EditableFieldsState.errors || {};
      EditableFieldsState.errors[field.name] = detectedViolations.join(' ');
      showErrors();
      submit.reject();
    } else {
      fieldController.state.isBusy = true;
      WorkPackageService.loadWorkPackageForm(EditableFieldsState.workPackage).then(
        function(form) {
          EditableFieldsState.workPackage.form = form;
          if (_.isEmpty(form.embedded.validationErrors.props)) {
            var result = WorkPackageService.updateWorkPackage(
              EditableFieldsState.workPackage,
              notify
            );
            result.then(angular.bind(this, function(updatedWorkPackage) {
              submit.resolve();
              field.resource = _.extend(field.resource, updatedWorkPackage);

              $scope.$emit('workPackageUpdatedInEditor', updatedWorkPackage);
              $scope.$on('workPackageRefreshed', function() {
                fieldController.state.isBusy = false;
                fieldController.isEditing = false;
              });
              uploadPendingAttachments(updatedWorkPackage);
            })).catch(handleFailure);
          } else {
            afterError();
            submit.reject();
            EditableFieldsState.errors = {};
            _.forEach(form.embedded.validationErrors.props, function(error, field) {
              if(field === 'startDate' || field === 'dueDate') {
                EditableFieldsState.errors['date'] = error.message;
              } else {
                EditableFieldsState.errors[field] = error.message;
              }
            });

            showErrors();
          }
        }).catch(handleFailure);
    }

    return submit.promise;
  };

  this.discardEditing = function() {
    $scope.fieldController.isEditing = false;
    delete EditableFieldsState.submissionPromises['work_package'];
    delete EditableFieldsState.getPendingFormChanges()[field.name];
    if (
      EditableFieldsState.errors &&
      EditableFieldsState.errors.hasOwnProperty(field.name)
    ) {
      delete EditableFieldsState.errors[field.name];
    }
  };

  this.isActive = function() {
    return EditableFieldsState.isActiveField(field.name);
  };

  this.markActive = function() {
    EditableFieldsState.submissionPromises['work_package'] = {
      field: field.name,
      thePromise: this.submitField,
      prepend: true
    };
    EditableFieldsState.currentField = field.name;
  };

  function afterError() {
    $scope.fieldController.state.isBusy = false;
    $scope.focusInput();
  }
  function setFailure(e) {
    afterError();
    EditableFieldsState.errors = {
      '_common': ApiHelper.getErrorMessages(e)
    };
    showErrors();
  }

  $scope.$watch('editableFieldsState.editAll.state', function(state) {
    $scope.fieldController.isEditing = state;
    $scope.fieldController.lockFocus = true;
  });
}
InplaceEditorEditPaneController.$inject = ['$scope', '$element', '$location', '$timeout', '$q',
  '$rootScope', 'WorkPackageService', 'EditableFieldsState', 'ApiHelper', 'NotificationsService'];
