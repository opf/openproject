uiComponentsApp.directive('modal', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      element.on('click', function(e){
        modalHelperInstance.createModal(scope.node.url, function (modalDiv) {});
      });
    }
  };
}]);
