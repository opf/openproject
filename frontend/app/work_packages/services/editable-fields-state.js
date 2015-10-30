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

module.exports = function($q, $rootScope) {
  var EditableFieldsState = {
    workPackage: null,
    errors: null,
    isBusy: false,
    currentField: null,
    submissionPromises: {},
    forcedEditState: false,

    isActiveField: function (field) {
      return !(this.forcedEditState || this.editAll.state) && this.currentField === field;
    },

    getPendingFormChanges: function () {
      var form = this.workPackage.form;
      return form.pendingChanges = form.pendingChanges || angular.copy(form.embedded.payload.props);
    },

    save: function (notify, callback) {
      // We have to ensure that some promises are executed earlier then others
      var promises = [];
      angular.forEach(this.submissionPromises, function(field) {
        var p = field.thePromise.call(this, notify);
        promises[field.prepend ? 'unshift' : 'push' ](p);
      });

      return $q.all(promises).then(angular.bind(this, function() {
        // Update work package after this call
        $rootScope.$broadcast('workPackageRefreshRequired', callback);
        this.errors = null;
        this.submissionPromises = {};
        this.currentField = null;
        this.editAll.stop();
      }));
    },

    editAll: {
      focusField: 'subject',

      cancel: function () {
        this.stop();
      },

      get allowed() {
        return EditableFieldsState.workPackage && !!EditableFieldsState.workPackage.links.update;
      },

      start: function () {
        return this.state = true;
      },

      stop: function () {
        return this.state = false;
      },

      toggleState: function () {
        return this.state = !this.state;
      },

      isFocusField: function (field) {
        return this.focusField === field;
      }
    }
  };

  return EditableFieldsState;
};
