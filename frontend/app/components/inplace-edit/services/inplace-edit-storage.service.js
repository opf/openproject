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
  .factory('inplaceEditStorage', inplaceEditStorage);

function inplaceEditStorage($q, $rootScope, EditableFieldsState, WorkPackageService,
  ActivityService, inplaceEditForm, ApiHelper, inplaceEditErrors) {

  var handleAPIErrors = function (deferred) {
    return function (errors) {
      inplaceEditErrors.errors = {
        _common: ApiHelper.getErrorMessages(errors)
      };

      deferred.reject(inplaceEditErrors.errors)
    }
  };

  return {
    saveWorkPackage: function () {
      var deferred = $q.defer();

      if (inplaceEditErrors.errors) {
        deferred.reject(inplaceEditErrors.errors);
        return deferred.promise;
      }

      EditableFieldsState.isBusy = true;

      this.updateWorkPackageForm()
        .then(function () {
          WorkPackageService.updateWorkPackage(EditableFieldsState.workPackage)
            .then(function (updatedWorkPackage) {

              $rootScope.$broadcast('workPackageUpdatedInEditor', updatedWorkPackage);
              $rootScope.$broadcast('uploadPendingAttachments', updatedWorkPackage);

              EditableFieldsState.editAll.cancel();

              deferred.resolve(updatedWorkPackage);
            })
            .catch(handleAPIErrors(deferred));
        })
        .catch(deferred.reject);

      return deferred.promise;
    },

    /**
     * Refreshes the work package form without validation,
     * but rejects upon API errors.
     */
    refreshWorkPackageForm: function() {
      var deferred = $q.defer();
      WorkPackageService.loadWorkPackageForm(EditableFieldsState.workPackage)
        .then(function(form) {
          var editForm = inplaceEditForm.getForm(EditableFieldsState.workPackage.props.id);
          editForm.resource.form = form;
          EditableFieldsState.workPackage.form = form;

          editForm.updateFieldValues();

          deferred.resolve(form);
      }).catch(handleAPIErrors(deferred));

      return deferred.promise;
    },

    /**
     * Updates and processes the work package form, validating
     * and rejecting upon form errors.
     */
    updateWorkPackageForm: function () {
      var deferred = $q.defer();

      this.refreshWorkPackageForm().then(function(form) {
        if (_.isEmpty(form.embedded.validationErrors.props)) {
          deferred.resolve(form);

        } else {
          inplaceEditErrors.errors = {};
          _.forEach(form.embedded.validationErrors.props, function(error, field) {
            var fieldName = field;

            if(field === 'startDate' || field === 'dueDate') {
              fieldName = 'date';
            }

            inplaceEditErrors.errors[fieldName] = error.message;
          });

          deferred.reject(inplaceEditErrors.errors);
        }
      }).catch(deferred.reject);

      return deferred.promise;
    },

    addComment: function (value) {
      return ActivityService.createComment(EditableFieldsState.workPackage, value);
    }
  };
}
