angular.module('openproject.workPackages.filters')

// work packages
.filter('columnContent', ['WorkPackagesHelper', function(WorkPackagesHelper){
  return WorkPackagesHelper.getRowObjectContent;
}]);

