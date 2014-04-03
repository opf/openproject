// TODO move to UI components
angular.module('openproject.helpers')

.service('WorkPackageLoadingHelper', ['$timeout', function($timeout) {
  var currentRun;

  return {
    withDelay: function(delay, callback, params) {
      $timeout.cancel(currentRun);

      currentRun = $timeout(function() {
        return callback.apply(this, params);
      }, delay);

      return currentRun;
    },

    /**
     * @name withLoading
     *
     * @description Wraps a data-loading function and manages the loading state within the scope
     * @param {scope} a scope on which an isLoading flag is set
     * @param {function} callback Function returning a promise
     * @param {array} params Params forwarded to the callback
     * @returns {promise} Promise returned by the callback
     */
    withLoading: function(scope, callback, params, errorCallback) {
      scope.isLoading = true;

      return callback.apply(this, params)
        .then(function(results){
          scope.isLoading = false;

          return results;
        }, errorCallback);
    }
  };
}]);
