angular.module('openproject.workPackages.filters')

// work packages
.filter('columnContent', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper){
  return WorkPackagesTableHelper.getRowObjectContent;
}]);

