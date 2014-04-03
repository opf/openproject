//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', '$q', 'AVAILABLE_WORK_PACKAGE_FILTERS', 'StatusService', 'TypeService', 'PriorityService', 'UserService', 'VersionService', 'RoleService', 'GroupService', function($http, PathHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService, VersionService, RoleService, GroupService) {

  var availableColumns = [], availableFilterValues = {};

  var QueryService = {
    getAvailableColumns: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doQuery(url);
    },

    getAvailableFilterValues: function(filterName, projectIdentifier) {
      var modelName = AVAILABLE_WORK_PACKAGE_FILTERS[filterName].modelName;

      if(availableFilterValues[modelName]) {
        return $q.when(availableFilterValues[modelName]);
      } else {
        var retrieveAvailableValues;

        switch(modelName) {
          case 'status':
            retrieveAvailableValues = StatusService.getStatuses(projectIdentifier);
            break;
          case 'type':
            retrieveAvailableValues = TypeService.getTypes(projectIdentifier);
            break;
          case 'priority':
            retrieveAvailableValues = PriorityService.getPriorities(projectIdentifier);
            break;
          case 'user':
            retrieveAvailableValues = UserService.getUsers(projectIdentifier);
            break;
          case 'version':
            retrieveAvailableValues = VersionService.getProjectVersions(projectIdentifier);
            break;
          case 'role':
            retrieveAvailableValues = RoleService.getRoles();
            break;
          case 'group':
            retrieveAvailableValues = GroupService.getGroups();
            break;
        }

        return retrieveAvailableValues.then(function(values) {
          return QueryService.storeAvailableFilterValues(modelName, values);
        });
      }
    },

    storeAvailableFilterValues: function(modelName, values) {
      availableFilterValues[modelName] = values;
      return values;
    },

    doQuery: function(url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(function(response){
        return response.data;
      });
    }
  };

  return QueryService;
}]);
