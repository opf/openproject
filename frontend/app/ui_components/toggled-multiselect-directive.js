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

// TODO move to UI components
module.exports = function(I18n){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '=',
      values: '=',
      availableOptions: '=',
      disabled: '=isDisabled'
    },
    templateUrl: '/templates/components/toggled_multiselect.html',
    link: function(scope, element, attributes){
      scope.I18n = I18n;

      scope.toggleMultiselect = function(){
        scope.isMultiselect ? switchToSingleSelect() : switchToMultiSelect();
      };

      function switchToMultiSelect() {
        scope.isMultiselect = true;

        if (scope.values && !Array.isArray(scope.values)) {
          scope.values = [scope.values];
        }
      }

      function switchToSingleSelect() {
        scope.isMultiselect = false;

        if (Array.isArray(scope.values)) {
          scope.values = scope.values[0];
        }
      }

      scope.isSelected = function(value) {
        if (!scope.values) {
          return false;
        } else if (scope.isMultiselect) {
          return scope.values.indexOf(value) !== -1 || scope.values.indexOf(value.toString()) !== -1;
        } else {
          return scope.values.toString() === value.toString();
        }
      };

      scope.isMultiselect = (Array.isArray(scope.values) && scope.values.length > 1);
    }
  };
};
