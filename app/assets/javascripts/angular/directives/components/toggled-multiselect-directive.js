// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('toggledMultiselect', ['WorkPackagesHelper', 'I18n', function(WorkPackagesHelper, I18n){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '=',
      values: '=',
      availableOptions: '='
    },
    templateUrl: '/templates/components/toggled_multiselect.html',
    link: function(scope, element, attributes){
      scope.I18n = I18n;

      scope.toggleMultiselect = function(){
        scope.isMultiselect = !scope.isMultiselect;
      };

      scope.isSelected = function(value) {
        return Array.isArray(scope.values) && (scope.values.indexOf(value) !== -1 || scope.values.indexOf(value.toString()) !== -1);
      };

      scope.isMultiselect = (Array.isArray(scope.values) && scope.values.length > 1);
    }
  };
}]);
