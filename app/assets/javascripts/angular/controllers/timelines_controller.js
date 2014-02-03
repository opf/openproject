openprojectApp.controller('TimelinesController', ['$scope', 'Timeline', function($scope, Timeline) {
  // Setup

  // Get server-side stuff into scope
  $scope.timelineOptions = gon.timeline_options;

  // Count timeline containers
  $scope.timelineContainerCount = 0;
}]);
