angular.module('openproject.workPackages.filters')

.filter('allRowsChecked', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {
  return WorkPackagesTableHelper.allRowsChecked;
}])

.filter('subtractFilters', [function() {
  return function(availableFilters, selectedFilters) {
    var filters = angular.copy(availableFilters);

    angular.forEach(selectedFilters, function(filter) {
      delete filters[filter.name];
    });

    return filters;
  };
}]);
