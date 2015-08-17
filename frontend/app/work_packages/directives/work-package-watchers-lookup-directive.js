module.exports = function() {
  'use strict';

  var workPackageWatchersLookupController = function(scope) {
    scope.addWatcher = function() {
      if (!scope.selectedWatcher) {
        return;
      }
      // we pass up the original up the scope chain,
      // _not_ the wrapper object
      scope.$emit('watchers.add', scope.selectedWatcher.originalObject);
    }

    scope.$on('watchers.add.finished', function(_, watcher) {
      console.log(watcher);
      if (scope.selectedWatcher.id === watcher.id) {
        scope.selectedWatcher = null;
      };
    });
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
