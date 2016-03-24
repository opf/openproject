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

export class WorkPackageEditFormController {
  public workPackage;
  public fields = {};

  constructor(
    protected NotificationsService,
    protected $q,
    protected QueryService,
    protected $rootScope,
    protected $timeout) {
  }

  public loadSchema() {
    return this.workPackage.getSchema();
  }

  public updateWorkPackage() {
    var deferred = this.$q.defer();

    this.workPackage.save()
      .then(() => {
        angular.forEach(this.fields, field => field.setErrorState(false));
        deferred.resolve();
      this.$rootScope.$emit('workPackagesRefreshInBackground');
      })
      .catch((error) => {
        if (!error.data) {
          this.NotificationsService.addError("An internal error has occcurred.");
          return deferred.reject([]);
        }

        error.data.showErrorNotification();
        this.handleSubmissionErrors(error.data, deferred)
      });

    return deferred.promise;
  }

  private handleSubmissionErrors(error:any, deferred:any) {

    // Process single API errors
    this.handleErrorenousColumns(error.getInvolvedColumns());
    return deferred.reject();
  }

  private handleErrorenousColumns(columns:string[]) {
    var selected = this.QueryService.getSelectedColumnNames();
    var active = _.find(this.fields, (f:any) => f.active);
    columns.reverse().map(name => {
      if (selected.indexOf(name) === -1) {
        selected.splice(selected.indexOf(active.fieldName) + 1, 0, name);
      }
    });

    this.QueryService.setSelectedColumns(selected);
    this.$timeout(_ => {
      angular.forEach(this.fields, (field) => {
        field.setErrorState(columns.indexOf(field.fieldName) !== -1);
      });
    });
  }
}

function wpEditForm() {
  return {
    restrict: 'A',

    scope: {
      workPackage: '=wpEditForm'
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
