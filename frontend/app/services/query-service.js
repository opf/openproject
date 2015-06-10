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

/* jshint camelcase: false */

module.exports = function(
    Query,
    Sortation,
    $http,
    PathHelper,
    $q,
    AVAILABLE_WORK_PACKAGE_FILTERS,
    StatusService,
    TypeService,
    PriorityService,
    UserService,
    VersionService,
    CategoryService,
    RoleService,
    GroupService,
    ProjectService,
    WorkPackagesTableHelper,
    I18n,
    queryMenuItemFactory,
    $rootScope,
    QUERY_MENU_ITEM_TYPE
  ) {

  var query;

  var availableColumns = [],
      availableUnusedColumns = [],
      availableFilterValues = {},
      availableFilters = {},
      availableGroupedQueries;

  var totalEntries;

  var QueryService = {
    initQuery: function(queryId, queryData, selectedColumns, exportFormats, afterQuerySetupCallback) {
      query = new Query({
        id: queryId,
        name: queryData.name,
        project_id: queryData.project_id,
        displaySums: queryData.display_sums,
        groupSums: queryData.group_sums,
        sums: queryData.sums,
        columns: selectedColumns,
        groupBy: queryData.group_by,
        isPublic: queryData.is_public,
        exportFormats: exportFormats,
        starred: queryData.starred,
        links: queryData._links
      });
      query.setSortation(queryData.sort_criteria);

      QueryService.getAvailableFilters(query.project_id)
        .then(function(availableFilters) {
          query.setAvailableWorkPackageFilters(availableFilters);
          if (query.isDefault()) {
            query.setDefaultFilter();
          }
          if(queryData.filters && queryData.filters.length) {
            query.setFilters(queryData.filters);
          }

          return query;
        })
        .then(afterQuerySetupCallback);

      return query;
    },

    updateQuery: function(values, afterUpdate) {
      var queryData = {
      };
      if(!!values.display_sums) {
        queryData.displaySums = values.display_sums;
      }
      if(!!values.columns) {
        queryData.columns = values.columns;
      }
      if(!!values.group_by) {
        queryData.groupBy = values.group_by;
      }
      if(!!values.sort_criteria) {
        queryData.sortCriteria = values.sort_criteria;
      }
      query.update(queryData);

      QueryService.getAvailableFilters(query.project_id)
        .then(function(availableFilters) {
          query.setAvailableWorkPackageFilters(availableFilters);
          if(queryData.filters && queryData.filters.length) {
            query.setFilters(queryData.filters);
          }

          return query;
        })
        .then(afterUpdate);

      return query;
    },

    getQuery: function() {
      return query;
    },

    clearQuery: function() {
      query = null;
    },

    getQueryName: function() {
      if (query && query.hasName()) {
        return query.name;
      }
    },

    setTotalEntries: function(numberOfEntries) {
      totalEntries = numberOfEntries;
    },

    getTotalEntries: function() {
      return totalEntries;
    },

    getAvailableUnusedColumns: function() {
      return availableUnusedColumns;
    },

    hideColumns: function(columnNames) {
      WorkPackagesTableHelper.moveColumns(columnNames, this.getSelectedColumns(), availableUnusedColumns);
    },

    showColumns: function(columnNames) {
      WorkPackagesTableHelper.moveColumns(columnNames, availableUnusedColumns, this.getSelectedColumns());
    },

    getAvailableGroupedQueries: function() {
      return availableGroupedQueries;
    },

    // data loading

    loadAvailableGroupedQueries: function(projectIdentifier) {
      if (availableGroupedQueries) {
        return $q.when(availableGroupedQueries);
      }

      return QueryService.fetchAvailableGroupedQueries(projectIdentifier);
    },

    fetchAvailableGroupedQueries: function(projectIdentifier) {
      var url = projectIdentifier ? PathHelper.apiProjectGroupedQueriesPath(projectIdentifier) : PathHelper.apiGroupedQueriesPath();

      return QueryService.doQuery(url)
        .then(function(groupedQueriesResults) {
          availableGroupedQueries = groupedQueriesResults;
          return availableGroupedQueries;
        });
    },

    loadAvailableUnusedColumns: function(projectIdentifier) {
      return QueryService.loadAvailableColumns(projectIdentifier)
        .then(function(availableColumns) {
          availableUnusedColumns = QueryService.selectUnusedColumns(availableColumns);
          return availableUnusedColumns;
        });
    },

    selectUnusedColumns: function(columns) {
      return WorkPackagesTableHelper.getColumnDifference(
        columns, QueryService.getSelectedColumns());
    },

    loadAvailableColumns: function(projectIdentifier) {
      // TODO: Once we have a single page app we need to differentiate between different project columns
      if(availableColumns.length) {
        return $q.when(availableColumns);
      }

      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doGet(url, function(response){
        availableColumns = response.data.available_columns;
        return availableColumns;
      });
    },

    getGroupBy: function() {
      return query.groupBy;
    },

    setGroupBy: function(groupBy) {
      query.setGroupBy(groupBy);
      query.dirty = true;
    },

    getSelectedColumns: function() {
      return this.getQuery().getSelectedColumns();
    },

    setSelectedColumns: function(selectedColumnNames) {
      query.dirty = true;
      var currentColumns = this.getSelectedColumns();

      this.hideColumns(currentColumns.map(function(column) { return column.name; }));
      this.showColumns(selectedColumnNames);
    },

    updateSortElements: function(sortation) {
      return query.updateSortElements(sortation);
    },

    getSortation: function() {
      return query.getSortation();
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
            });
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
                retrieveAvailableValues = VersionService.getVersions(projectIdentifier);
                break;
              case 'category':
                retrieveAvailableValues = CategoryService.getCategories(projectIdentifier);
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

    // synchronization

    saveQuery: function() {
      var url = query.project_id ? PathHelper.apiProjectQueryPath(query.project_id, query.id) : PathHelper.apiQueryPath(query.id);

      return QueryService.doQuery(url, query.toUpdateParams(), 'PUT', function(response) {
        query.dirty = false;
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_update') }} );
      });
    },

    saveQueryAs: function(name) {
      query.setName(name);
      var url = query.project_id ? PathHelper.apiProjectQueriesPath(query.project_id) : PathHelper.apiQueriesPath();

      return QueryService.doQuery(url, query.toParams(), 'POST', function(response){
        query.save(response.data.query);
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        // The starred-state does not get saved via the API. So we manually
        // set it, if the old query was starred.
        if (query.starred) {
          QueryService.starQuery();
        }

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_create') }} );
      });
    },

    deleteQuery: function() {
      var url;
      if(_.isNull(query.project_id)) {
        url = PathHelper.apiQueryPath(query.id);
      } else {
        url = PathHelper.apiProjectQueryPath(query.project_id, query.id);
      }
      return QueryService.doQuery(url, query.toUpdateParams(), 'DELETE', function(response){
        QueryService.fetchAvailableGroupedQueries(query.project_id);

        $rootScope.$broadcast('openproject.layout.removeMenuItem', {
          itemType: QUERY_MENU_ITEM_TYPE,
          objectId: query.id
        });
        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_delete') }} );
      });
    },

    getQueryPath: function(query) {
      if (query.project_id) {
        return PathHelper.projectPath(query.project_id) + PathHelper.workPackagesPath() + '?query_id=' + query.id;
      } else {
        return PathHelper.workPackagesPath() + '?query_id=' + query.id;
      }
    },

    addOrRemoveMenuItem: function(query) {
      if (!query) return;
      if(query.starred) {
        queryMenuItemFactory
          .generateMenuItem(query.name, QueryService.getQueryPath(query), query.id)
          .then(function() {
            $rootScope.$broadcast('openproject.layout.activateMenuItem', {
              itemType: QUERY_MENU_ITEM_TYPE,
              objectId: query.id
            });
          });

      } else {
        $rootScope.$broadcast('openproject.layout.removeMenuItem', {
          itemType: QUERY_MENU_ITEM_TYPE,
          objectId: query.id
        });
      }
    },

    toggleQueryStarred: function(query) {
      if(query.starred) {
        return QueryService.unstarQuery();
      } else {
        return QueryService.starQuery();
      }
    },

    starQuery: function() {
      var url = PathHelper.apiQueryStarPath(query.id);
      var theQuery = query;

      var success = function(response){
        theQuery.star();
        QueryService.addOrRemoveMenuItem(theQuery);
        return response.data;
      };

      var failure = function(response){
        var msg = undefined;

        if(response.data.errors) {
          msg = response.data.errors.join(", ");
        }

        return QueryService.failure(msg)(response);
      };

      return QueryService.doPatch(url, success, failure);
    },

    unstarQuery: function() {
      var url = PathHelper.apiQueryUnstarPath(query.id);
      var theQuery = query;

      return QueryService.doPatch(url, function(response){
        theQuery.unstar();
        QueryService.addOrRemoveMenuItem(theQuery);
        return response.data;
      });
    },

    updateHighlightName: function() {
      // TODO Implement an API endpoint for updating the names or add an appropriate endpoint that returns query names for all highlighted queries
      return this.unstarQuery().then(this.starQuery);
    },

    doGet: function(url, success, failure) {
      return QueryService.doQuery(url, null, 'GET', success, failure);
    },

    doPatch: function(url, success, failure) {
      return QueryService.doQuery(url, null, 'PATCH', success, failure);
    },

    doQuery: function(url, params, method, success, failure) {
      method = method || 'GET';
      success = success || function(response){
        return response.data;
      };
      failure = failure || QueryService.failure();

      return $http({
        method: method,
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(success, failure);
    },

    failure: function(msg){
      msg = msg || I18n.t('js.notice_bad_request');
      return function(response){
        return angular.extend(response, { status: { text: msg, isError: true }} );
      };
    }
  };

  return QueryService;
};
