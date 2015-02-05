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

module.exports = function() {

  var activeScopes = [];

  var OverviewTabInplaceEditorConfig = {

    isBusy: false,

    registerActiveEditorScope: function($scope) {
      activeScopes.push($scope);
    },

    deregisterActiveEditorScope: function($scope) {
      _.remove(activeScopes, function(scope) {
        return scope === $scope;
      });
    },

    collectChanges: function(data) {
      _.forEach(activeScopes, function(scope) {
        scope.collectChanges(data);
        scope.isBusy = true;
      });
      return data;
    },

    dispatchErrors: function(e) {
      _.forEach(activeScopes, function(scope) {
        scope.isBusy = false;
        scope.acceptErrors(e);
      });
    },

    dispatchChanges: function(workPackage) {
      _.forEach(activeScopes, function(scope) {
        scope.isBusy = false;
        scope.acceptChanges(workPackage);
      });
    },

    getInplaceProperties: function() {
      return {
        assignee: {
          type: 'select2',
          attribute: 'assignee',
          embedded: false,
          placeholder: '-',
          displayStrategy: 'user',
        },
        responsible: {
          type: 'select2',
          attribute: 'responsible',
          embedded: false,
          placeholder: '-',
          displayStrategy: 'user'
        },
        status: {
          type: 'select2',
          attribute: 'status.name',
          embedded: true,
          placeholder: '-'
        },
        versionName: {
          type: 'select2',
          attribute: 'version.name',
          embedded: true,
          placeholder: '-',
          displayStrategy: 'version',
          attributeTitle: I18n.t('js.work_packages.properties.version')
        }
      };
    }
  };

  return OverviewTabInplaceEditorConfig;
};
