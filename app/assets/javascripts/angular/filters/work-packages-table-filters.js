angular.module('openproject.workPackages.filters')

.filter('allRowsChecked', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {
  return WorkPackagesTableHelper.allRowsChecked;
}]);
