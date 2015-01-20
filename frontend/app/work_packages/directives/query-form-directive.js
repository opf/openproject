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

module.exports = function() {

  return {
    restrict: 'EA',

    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showQueryOptions = false;

          function querySwitched(currentProperties, formerProperties) {
            if (formerProperties === undefined) {
              return true;
            } else {
              return formerProperties.id !== currentProperties.id;
            }
          }

          function queryPropertiesChanged(currentProperties, formerProperties) {
            if (formerProperties === undefined) return false;

            var groupByChanged = currentProperties.groupBy !== formerProperties.groupBy;
            var sortElementsChanged = JSON.stringify(currentProperties.sortElements) !== JSON.stringify(formerProperties.sortElements);

            return groupByChanged || sortElementsChanged;
          }

          function passiveQueryPropertiesChanged(currentProperties, formerProperties) {
            if (formerProperties === undefined) return false;

            var columnsChanged = JSON.stringify(currentProperties.columns) !== JSON.stringify(formerProperties.columns);
            var displaySumsChanged = currentProperties.displaySums !== formerProperties.displaySums;

            return columnsChanged || displaySumsChanged;
          }

          function observedQueryProperties() {
            var query = scope.query;

            if (query !== undefined) {
              /* Oberve a few properties to avoid a full deep watch,
                 filters are being watched within their own directive scope */
              return {
                id: query.id,
                groupBy: query.groupBy,
                sortElements: query.sortation.sortElements
              };
            }
          }

          function passiveQueryProperties() {
            var query = scope.query;

            if (query !== undefined) {
              return {
                columns: query.columns,
                displaySums: query.displaySums
              };
            }
          }

          scope.$watch(observedQueryProperties, function(newProperties, oldProperties) {
            if (!querySwitched(newProperties, oldProperties)) {
              if (queryPropertiesChanged(newProperties, oldProperties)) {
                scope.$emit('queryStateChange');
                scope.$emit('workPackagesRefreshRequired');
              }
            }
          }, true);

          scope.$watch(passiveQueryProperties, function(newProperties, oldProperties) {
            if (passiveQueryPropertiesChanged(newProperties, oldProperties)) {
              scope.$emit('queryStateChange');
            }
          }, true);
        }
      };
    }
  };
};
