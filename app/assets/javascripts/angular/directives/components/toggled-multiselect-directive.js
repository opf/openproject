// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('toggledMultiselect', ['WorkPackagesHelper', function(WorkPackagesHelper){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '=',
      values: '=',
      availableFilterValues: '=',
    },
    templateUrl: '/templates/components/toggled_multiselect.html',
    link: function(scope, element, attributes){
      scope.toggleMultiselect = function(){
        scope.isMultiselect = !scope.isMultiselect;
      };

      scope.isMultiselect = (scope.values !== undefined && scope.values.length > 1);
    }
  };
}]);
