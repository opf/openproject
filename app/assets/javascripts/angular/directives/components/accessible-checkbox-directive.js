// TODO move to UI components

openprojectApp.directive('accessibleCheckbox', [function(){
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
