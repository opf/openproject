// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('accessibleCheckbox', [function(){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '@',
      checkboxId: '@',
      checkboxTitle: '@',
      checkboxValue: '=',
      model: '='
    },
    templateUrl: '/templates/components/accessible_checkbox.html'
  };
}]);
