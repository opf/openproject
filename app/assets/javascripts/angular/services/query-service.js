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

.service('QueryService', ['Query', 'Sortation', '$http', '$location', 'PathHelper', 'QueriesHelper', '$q', 'AVAILABLE_WORK_PACKAGE_FILTERS', 'StatusService', 'TypeService', 'PriorityService', 'UserService', 'VersionService', 'RoleService', 'GroupService', 'ProjectService', 'I18n',
  function(Query, Sortation, $http, $location, PathHelper, QueriesHelper, $q, AVAILABLE_WORK_PACKAGE_FILTERS, StatusService, TypeService, PriorityService, UserService, VersionService, RoleService, GroupService, ProjectService, I18n) {

  var query;

  var availableColumns = [], availableFilterValues = {}, availableFilters = {};

  var totalEntries;

  var QueryService = {
    initQuery: function(queryId, queryData, selectedColumns, afterQuerySetupCallback) {
      query = new Query({
        id: queryId,
        name: queryData.name,
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

    resetQuery: function() {
      query = null;
    },

    getQuery: function() {
      return query;
    },

    setTotalEntries: function(numberOfEntries) {
      totalEntries = numberOfEntries;
    },

    getTotalEntries: function() {
      return totalEntries;
    },

    // data loading

    getAvailableGroupedQueries: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectGroupedQueriesPath(projectIdentifier) : PathHelper.apiGroupedQueriesPath();

      return QueryService.doQuery(url);
    },

    getAvailableUnusedColumns: function(projectIdentifier) {
      return QueryService.getAvailableColumns(projectIdentifier)
        .then(function(data){
          return QueriesHelper.getAvailableColumns(data.available_columns, QueryService.getSelectedColumns());
        });
    },

    getAvailableColumns: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doQuery(url)
    },

    getSelectedColumns: function() {
      return query.getSelectedColumns();
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

    saveQuery: function() {
      var url = PathHelper.apiProjectQueryPath(query.project_id, query.id);
      return QueryService.doQuery(url, query.toUpdateParams(), 'PUT', function(response){
        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_update') }} );
      });
    },

    saveQueryAs: function(name) {
      query.setName(name);
      var url = PathHelper.apiProjectQueriesPath(query.project_id);
      return QueryService.doQuery(url, query.toParams(), 'POST', function(response){
        query.save(response.data);
        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_create') }} );
      });
    },

    doQuery: function(url, params, method, success, failure) {
      method = method || 'GET';
      success = success || function(response){
        return response.data;
      };
      failure = failure || function(response){
        return angular.extend(response.data, { status: { text: I18n.t('js.notice_bad_request'), isError: true }} );
      };

      return $http({
        method: method,
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(success, failure);
    }
  };

  return QueryService;
}]);
