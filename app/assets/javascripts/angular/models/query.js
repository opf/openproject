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

angular.module('openproject.models')

.factory('Query', ['Filter', 'Sortation', function(Filter, Sortation) {

  Query = function (queryData, options) {
    angular.extend(this, queryData, options);

    this.filters = [];
    this.groupBy = this.groupBy || '';

    if(queryData) this.setFilters(queryData.filters);
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
          'sort': this.sortation.encode(),
          'display_sums': this.displaySums
        }].concat(this.getActiveConfiguredFilters().map(function(filter) {
          return filter.toParams();
        }))
      );
    },

    serialiseForAngular: function(){
      var params = this.toParams();
      var serialised = '';
      angular.forEach(params, function(value, key){
        if(typeof value == "string" || typeof value == "boolean"){
          serialised = serialised + "&" + key + "=" + encodeURIComponent(value);
        } else if(Array.isArray(value)){
          angular.forEach(value, function(v){
            serialised = serialised + "&" + key + "=" + encodeURIComponent(v);
          });
        }
      });
      return serialised.slice(1, serialised.length);
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

    getParamColumns: function(){
      var selectedColumns = this.columns.map(function(column) {
        return column.name;
      });
      // To be able to group the work packages we need to add in the group by column if it is not already in the selected columns
      if(selectedColumns.indexOf(this.groupBy) == -1){
        selectedColumns.push(this.groupBy);
      }
      return selectedColumns;
    },

    getFilterByName: function(filterName) {
      return this.filters.filter(function(filter){
        return filter.name === filterName;
      })[0];
    },

    addFilter: function(filterName, options) {
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
      this.filters.splice(this.getFilterNames().indexOf(filterName), 1);
    },

    deactivateFilter: function(filter, loading) {
      if (!loading) filter.deactivated = true;
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

    // Note: If we pass an id for the query then any changes to filters are ignored by the server and it
    //       just uses the queries filters. Therefor we have to set it to null.
    hasChanged: function(){
      this.id = null;
    },

    setSortation: function(sortation){
      this.sortation = sortation;
    }
  };

  return Query;
}]);
