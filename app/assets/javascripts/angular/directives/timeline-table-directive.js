openprojectApp.directive('timelineTable', [function() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/timeline_table.html',
    scope: true,
    link: function(scope, element, attributes) {
      scope.columns = scope.timeline.options.columns;
      scope.height = scope.timeline.decoHeight();
      scope.excludeEmpty = scope.timeline.options.exclude_empty === 'yes';
      scope.isGrouping = scope.timeline.isGrouping();
      scope.hideTreeRoot = scope.isGrouping || scope.timeline.options.hide_tree_root;
    }
  };
}]);
