module.exports = function() {
  'use strict';

  var workPackageWatchersLookupController = function(scope) {
    scope.addWatcher = function() {
      scope.$emit('watchers.add', scope.watcher);
    };
  };

  return {
    replace: true,
    restrict: 'E',
    templateUrl: '/templates/work_packages/watchers/lookup.html',
    link: workPackageWatchersLookupController,
    scope: {
      watchers: '='
    }
  };
};
