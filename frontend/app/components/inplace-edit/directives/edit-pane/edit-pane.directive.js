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
    require: '^workPackageField',
    templateUrl: '/components/inplace-edit/directives/edit-pane/edit-pane.directive.html',

    controllerAs: 'editPaneController',
    controller: InplaceEditorEditPaneController,

    link: function(scope, element, attrs, fieldController) {
      var field = scope.field;

      scope.fieldController = fieldController;
      scope.editableFieldsState = EditableFieldsState;

      scope.focusInput = function() {
        $timeout(function() {
          var inputElement = element.find('.focus-input');
          FocusHelper.focus(inputElement);
          inputElement.triggerHandler('keyup');
          scope.editPaneController.markActive();
          inputElement.off('focus.inplace').on('focus.inplace', function() {
            scope.$apply(function() {
              scope.editPaneController.markActive();
            });
          });
        });
      };

      if (!EditableFieldsState.forcedEditState) {
        element.bind('keydown keypress', function(e) {
          if (e.keyCode === 27 && !EditableFieldsState.editAll.state) {
            scope.$apply(function() {
              scope.editPaneController.discardEditing();
            });
          }
        });
      }

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
inplaceEditorEditPane.$inject = ['EditableFieldsState', 'FocusHelper', '$timeout', '$q'];


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

  var uploadPendingAttachments = function(wp) {
    $rootScope.$broadcast('uploadPendingAttachments', wp);
  };

  this.submit = function() {
    EditableFieldsState.save().then(function() {
      $location.hash(null);
      $timeout(function() {
        $element[0].scrollIntoView(false);
      });
    });
  };

  this.handleFailure = function(e, submit) {
    setFailure(e);
    submit.reject(e);
  };

  this.updateWorkPackageForm = function(submit) {
    WorkPackageService.loadWorkPackageForm(EditableFieldsState.workPackage).then(
      function(form) {
        field.resource.form = form;
        EditableFieldsState.workPackage.form = form;
        if (_.isEmpty(form.embedded.validationErrors.props)) {
          submit.resolve();
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
      }).catch(function(e) {
        vm.handleFailure(e, submit);
      });

    return submit.promise;
  };

  this.submitField = function() {
    var submit = $q.defer();
    var fieldController = $scope.fieldController;
    var pendingFormChanges = EditableFieldsState.getPendingFormChanges();
    var detectedViolations = [];

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
      vm.updateWorkPackageForm(submit).then(function() {
        var result = WorkPackageService.updateWorkPackage(
          EditableFieldsState.workPackage
        );
        result.then(angular.bind(this, function(updatedWorkPackage) {
          submit.resolve();
          field.resource = _.extend(field.resource, updatedWorkPackage);

          $scope.$emit('workPackageUpdatedInEditor', updatedWorkPackage);
          uploadPendingAttachments(updatedWorkPackage);
        })).catch(function(e) {
          vm.handleFailure(e, submit);
        });
      });
    }

    return submit.promise;
  };

  this.discardEditing = function() {
    EditableFieldsState.discard(field.name);
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

  this.isRequired = function() {
    return field.isRequired();
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

  $scope.$watch('field.value', function(value) {
    if ($scope.fieldController.isEditing) {
      var pendingChanges = EditableFieldsState.getPendingFormChanges();
      pendingChanges[field.name] = value;
      vm.markActive();
    }
  }, true);

  $scope.$watchCollection('field.resource.form', function(form) {
    var strategy = field.getInplaceEditStrategy();

    if (field.name === 'date' && strategy === 'date') {
      form.pendingChanges = EditableFieldsState.getPendingFormChanges();
      form.pendingChanges['startDate'] =
        form.pendingChanges['dueDate'] =
          field.value ? field.value['dueDate'] : null;
    }

    if (strategy !== $scope.strategy) {
      $scope.strategy = strategy;
      $scope.templateUrl = '/templates/inplace-edit/edit/fields/' + strategy + '.html';
    }
  });

  $scope.$on('form.updateRequired', function() {
    var submit = $q.defer();
    vm.updateWorkPackageForm(submit);
  });

  $scope.$on('workPackageRefreshed', function() {
    vm.discardEditing();
    EditableFieldsState.isBusy = false;
  });
}
InplaceEditorEditPaneController.$inject = ['$scope', '$element', '$location', '$timeout', '$q',
  '$rootScope', 'WorkPackageService', 'EditableFieldsState', 'ApiHelper', 'NotificationsService'];
