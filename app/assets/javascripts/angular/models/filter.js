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

.constant('OPERATORS_REQUIRING_VALUES', ['o', 'c', '!*', '*', 't', 'w'])
.factory('Filter', ['OPERATORS_REQUIRING_VALUES', 'AVAILABLE_WORK_PACKAGE_FILTERS', function(OPERATORS_REQUIRING_VALUES, AVAILABLE_WORK_PACKAGE_FILTERS) {
  Filter = function (data) {
    angular.extend(this, data);
    this.pruneValues();
  };

  Filter.prototype = {
    toParams: function() {
      var params = {};

      params['op[' + this.name + ']'] = this.operator;
      params['v[' + this.name + '][]'] = this.valuesAsArray();

      return params;
    },

    valuesAsArray: function() {
      if (Array.isArray(this.values)) {
        if (this.values.length === 0) return ['']; // Workaround: The array must not be empty for backend compatibility so that the values are passed as a URL param at all even if `this` is the only query filter
        // TODO fix this on the backend side, so that filters can be initialized on a query without providing values

        return this.values;
      } else {
        return [this.values];
      }
    },

    requiresValues: function() {
      return OPERATORS_REQUIRING_VALUES.indexOf(this.operator) === -1;
    },

    isConfigured: function() {
      return this.operator && (this.hasValues() || !this.requiresValues());
    },

    getModelName: function() {
      return AVAILABLE_WORK_PACKAGE_FILTERS[this.name].modelName;
    },

    pruneValues: function() {
      if (this.values) {
        this.values = this.values.filter(function(value) {
          return value !== '';
        });
      }
    },

    hasValues: function() {
      return Array.isArray(this.values) ? this.values.length > 0 : !!this.values;
    }
  };

  return Filter;
}]);
