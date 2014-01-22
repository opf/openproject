uiComponentsApp.directive('optionColumn', [function() {
  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement, tAttrs, transclude) {
      return{
        pre: function(scope, iElement, iAttrs, controller) {
          scope.isDateOption = function(option) {
            return (option === 'start_date' || option === 'due_date');
          };
        }
      };
    }
  };
}]);
