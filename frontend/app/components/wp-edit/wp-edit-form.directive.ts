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
  public firstActiveField:string;

  constructor(
    protected I18n,
    protected NotificationsService,
    protected $q,
    protected QueryService,
    protected $state,
    protected $rootScope,
    protected loadingIndicator,
    protected $timeout) {
  }

  public isFieldRequired(fieldName) {
    return _.filter((this.fields as any), (name:string, _field) => {
      return !this.workPackage[name] && this.workPackage.requiredValueFor(name);
    });
  }

  public loadSchema() {
    return this.workPackage.getSchema();
  }

  public updateWorkPackage() {
    var deferred = this.$q.defer();

    // Reset old error notifcations
    this.$rootScope.$emit('notifications.clearAll');

    this.workPackage.save()
      .then(() => {
        angular.forEach(this.fields, field => field.setErrorState(false));
        deferred.resolve();

        this.showSaveNotification();
        this.$rootScope.$emit('workPackageSaved', this.workPackage);
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

  private showSaveNotification() {
    var message = 'js.notice_successful_' + (this.workPackage.inlineCreated ? 'create' : 'update');
    this.NotificationsService.addSuccess({
      message: this.I18n.t(message),
      link: {
        target: _ => {
          this.loadingIndicator.mainPage = this.$state.go.apply(this.$state,
            ["work-packages.show.activity", { workPackageId: this.workPackage.id }]);
        },
        text: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen')
      }
    });
  }

  private handleSubmissionErrors(error:any, deferred:any) {

    // Process single API errors
    this.handleErrorenousColumns(error.getInvolvedColumns());
    return deferred.reject();
  }

  private handleErrorenousColumns(columns:string[]) {
    return if (columns.length === 0);

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

      // Activate + Focus on first field
      this.firstActiveField = columns[0];
      this.fields[this.firstActiveField].activate(true);
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
