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
    ApiHelper) {

  return {
    saveWorkPackage: function () {
      var deferred = $q.defer();

      if (EditableFieldsState.errors) {
        return deferred.reject(EditableFieldsState.errors);
      }

      EditableFieldsState.isBusy = true;

      this.updateWorkPackageForm().then(function () {
        WorkPackageService.updateWorkPackage(EditableFieldsState.workPackage)
          .then(function (updatedWorkPackage) {
            $rootScope.$broadcast('workPackageUpdatedInEditor', updatedWorkPackage);
            $rootScope.$broadcast('uploadPendingAttachments', updatedWorkPackage);

            deferred.resolve(updatedWorkPackage);
          })

          .catch(function (errors) {
            EditableFieldsState.isBusy = false;
            EditableFieldsState.errors = {
              _common: ApiHelper.getErrorMessages(errors)
            };
            deferred.reject(errors);
          });
        });

      return deferred.promise;
    },

    updateWorkPackageForm: function () {
      var deferred = $q.defer();

      WorkPackageService.loadWorkPackageForm(EditableFieldsState.workPackage)
        .then(function(form) {
          EditableFieldsState.workPackage.form = form;

          if (_.isEmpty(form.embedded.validationErrors.props)) {
            deferred.resolve(form);

          } else {
            EditableFieldsState.errors = {};
            _.forEach(form.embedded.validationErrors.props, function(error, field) {
              if(field === 'startDate' || field === 'dueDate') {
                EditableFieldsState.errors['date'] = error.message;
              } else {
                EditableFieldsState.errors[field] = error.message;
              }
            });

            deferred.reject(EditableFieldsState.errors);
          }
        })

        .catch(function(errors) {
          deferred.reject(errors);
        });

      return deferred.promise;
    }
  };
}
