openprojectApp.controller('TimelinesController', ['$scope', 'Timeline', function($scope, Timeline) {

  getInitialOutlineExpansion = function(timelineOptions) {
    initialOutlineExpansion = timelineOptions.initial_outline_expansion;
    if (initialOutlineExpansion && initialOutlineExpansion >= 0) {
      return initialOutlineExpansion;
    } else {
      return 0;
    }
  };

  // Setup

  // Get server-side stuff into scope
  $scope.timelineOptions = gon.timeline_options;

  // Hide charts until tables are drawn
  $scope.underConstruction = true;

  // Create timeline object
  $scope.timeline = Timeline.create($scope.timelineOptions);

  // Set initial expansion index
  $scope.timeline.expansionIndex = getInitialOutlineExpansion($scope.timelineOptions);

  // Count timeline containers
  $scope.timelineContainerCount = 0;
}]);
