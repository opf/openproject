// TODO move to UI components

openprojectApp.directive('accessibleCheckbox', [function(){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      checkboxId: '@',
      checkboxTitle: '@',
      model: '='
    },
    templateUrl: '/templates/components/accessible_checkbox.html'
  };
}]);
