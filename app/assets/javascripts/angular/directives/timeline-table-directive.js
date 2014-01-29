openprojectApp.directive('timelineTable', [function() {
  return {
    restrict: 'E',
    replace: true,
    scope: true,
    templateUrl: '/templates/timelines/timeline_table.html'
  };
}]);
