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

module.exports = function(Filter, Sortation, UrlParamsHelper, INITIALLY_SELECTED_COLUMNS) {

  var Query = function (queryData, options) {
    angular.extend(this, queryData, options);

    this.filters = [];
    this.groupBy = this.groupBy || '';

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
    toParams: function() {
      return angular.extend.apply(this, [
        {
          'f[]': this.getFilterNames(this.getActiveConfiguredFilters()),
          'c[]': this.getParamColumns(),
          'group_by': this.groupBy,
          'sort': this.getEncodedSortation(),
          'display_sums': this.displaySums,
          'name': this.name,
          'is_public': this.isPublic,
          'accept_empty_query_fields': this.isDirty(),
        }].concat(this.getActiveConfiguredFilters().map(function(filter) {
          return filter.toParams();
        }))
      );
    },

    toUpdateParams: function() {
      return angular.extend.apply(this, [
        {
          'id': this.id,
          'query_id': this.id,
          'f[]': this.getFilterNames(this.getActiveConfiguredFilters()),
          'c[]': this.getParamColumns(),
          'group_by': this.groupBy,
          'sort': this.getEncodedSortation(),
          'display_sums': this.displaySums,
          'name': this.name,
          'is_public': this.isPublic,
          'accept_empty_query_fields': this.isDirty()
        }].concat(this.getActiveConfiguredFilters().map(function(filter) {
          return filter.toParams();
        }))
      );
    },

    save: function(data){
      // Note: query has already been updated, only the id needs to be set
      this.id = data.id;
      this.dirty = false;
      return this;
    },

    star: function() {
      this.starred = true;
    },

    unstar: function() {
      this.starred = false;
    },

    update: function(queryData) {
      angular.extend(this, queryData);

      if(queryData.filters){
        this.filters = [];
        this.setRawFilters(queryData.filters);
      }
      if(queryData.sortCriteria) this.setSortation(queryData.sortCriteria);
      this.dirty = true;

      return this;
    },

    getQueryString: function(){
      return UrlParamsHelper.buildQueryString(this.toParams());
    },

    getSortation: function(){
      return this.sortation;
    },

    setSortation: function(sortCriteria){
      this.sortation = new Sortation(sortCriteria);
    },

    setGroupBy: function(groupBy) {
      this.groupBy = groupBy;
    },

    updateSortElements: function(sortElements){
      this.sortation.setSortElements(sortElements);
    },

    setName: function(name) {
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
    setAvailableWorkPackageFilters: function(availableFilters) {
      this.availableWorkPackageFilters = availableFilters;

      if (this.project_id){
        delete this.availableWorkPackageFilters["project_id"];
      } else {
        delete this.availableWorkPackageFilters["subproject_id"];
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
    setFilters: function(filters) {
      if (filters){
        var self = this;

        this.filters = filters.map(function(filterData){
          return new Filter(self.getExtendedFilterData(filterData));
        });
      }
    },

    setRawFilters: function(filters) {
      this.dirty = true;
      if (filters){
        var self = this;

        this.filters = filters.map(function(filterData){
          return new Filter(filterData);
        });
      }
    },

    setColumns: function(columns) {
      this.columns = columns;
    },

    /**
     * @name isDefault
     * @function
     *
     * @description
     * Returns true if the query is a default query
     * @returns {boolean} default
     */
    isDefault: function() {
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
    isGlobal: function() {
      return !this.project_id;
    },

    /**
     * @name setFilters
     * @function
     *
     * @description
     * (Re-)sets the query filters to a single filter for status: open

     * @returns {undefined}
     */
    setDefaultFilter: function() {
      var statusOpenFilterData = this.getExtendedFilterData({name: 'status_id', operator: 'o'});
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
    getExtendedFilterData: function(filterData) {
      return angular.extend(filterData, {
        type: this.getFilterType(filterData.name),
        modelName: this.getFilterModelName(filterData.name)
      });
    },

    getFilterNames: function(filters) {
      return (filters || this.filters).map(function(filter){
        return filter.name;
      });
    },

    getSelectedColumns: function(){
      return this.columns;
    },

    getParamColumns: function(){
      var selectedColumns = this.columns.map(function(column) {
        return column.name;
      });

      return selectedColumns;
    },

    getEncodedSortation: function() {
      return !!this.sortation ? this.sortation.encode() : null;
    },

    getColumnNames: function() {
      return this.columns.map(function(column) {
        return column.name;
      });
    },

    getFilterByName: function(filterName) {
      return this.filters.filter(function(filter){
        return filter.name === filterName;
      })[0];
    },

    addFilter: function(filterName, options) {
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

    removeFilter: function(filterName) {
      this.dirty = true;
      this.filters.splice(this.getFilterNames().indexOf(filterName), 1);
    },

    deactivateFilter: function(filter) {
      this.dirty = true;
      filter.deactivated = true;
    },

    getFilterType: function(filterName) {
      if (this.availableWorkPackageFilters && this.availableWorkPackageFilters[filterName]){
        return this.availableWorkPackageFilters[filterName].type;
      } else {
        return 'none';
      }
    },

    getFilterModelName: function(filterName) {
      if (this.availableWorkPackageFilters && this.availableWorkPackageFilters[filterName]) return this.availableWorkPackageFilters[filterName].modelName;
    },

    getActiveFilters: function() {
      return this.filters.filter(function(filter){
        return !filter.deactivated;
      });
    },

    getActiveConfiguredFilters: function() {
      return this.getActiveFilters().filter(function(filter){
        return filter.isConfigured();
      });
    },

    clearAll: function(){
      this.groupBy = '';
      this.displaySums = false;
      this.id = null;
      this.clearFilters();
    },

    clearFilters: function(){
      this.filters.map(function(filter){
        filter.deactivated = true;
      });
    },

    isNew: function() {
      return !this.id;
    },

    isDirty: function() {
      return this.dirty;
    },

    hasName: function() {
      return !!this.name && !this.isDefault();
    },

  };

  return Query;
};
