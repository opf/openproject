// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('progressBar', [function() {
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      progress: '=',
      width: '@',
      legend: '@'
    },
    templateUrl: '/templates/components/progress_bar.html',
    link: function(scope) {
      // apply defaults
      scope.progress = scope.progress || 0;
      scope.width = scope.width || '100px';
      scope.legend = scope.legend || '';

      scope.scaleLength = 100;
      scope.progress = Math.round(scope.progress);
    }
  };
}]);
