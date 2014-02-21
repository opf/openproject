angular.module('openproject.workPackages.filters')

.filter('allRowsChecked', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {
  return WorkPackagesTableHelper.allRowsChecked;
}])

.filter('subtractActiveFilters', [function() {
  return function(availableFilters, selectedFilters) {
    var filters = angular.copy(availableFilters);

    angular.forEach(selectedFilters, function(filter) {
      if(!filter.deactivated) delete filters[filter.name];
    });

    return filters;
  };
}]);
