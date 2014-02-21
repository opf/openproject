angular.module('openproject.models')

.factory('Query', [function() {

  Query = function (data) {
    angular.extend(this, data);

    if (this.filters === undefined) this.filters = [];
  };

  Query.prototype = {
    toParams: function() {
      return {
        'c[]': this.selectedColumns.map(function(column) {
          return column.name;
         }),
        'group_by': this.group_by
      };
    },

    getFilterNames: function() {
      return this.filters.map(function(filter){
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
        this.filters.push(angular.extend({name: filterName}, options));
      }
    },

    removeFilter: function(filterName) {
      this.filters.splice(this.getFilterNames().indexOf(filterName), 1);
    },

    deactivateFilter: function(filter) {
      filter.deactivated = true;
    },

    getAvailableFilterValues: function(filterName) {
      return this.available_work_package_filters[filterName].values;
    },

    getFilterType: function(filterName) {
      return this.available_work_package_filters[filterName].type;
    },

    getActiveFilters: function() {
      this.filters.filter(function(filter){
        return !filter.deactivated;
      });
    }
  };

  return Query;
}]);
