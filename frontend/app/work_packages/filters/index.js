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

angular.module('openproject.workPackages.filters')

.filter('allRowsChecked', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {
  return WorkPackagesTableHelper.allRowsChecked;
}])

/**
 * filter
 * @name remainingFilterNames
 * @function
 *
 * @description
 * Gets a hash of available filters and selected filters and calculates the difference.
 * Returns the keys of those filters that haven't been selected sorted by the localised
 * filter names.
 *
 * @param {Object} availableFilters The set of available filters, stored with their
 *    filter name.
 * @param {Array} selectedFilters An array with the selected filters.
 *
 * @returns {Array} An array of the filter names of those available filters that haven't
 *    been selected, ordered by the corresponding filters localised names.
*/
.filter('remainingFilterNames', ['orderByFilter', 'FiltersHelper', function(orderByFilter, FiltersHelper) {

  function subtractActiveFilters(filters, filtersToSubtract) {
    var filterDiff = _.clone(filters);

    angular.forEach(filtersToSubtract, function(filter) {
      if(!filter.deactivated) delete filterDiff[filter.name];
    });

    return filterDiff;
  }

  function flattenFiltersHash(filtersHash) {
    var flattenedHash = [];
    angular.forEach(filtersHash, function(filterValues, filterName) {
      flattenedHash.push(angular.extend({filterName: filterName}, filterValues));
    });

    return flattenedHash;
  }

  return function(availableFilters, selectedFilters) {
    if(!availableFilters) return [];

    var filters = subtractActiveFilters(availableFilters, selectedFilters);

    return orderByFilter(flattenFiltersHash(filters), FiltersHelper.localisedFilterName).map(function(filter) {
      return filter.filterName;
    });
  };
}]);
