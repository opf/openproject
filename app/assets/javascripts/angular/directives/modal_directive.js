uiComponentsApp.directive('modal', [function() {
  return {
    restrict: 'A',
    scope: {
      target: '='
    },
    link: function(scope, element, attributes) {
      element.on('click', function(e){
        modalHelperInstance.createModal(scope.target, function (modalDiv) {});
      });
    }
  };
}]);
