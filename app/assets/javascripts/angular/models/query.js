angular.module('openproject.models')

.factory('Query', ['Filter', 'Sortation', function(Filter, Sortation) {

  Query = function (data, options) {
    angular.extend(this, data, options);
    this.group_by = this.group_by || '';

    if (this.filters === undefined){
      this.filters = [];
    } else {
      this.filters = this.filters.map(function(filter){
        var name = Object.keys(filter)[0];
        return new Filter(angular.extend(filter[name], { name: name }));
      });
    }
  };

  Query.prototype = {
    toParams: function() {
      return angular.extend.apply(this, [
        {
          'f[]': this.getFilterNames(this.getActiveConfiguredFilters()),
          'c[]': this.selectedColumns.map(function(column) {
            return column.name;
           }),
          'group_by': this.group_by,
          'query_id': this.id,
          'sort': this.sortation.encode()
        }].concat(this.getActiveConfiguredFilters().map(function(filter) {
          return filter.toParams();
        }))
      );
    },

    getFilterNames: function(filters) {
      return (filters || this.filters).map(function(filter){
        return filter.name;
      });
    },

    getFilterByName: function(filterName) {
      return this.filters.filter(function(filter){
        return filter.name === filterName;
      }).first();
    },

    addFilter: function(filterName, options) {
      var filter = this.getFilterByName(filterName);

      if (filter) {
        filter.deactivated = false;
      } else {
        this.filters.push(new Filter(angular.extend({name: filterName}, options)));
      }
    },

    removeFilter: function(filterName) {
      this.filters.splice(this.getFilterNames().indexOf(filterName), 1);
    },

    deactivateFilter: function(filter, loading) {
      if (!loading) filter.deactivated = true;
    },

    getAvailableFilterValues: function(filterName) {
      return this.available_work_package_filters[filterName].values;
    },

    getFilterType: function(filterName) {
      return this.available_work_package_filters[filterName].type;
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
      this.group_by = '';
      this.display_sums = false;
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
