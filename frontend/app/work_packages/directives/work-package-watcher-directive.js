module.exports = function() {
  'use strict';

  var workPackageWatcherController = function(scope) {
    scope.remove = function() {
      scope.deleting = true;
      scope.$emit('watchers.remove', scope.watcher);
    };
  };

  return {
    replace: true,
    templateUrl: '/templates/work_packages/watchers/watcher.html',
    link: workPackageWatcherController,
    scope: {
      watcher: '='
    }
  };
};
