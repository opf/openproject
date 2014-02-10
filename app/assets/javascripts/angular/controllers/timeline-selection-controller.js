angular.module('openproject.timelines.controllers')

.controller('TimelineSelectionController', ['$scope', '$window', function($scope, $window) {
  $scope.timelines = gon.timelines;
  $scope.currentTimelineId = gon.current_timeline_id;

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };
}]);
