angular.module('openproject.uiComponents')

.directive('modal', [function() {
  return {
    restrict: 'A',
    scope: {
      target: '='
    },
    link: function(scope, element, attributes) {
      element.on('click', function(e){
        e.preventDefault();

        modalHelperInstance.createModal(scope.target || attributes['href'], function (modalDiv) {});
      });
    }
  };
}]);
