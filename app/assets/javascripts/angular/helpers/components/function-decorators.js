// TODO move to UI components
angular.module('openproject.helpers')

.service('FunctionDecorators', ['$timeout', function($timeout) {
  var currentRun;

  return {
    withDelay: function(delay, callback, params) {
      $timeout.cancel(currentRun);

      currentRun = $timeout(function() {
        return callback.apply(this, params);
      }, delay);

      return currentRun;
    }
  };
}]);
