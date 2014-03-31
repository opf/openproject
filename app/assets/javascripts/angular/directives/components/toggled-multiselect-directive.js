// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('toggledMultiselect', ['WorkPackagesHelper', function(WorkPackagesHelper){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '=',
      values: '=',
      availableOptions: '=',
    },
    templateUrl: '/templates/components/toggled_multiselect.html',
    link: function(scope, element, attributes){
      scope.toggleMultiselect = function(){
        scope.isMultiselect = !scope.isMultiselect;
      };

      scope.isSelected = function(value) {
        return scope.values instanceof Array && (scope.values.indexOf(value) !== -1 || scope.values.indexOf(value.toString()) !== -1);
      };

      scope.isMultiselect = (scope.values instanceof Array && scope.values.length > 1);
    }
  };
}]);
