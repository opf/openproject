angular.module('openproject.models')

.factory('Filter', [function() {
  Filter = function (data) {
    angular.extend(this, data);
  };

  Filter.prototype = {
    requiresValues: function() {
      return ['o', 'c', '!*', '*', 't', 'w'].indexOf(this.operator) === -1;
    },

    isConfigured: function() {
      return this.operator &&
    }
  };

  return Filter;
}]);
