angular.module('openproject.models')

.factory('Filter', [function() {
  Filter = function (data) {
    angular.extend(this, data);
  };

  Filter.prototype = {
    toParams: function() {
      var params = {};

      params['op[' + this.name + ']'] = this.operator;
      params['v[' + this.name + '][]'] = this.valuesAsArray();

      return params;
    },

    valuesAsArray: function() {
      if (typeof(this.values) === Array) {
        return this.values;
      } else {
        return [this.values];
      }
    },

    requiresValues: function() {
      return ['o', 'c', '!*', '*', 't', 'w'].indexOf(this.operator) === -1;
    },

    isConfigured: function() {
      return this.operator && (this.values || !this.requiresValues());
    }
  };

  return Filter;
}]);
