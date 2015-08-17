module.exports = function() {
  'use strict';

  var workPackageWatchersLookupController = function(scope) {
    scope.locked = false;
    scope.addWatcher = function() {
      if (!scope.selectedWatcher) {
        return;
      }

      scope.locked = !scope.locked;

      // we pass up the original up the scope chain,
      // _not_ the wrapper object
      scope.$emit('watchers.add', scope.selectedWatcher.originalObject);
    };

    scope.$on('watchers.add.finished', function() {
      scope.locked = !scope.locked;

      // to clear the input of the directive
      scope.$broadcast('angucomplete-alt:clearInput');

      scope.selectedWatcher = null;

      //set the focus back to allow for next watcher
      angular.element('#watchers-lookup_value').focus();
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
