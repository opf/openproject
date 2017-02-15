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

import {filtersModule} from "../../../angular-modules";
import {States} from '../../states.service';

function QueryService($rootScope:ng.IRootScopeService,
                      $http:ng.IHttpService,
                      $q:ng.IQService,
                      Query:any,
                      PathHelper:any,
                      AVAILABLE_WORK_PACKAGE_FILTERS:any,
                      StatusService:any,
                      TypeService:any,
                      PriorityService:any,
                      UserService:any,
                      VersionService:any,
                      CategoryService:any,
                      RoleService:any,
                      GroupService:any,
                      ProjectService:any,
                      states:States,
                      I18n:op.I18n,
                      queryMenuItemFactory:any,
                      QUERY_MENU_ITEM_TYPE:any
) {

  var query:any;

  var availableColumns:any = [],
      availableUnusedColumns = [],
      availableFilterValues:any = {},
      availableFilters:any = {},
      availableGroupedQueries:any;

  var totalEntries:any;

  var QueryService = {
    initQuery: function(queryId:any, queryData:any, selectedColumns:any, exportFormats:any, afterQuerySetupCallback:any) {
      query = new Query({
        id: queryId,
        name: queryData.name,
        projectId: queryData.projectId,
        displaySums: queryData.displaySums,
        groupSums: queryData.groupSums,
        sums: queryData.sums,
        columns: selectedColumns,
        groupBy: queryData.groupBy,
        isPublic: queryData.isPublic,
        exportFormats: exportFormats,
        starred: queryData.starred,
        links: queryData._links
      });
      query.setSortation(queryData.sortCriteria);

      QueryService.getAvailableFilters(query.projectId)
        .then(function(availableFilters:any) {
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

    updateQuery: function(values:any, afterUpdate:any) {
      var queryData = <any> {
      };
      if (!!values.displaySums) {
        queryData.displaySums = values.displaySums;
      }
      if (!!values.columns) {
        queryData.columns = values.columns;
      }
      if (!!values.groupBy) {
        queryData.groupBy = values.groupBy;
      }
      if (!!values.sortCriteria) {
        queryData.sortCriteria = values.sortCriteria;
      }
      query.update(queryData);

      QueryService.getAvailableFilters(query.projectId)
        .then(function(availableFilters:any) {
          query.setAvailableWorkPackageFilters(availableFilters);
          if(values.filters && values.filters.length) {
            query.setFilters(values.filters);
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

    setTotalEntries: function(numberOfEntries:number) {
      totalEntries = numberOfEntries;
    },

    getTotalEntries: function() {
      return totalEntries;
    },

    getAvailableGroupedQueries: function() {
      return availableGroupedQueries;
    },

    // data loading

    loadAvailableGroupedQueries: function(projectIdentifier:string) {
      if (availableGroupedQueries) {
        return $q.when(availableGroupedQueries);
      }

      return QueryService.fetchAvailableGroupedQueries(projectIdentifier);
    },

    fetchAvailableGroupedQueries: function(projectIdentifier:string) {
      var url = projectIdentifier ? PathHelper.apiProjectGroupedQueriesPath(projectIdentifier) : PathHelper.apiGroupedQueriesPath();

      return QueryService.doQuery(url)
        .then(function(groupedQueriesResults:any) {
          availableGroupedQueries = groupedQueriesResults;
          return availableGroupedQueries;
        });
    },

    loadAvailableUnusedColumns: function(projectIdentifier:string) {
      return QueryService.loadAvailableColumns(projectIdentifier)
        .then(function(availableColumns:any) {
          availableUnusedColumns = QueryService.selectUnusedColumns(availableColumns);
          return availableUnusedColumns;
        });
    },

    selectUnusedColumns: function(columns:api.ex.Column[]) {
      let identifiers = QueryService.getSelectedColumnNames();

      return columns.filter(function(column) {
        return identifiers.indexOf(column.name) === -1;
      });
    },

    loadAvailableColumns: function(projectIdentifier:string) {
      // TODO: Once we have a single page app we need to differentiate between different project columns
      if(availableColumns.length) {
        return $q.when(availableColumns);
      }

      var url = projectIdentifier ? PathHelper.apiProjectAvailableColumnsPath(projectIdentifier) : PathHelper.apiAvailableColumnsPath();

      return QueryService.doGet(url, (response:any) => {
        let columns = response.data.available_columns;
        states.query.availableColumns.put(columns);
        return columns;
      });
    },

    getGroupBy: function() {
      return query.groupBy;
    },

    setGroupBy: function(groupBy:string) {
      query.setGroupBy(groupBy);
      query.dirty = true;
    },

    getSelectedColumns: function(this:any) {
      return this.getQuery().getSelectedColumns();
    },

    getSelectedColumnNames: function(this:any) {
      return this.getSelectedColumns().map((column:api.ex.Column) => column.name);
    },

    setSelectedColumns: function(this:any, selectedColumnNames:string[]) {
      query.dirty = true;
      var currentColumns = this.getSelectedColumns();

      this.hideColumns(currentColumns.map(function(column:api.ex.Column) { return column.name; }));
      this.showColumns(selectedColumnNames);
    },

    updateSortElements: function(sortation:string) {
      return query.updateSortElements(sortation);
    },

    getSortation: function() {
      return query.getSortation();
    },

    getAvailableFilters: function(this:any, projectIdentifier:string){
      // TODO once this is becoming more single-page-app-like keep the available filters of the query model in sync when the project identifier is changed on the scope but the page isn't reloaded
      var identifier = 'global';
      var getFilters = <any> QueryService.getCustomFieldFilters;
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
          .then(function(data:any) {
            return QueryService.storeAvailableFilters(identifier, angular.extend(AVAILABLE_WORK_PACKAGE_FILTERS, data.custom_field_filters));
          });
      }

    },

    getProjectCustomFieldFilters: function(projectIdentifier:string) {
      return QueryService.doQuery(PathHelper.apiProjectCustomFieldsPath(projectIdentifier), {}, 'GET', null, null, true);
    },

    getCustomFieldFilters: function() {
      return QueryService.doQuery(PathHelper.apiCustomFieldsPath());
    },

    getAvailableFilterValues: function(filterName:string, projectIdentifier:string) {
      return QueryService.getAvailableFilters(projectIdentifier)
        .then(function(filters:any) {
          var filter = filters[filterName];
          var modelName = filter.modelName;

          if(filter.values) {
            // Note: We have filter values already because it is a custom field and the server gives the possible values.
            var values = filter.values.map(function(value:any) {
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

            return retrieveAvailableValues.then(function(values:any) {
              return QueryService.storeAvailableFilterValues(modelName, values);
            });
          }
        });

    },

    storeAvailableFilterValues: function(modelName:string, values:any) {
      availableFilterValues[modelName] = values;
      return values;
    },

    storeAvailableFilters: function(projectIdentifier:string, filters:any){
      availableFilters[projectIdentifier] = filters;
      return availableFilters[projectIdentifier];
    },

    // synchronization

    saveQuery: function() {
      var url = query.projectId ? PathHelper.apiProjectQueryPath(query.projectId, query.id) : PathHelper.apiQueryPath(query.id);

      return QueryService.doQuery(url, query.toUpdateParams(), 'PUT', function(response:any) {
        query.dirty = false;
        QueryService.fetchAvailableGroupedQueries(query.projectId);

        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_update') }} );
      });
    },

    saveQueryAs: function(name:string) {
      query.setName(name);
      var url = query.projectId ? PathHelper.apiProjectQueriesPath(query.projectId) : PathHelper.apiQueriesPath();

      return QueryService.doQuery(url, query.toParams(), 'POST', function(response:any){
        query.save(response.data.query);
        QueryService.fetchAvailableGroupedQueries(query.projectId);

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
      if(_.isNull(query.projectId)) {
        url = PathHelper.apiQueryPath(query.id);
      } else {
        url = PathHelper.apiProjectQueryPath(query.projectId, query.id);
      }
      return QueryService.doQuery(url, query.toUpdateParams(), 'DELETE', function(response:any){
        QueryService.fetchAvailableGroupedQueries(query.projectId);

        $rootScope.$broadcast('openproject.layout.removeMenuItem', {
          itemType: QUERY_MENU_ITEM_TYPE,
          objectId: query.id
        });
        return angular.extend(response.data, { status: { text: I18n.t('js.notice_successful_delete') }} );
      });
    },

    getQueryPath: function(query:any) {
      if (query.projectId) {
        return PathHelper.projectWorkPackagesPath(query.projectId) + '?query_id=' + query.id;
      } else {
        return PathHelper.workPackagesPath() + '?query_id=' + query.id;
      }
    },

    addOrRemoveMenuItem: function(query:any) {
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

    toggleQueryStarred: function(query:any) {
      if(query.starred) {
        return QueryService.unstarQuery();
      } else {
        return QueryService.starQuery();
      }
    },

    starQuery: function() {
      var url = PathHelper.apiQueryStarPath(query.id);
      var theQuery = query;

      var success = function(response:any){
        theQuery.star();
        QueryService.addOrRemoveMenuItem(theQuery);
        return response.data;
      };

      var failure = function(response:any){
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

      return QueryService.doPatch(url, function(response:any){
        theQuery.unstar();
        QueryService.addOrRemoveMenuItem(theQuery);
        return response.data;
      });
    },

    updateHighlightName: function(this:any) {
      // TODO Implement an API endpoint for updating the names or add an appropriate endpoint that returns query names for all highlighted queries
      return this.unstarQuery().then(this.starQuery);
    },

    doGet: function(url:string, success:any, failure?:any) {
      return QueryService.doQuery(url, null, 'GET', success, failure);
    },

    doPatch: function(url:string, success:any, failure?:any) {
      return QueryService.doQuery(url, null, 'PATCH', success, failure);
    },

    doQuery: function(url:string, params:any = {}, method:string = 'GET', success?:any, failure?:any, cache:boolean = false) {
      success = success || function(response:any){
        return response.data;
      };
      failure = failure || QueryService.failure();

      return $http({
        method: method,
        url: url,
        params: params,
        headers: {
          'caching': { enabled: cache },
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      } as any).then(success, failure);
    },

    failure: function(msg?:string) {
      msg = msg || I18n.t('js.notice_bad_request');
      return function(response:any){
        return angular.extend(response, { status: { text: msg, isError: true }} );
      };
    }
  };

  return QueryService;
}

filtersModule.factory('QueryService', QueryService);
