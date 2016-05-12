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

import {ErrorResource} from "../api/api-v3/hal-resources/error-resource.service";
import {WorkPackageEditModeStateService} from "./wp-edit-mode-state.service";
import {WorkPackageEditFieldController} from "./wp-edit-field/wp-edit-field.directive";

export class WorkPackageEditFormController {
  public workPackage;
  public hasEditMode: boolean;
  public errorHandler: Function;
  public successHandler: Function;
  public fields = {};

  public lastErrorFields: string[] = [];
  public firstActiveField: string;

  constructor(protected $scope: ng.IScope,
              protected $q,
              protected $state,
              protected $rootScope,
              protected I18n,
              protected NotificationsService,
              protected QueryService,
              protected wpEditModeState: WorkPackageEditModeStateService,
              protected loadingIndicator) {

    if (this.hasEditMode) {
      wpEditModeState.register(this);
    }
  }

  public isFieldRequired(fieldName) {
    return _.filter((this.fields as any), (name: string, _field) => {
      return !this.workPackage[name] && this.workPackage.requiredValueFor(name);
    });
  }

  public registerField(field) {
    this.fields[field.fieldName] = field;
    field.setErrorState(this.lastErrorFields.indexOf(field.fieldName) !== -1);
  }

  public toggleEditMode(state: boolean) {
    this.$scope.$evalAsync(() => {
      angular.forEach(this.fields, (field) => {

        // Setup the field if it is not yet active
        if (state && field.isEditable && !field.active) {
          field.initializeField();
        }

        // Disable the field if is active
        if (!state && field.active) {
          field.reset();
        }
      });
    });
  }
  
  public closeAllFields() {
    angular.forEach(this.fields, (field:WorkPackageEditFieldController) => {
      field.deactivate();
    })
  }

  public get inEditMode() {
    return this.hasEditMode && this.wpEditModeState.active;
  }

  public get isEditable() {
    return this.workPackage.isEditable;
  }

  public loadSchema() {
    return this.workPackage.getSchema();
  }

  public updateWorkPackage() {
    var deferred = this.$q.defer();

    // Reset old error notifcations
    this.$rootScope.$emit('notifications.clearAll');
    this.lastErrorFields = [];

    this.workPackage.save()
      .then(() => {
        angular.forEach(this.fields, field => field.setErrorState(false));
        deferred.resolve();

        this.showSaveNotification();
        this.successHandler({workPackage: this.workPackage, fields: this.fields});
      })
      .catch((error) => {
        if (!(error.data instanceof ErrorResource)) {
          this.NotificationsService.addError("An internal error has occcurred.");
          return deferred.reject([]);
        }
        error.data.showErrorNotification();
        this.handleSubmissionErrors(error.data, deferred);
      });

    return deferred.promise;
  }

  private showSaveNotification() {
    var message = 'js.notice_successful_' + (this.workPackage.inlineCreated ? 'create' : 'update');
    this.NotificationsService.addSuccess({
      message: this.I18n.t(message),
      link: {
        target: _ => {
          this.loadingIndicator.mainPage = this.$state.go.apply(this.$state,
            ["work-packages.show.activity", {workPackageId: this.workPackage.id}]);
        },
        text: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen')
      }
    });
  }

  private handleSubmissionErrors(error: any, deferred: any) {

    // Process single API errors
    this.handleErroneousAttributes(error.getInvolvedAttributes());
    return deferred.reject();
  }

  private handleErroneousAttributes(attributes: string[]) {
    if (attributes.length === 0) return;

    // Allow additional error handling
    this.errorHandler({
      workPackage: this.workPackage,
      fields: this.fields,
      attributes: attributes
    });

    // Save erroneous fields for when new fields appear
    this.lastErrorFields = attributes;

    this.$scope.$evalAsync(() => {
      angular.forEach(this.fields, field => {
        field.setErrorState(attributes.indexOf(field.fieldName) !== -1);
      });

      // Activate + Focus on first field
      this.firstActiveField = attributes[0];

      // Activate that field
      // TODO: For inplace-edit, this may be undefined
      // since it doesn't yet expand erroneous attributes
      var firstErrorField = this.fields[this.firstActiveField];
      if (firstErrorField) {
        firstErrorField.activate(true);
      }
    });
  }
}

function wpEditForm() {
  return {
    restrict: 'A',

    scope: {
      workPackage: '=wpEditForm',
      hasEditMode: '=hasEditMode',
      errorHandler: '&wpEditFormOnError',
      successHandler: '&wpEditFormOnSave'
    },

    controller: WorkPackageEditFormController,
    controllerAs: 'vm',
    bindToController: true
  };
}

//TODO: Use 'openproject.wpEdit' module
angular
  .module('openproject')
  .directive('wpEditForm', wpEditForm);
