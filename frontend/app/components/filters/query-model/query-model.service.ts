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

import {filtersModule} from '../../../angular-modules';

function QueryModelService(
  Filter:any,
  Sortation:any,
  UrlParamsHelper:any,
  PathHelper:any,
  INITIALLY_SELECTED_COLUMNS:any) {
  var Query = function (this:any, queryData:any, options:any) {
    angular.extend(this, queryData, options);

    this.filters = [];
    this.groupBy = this.groupBy || '';
    this.hasError = false;

    if(queryData.filters){
      if(options && options.rawFilters) {
        this.setRawFilters(queryData.filters);
      } else {
        this.setFilters(queryData.filters);
      }
    }

    if(queryData.sortCriteria) this.setSortation(queryData.sortCriteria);

    if(!this.columns) {
      this.setColumns(INITIALLY_SELECTED_COLUMNS);
    }
  };

  Query.prototype = {
    /**
     * @name toParams
     * @function
     *
     * @description Serializes the query to parameters required by the backend
     * @returns {Object} Request parameters
     */
    toParams: function(this:any) {
      return angular.extend.apply(this, [
        {
          'f[]': this.getFilterNames(this.getActiveConfiguredFilters()),
          'c[]': this.getParamColumns(),
          'groupBy': this.groupBy,
          'sort': this.getEncodedSortation(),
          'displaySums': this.displaySums,
          'name': this.name,
          'isPublic': this.isPublic,
          'accept_empty_query_fields': this.isDirty(),
        }].concat(this.getActiveConfiguredFilters().map(function(filter:any) {
          return filter.toParams();
        }))
      );
    },

    toUpdateParams: function(this:any) {
      return angular.extend.apply(this, [
        {
          'id': this.id,
          'queryId': this.id,
          'f[]': this.getFilterNames(this.getActiveConfiguredFilters()),
          'c[]': this.getParamColumns(),
          'groupBy': this.groupBy,
          'sort': this.getEncodedSortation(),
          'displaySums': this.displaySums,
          'name': this.name,
          'isPublic': this.isPublic,
          'accept_empty_query_fields': this.isDirty()
        }].concat(this.getActiveConfiguredFilters().map(function(filter:any) {
          return filter.toParams();
        }))
      );
    },

    save: function(this:any, data:any){
      // Note: query has already been updated, only the id needs to be set
      this.id = data.id;
      this.dirty = false;
      return this;
    },

    star: function(this:any) {
      this.starred = true;
    },

    unstar: function(this:any) {
      this.starred = false;
    },

    update: function(this:any, queryData:any) {
      angular.extend(this, queryData);

      if(queryData.filters){
        this.filters = [];
        this.setRawFilters(queryData.filters);
      }
      if(queryData.sortCriteria) this.setSortation(queryData.sortCriteria);
      this.dirty = true;

      return this;
    },

    getQueryString: function(this:any){
      return UrlParamsHelper.buildQueryString(this.toParams());
    },

    getSortation: function(this:any){
      return this.sortation;
    },

    setSortation: function(this:any, sortCriteria:any){
      this.sortation = new Sortation(sortCriteria);
    },

    setGroupBy: function(this:any, groupBy:any) {
      this.groupBy = groupBy;
    },

    updateSortElements: function(this:any, sortElements:any){
      this.sortation.setSortElements(sortElements);
    },

    setName: function(this:any, name:string) {
      this.name = name;
    },

    /**
     * @name setAvailableWorkPackageFilters
     * @function
     *
     * @description
     * Sets the available filters, which hold filter data of all selectable filters.
     * This data is also used to augment filters with their type and a modelname.
     *
     * @returns {undefined}
     */
    setAvailableWorkPackageFilters: function(this:any, availableFilters:any) {
      this.availableWorkPackageFilters = availableFilters;

      if (this.projectId){
        delete this.availableWorkPackageFilters['project'];
      } else {
        delete this.availableWorkPackageFilters['subprojectId'];
      }
      // TODO RS: Need to assertain if there are any sub-projects and remove filter if not.
      // The project will have to be fetched prior to this.
    },

    /**
     * @name setFilters
     * @function
     *
     * @description
     * Aggregates the filter data with meta data from availableWorkPackageFilters.
     * Then initializes filter objects and sets the query filter reference to them.

     * @returns {undefined}
     */
    setFilters: function(this:any, filters:any) {
      if (filters){
        var self = this;

        this.filters = filters.map(function(filterData:any){
          return new Filter(self.getExtendedFilterData(filterData));
        });
      }
    },

    setRawFilters: function(this:any, filters:any) {
      this.dirty = true;
      if (filters){
        var self = this;

        this.filters = filters.map(function(filterData:any){
          return new Filter(filterData);
        });
      }
    },

    setColumns: function(this:any, columns:any) {
      this.columns = columns;
    },

    applyDefaultsFromFilters: function(this:any, workPackage:any) {
      angular.forEach(this.filters, function(filter) {

        // Ignore any filters except =
        if (filter.operator !== '=') {
          return;
        }

        // Select the first value
        var value = filter.values;
        if (Array.isArray(filter.values)) {
          value = filter.values[0];
        }

        // Avoid empty values
        if (!value) {
          return;
        }

        switch(filter.name) {
          case 'type':
            workPackage.setAllowedValueFor('type', PathHelper.apiV3TypePath(value));
            break;
          case 'assignee':
            workPackage.setAllowedValueFor('assignee', PathHelper.apiV3UserPath(value));
            break;
        }

      });
    },

    /**
     * @name isDefault
     * @function
     *
     * @description
     * Returns true if the query is a default query
     * @returns {boolean} default
     */
    isDefault: function(this:any) {
      return this.name === '_';
    },

    /**
     * @name isGlobal
     * @function
     *
     * @description
     * Returns true if the query is a global query, meaning a query that is not
     * scoped to a project.
     * @returns {boolean} default
     */
    isGlobal: function(this:any) {
      return !this.projectId;
    },

    /**
     * @name setFilters
     * @function
     *
     * @description
     * (Re-)sets the query filters to a single filter for status: open

     * @returns {undefined}
     */
    setDefaultFilter: function(this:any) {
      var statusOpenFilterData = this.getExtendedFilterData({name: 'status', operator: 'o'});
      this.filters = [new Filter(statusOpenFilterData)];
    },

    /**
     * @name getExtendedFilterData
     * @function
     *
     * @description
     * Extends filter data with meta data from availableWorkPackageFilters.

     * @returns {object} Extended filter data.
     */
    getExtendedFilterData: function(this:any, filterData:any) {
      return angular.extend(filterData, {
        type: this.getFilterType(filterData.name),
        modelName: this.getFilterModelName(filterData.name)
      });
    },

    getFilterNames: function(this:any, filters:any) {
      return (filters || this.filters).map(function(filter:any){
        return filter.name;
      });
    },

    getSelectedColumns: function(this:any){
      return this.columns;
    },

    getParamColumns: function(this:any){
      var selectedColumns = this.columns.map(function(column:any) {
        return column.name;
      });

      return selectedColumns;
    },

    getEncodedSortation: function(this:any) {
      return !!this.sortation ? this.sortation.encode() : null;
    },

    getColumnNames: function(this:any) {
      return this.columns.map(function(column:any) {
        return column.name;
      });
    },

    getFilterByName: function(this:any, filterName:any) {
      return this.filters.filter(function(filter:any){
        return filter.name === filterName;
      })[0];
    },

    addFilter: function(this:any, filterName:any, options:any) {
      this.dirty = true;
      var filter = this.getFilterByName(filterName);

      if (filter) {
        filter.deactivated = false;
      } else {
        var filterData = this.getExtendedFilterData(angular.extend({name: filterName}, options));
        filter = new Filter(filterData);

        this.filters.push(filter);
      }
    },

    removeFilter: function(this:any, filterName:any) {
      this.dirty = true;
      this.filters.splice(this.getFilterNames().indexOf(filterName), 1);
    },

    deactivateFilter: function(this:any, filter:any) {
      this.dirty = true;
      filter.deactivated = true;
    },

    getFilterType: function(this:any, filterName:any) {
      if (this.availableWorkPackageFilters && this.availableWorkPackageFilters[filterName]){
        return this.availableWorkPackageFilters[filterName].type;
      } else {
        return 'none';
      }
    },

    getFilterModelName: function(this:any, filterName:any) {
      if (this.availableWorkPackageFilters && this.availableWorkPackageFilters[filterName]) return this.availableWorkPackageFilters[filterName].modelName;
    },

    getActiveFilters: function(this:any) {
      return this.filters.filter(function(filter:any){
        return !filter.deactivated;
      });
    },

    getRemainingFilters: function(this:any):any {
      const activeFilters = _.keyBy(this.getActiveFilters(), function(f:any) { return f.name });

      if (!activeFilters) {
        return {};
      }

      return _.pick(this.availableWorkPackageFilters, function(filter:any, key:string) {
        return !activeFilters[key];
      });
    },

    getActiveConfiguredFilters: function(this:any) {
      return this.getActiveFilters().filter(function(filter:any){
        return filter.isConfigured();
      });
    },

    clearAll: function(this:any){
      this.groupBy = '';
      this.displaySums = false;
      this.id = null;
      this.clearFilters();
    },

    clearFilters: function(this:any){
      this.filters.map(function(filter:any){
        filter.deactivated = true;
      });
    },

    isNew: function(this:any) {
      return !this.id;
    },

    isDirty: function(this:any) {
      return this.dirty;
    },

    hasName: function(this:any) {
      return !!this.name && !this.isDefault();
    }
  };

  return Query;
}

filtersModule.factory('Query', QueryModelService);
