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

.service('QueryService', ['Query', 'Sortation', '$http', '$location', 'PathHelper', '$q', 'AVAILABLE_WORK_PACKAGE_FILTERS', 'StatusService', 'TypeService', 'PriorityService', 'UserService', 'VersionService', 'RoleService', 'GroupService', 'ProjectService',
  function(Query, Sortation, $http, $location, PathHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService, VersionService, RoleService, GroupService, ProjectService) {

  var query;

  var availableColumns = [], availableFilterValues = {}, availableFilters = {};

  var QueryService = {
    initQuery: function(queryId, queryData, selectedColumns, afterQuerySetupCallback) {
      query = new Query({
        id: queryId,
        project_id: queryData.project_id,
        displaySums: queryData.display_sums,
        groupSums: queryData.group_sums,
        sums: queryData.sums,
        columns: selectedColumns,
        groupBy: queryData.group_by
      });
      query.setSortation(new Sortation(queryData.sort_criteria));

      QueryService.getAvailableFilters(query.project_id)
        .then(function(availableFilters) {
          query.setAvailableWorkPackageFilters(availableFilters);
          query.setFilters(queryData.filters);

          return query;
        })
        .then(afterQuerySetupCallback);

      return query;
    },

    getQuery: function() {
      return query;
    },

    // data loading

    getAvailableColumns: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doQuery(url);
    },

    getAvailableFilters: function(projectIdentifier){
      // TODO once this is becoming more single-page-app-like keep the available filters of the query model in sync when the project identifier is changed on the scope but the page isn't reloaded
      var identifier = 'global';
      var getFilters = QueryService.getCustomFieldFilters;
      var getFiltersArgs = [];
      if(projectIdentifier){
        identifier = projectIdentifier;
        getFilters = QueryService.getProjectCustomFieldFilters;
        getFiltersArgs.push(identifier);
      }
      if(availableFilters[identifier]){
        return $q.when(availableFilters[identifier]);
      } else {
        return getFilters.apply(this, getFiltersArgs)
          .then(function(data){
            return QueryService.storeAvailableFilters(identifier, angular.extend(AVAILABLE_WORK_PACKAGE_FILTERS, data.custom_field_filters));
          });
      }

    },

    getProjectCustomFieldFilters: function(projectIdentifier) {
      return QueryService.doQuery(PathHelper.apiProjectCustomFieldsPath(projectIdentifier));
    },

    getCustomFieldFilters: function() {
      return QueryService.doQuery(PathHelper.apiCustomFieldsPath());
    },

    getAvailableFilterValues: function(filterName, projectIdentifier) {
      return QueryService.getAvailableFilters(projectIdentifier)
        .then(function(filters){
          var filter = filters[filterName];
          var modelName = filter.modelName;

          if(filter.values) {
            // Note: We have filter values already because it is a custom field and the server gives the possible values.
            var values = filter.values.map(function(value){
              if(Array.isArray(value)){
                return { id: value[1], name: value[0] };
              } else {
                return { id: value, name: value };
              }
            })
            return $q.when(QueryService.storeAvailableFilterValues(modelName, values));
          }

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
              case 'project':
                retrieveAvailableValues = ProjectService.getProjects();
                break;
              case 'sub_project':
                retrieveAvailableValues = ProjectService.getSubProjects(projectIdentifier);
                break;
            }

            return retrieveAvailableValues.then(function(values) {
              return QueryService.storeAvailableFilterValues(modelName, values);
            });
          }
        });

    },

    storeAvailableFilterValues: function(modelName, values) {
      availableFilterValues[modelName] = values;
      return values;
    },

    storeAvailableFilters: function(projectIdentifier, filters){
      availableFilters[projectIdentifier] = filters;
      return availableFilters[projectIdentifier];
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
