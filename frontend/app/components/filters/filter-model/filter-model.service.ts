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

function filterModel(
  OPERATORS_NOT_REQUIRING_VALUES:any,
  MULTIPLE_VALUE_FILTER_OPERATORS:any,
  SELECTABLE_FILTER_TYPES:any) {
  var Filter = function (this:any, data:any) {
    angular.extend(this, data);

    // Experimental API controller will always give back strings even for numeric values so need to parse them
    if (this.isSingleInputField() && Array.isArray(this.values)) this.parseSingleValue(this.values[0]);

    this.pruneValues();
  };

  Filter.prototype = {
    /**
     * @name toParams
     * @function
     *
     * @description Serializes the filter to parameters required by the backend
     * @returns {Object} Request parameters
     */
    toParams: function (this:any) {
      var params:any = {};

      params['op[' + this.name + ']'] = this.operator;
      params['v[' + this.name + '][]'] = this.getValuesAsArray();

      return params;
    },

    isSingleInputField: function (this:any) {
      return !this.isSelectInputField() &&
             MULTIPLE_VALUE_FILTER_OPERATORS.indexOf(this.operator) === -1;
    },

    isSelectInputField: function (this:any) {
      return SELECTABLE_FILTER_TYPES.indexOf(this.type) !== -1;
    },

    parseSingleValue: function (this:any, v:any) {
      if (this.type == 'integer' || this.type == 'date') {
        if (this.operator == '=d') {
          this.dateValue = v;
        }
        else {
          this.textValue = parseInt(v);
        }
      }
      else {
        this.textValue = v;
      }
    },

    getValuesAsArray: function (this:any) {
      var result = [];
      if (this.isSingleInputField()) {
        if (this.operator == '=d') {
          result.push(this.dateValue);
        }
        else {
          result.push(this.textValue);
        }
      } else if (!Array.isArray(this.values)) {
        if (this.operator == '<>d') {
          if (this.values['0']) {
            result.push(this.values['0']);
          }
          else {
            // make sure that first value does not get pruned
            result.push('undefined');
          }
          if (this.values['1'])
          {
            result.push(this.values['1']);
          }
        }
        else {
          result.push(this.values);
        }
      } else {
        result = this.values;
      }
      return result;
    },

    requiresValues: function (this:any) {
      return OPERATORS_NOT_REQUIRING_VALUES.indexOf(this.operator) === -1;
    },

    isConfigured: function (this:any) {
      return this.operator && (this.hasValues() || !this.requiresValues());
    },

    pruneValues: function (this:any) {
      if (this.values) {
        if (this.operator == '<>d') {
          this.values = {
            '0': this.values[0] == 'undefined' ? null : this.values[0],
            '1': this.values[1]
          };
        }
        else {
          this.values = this.values.filter(function (value:any) {
            return value !== '';
          });
        }
      } else {
        this.values = [];
      }
    },

    hasValues: function (this:any) {
      if (this.isSingleInputField()) {
        if (this.operator == '=d') {
          return !!this.dateValue;
        }
        else {
          return !!this.textValue;
        }
      } else if (this.operator == '<>d') {
        return !!(this.values['0'] || this.values['1']);
      } else {
        return Array.isArray(this.values) ? this.values.length > 0 : !!this.values;
      }
    }
  };

  return Filter;
}

filtersModule.factory('Filter', filterModel);
