timelinesApp = angular.module('openproject.timelines', ['ui.select2'])

// .run(function($rootScope){
// })

.controller('TimelinesController', ['$scope', '$window', function($scope, $window){
  $scope.timelines = gon.timelines;
  $scope.currentTimelineId = gon.current_timeline_id;

  $scope.loadTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };
}]);
