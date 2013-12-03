timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // setup

  $scope.timelineContainerNo = 1; // formerly rand(10**75), TODO increment after each timeline startup

  $scope.timelines = gon.timelines;
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelineOptions = angular.extend(gon.timeline_options, { i18n: gon.timeline_translations });
  $scope.Timeline = Timeline;

  // $scope.timeline = TimelineService.loadTimeline($scope.timelineOptions);

  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };

  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };

  angular.element(document).ready(function() {
    // start timeline
    // $scope.timeline = TimelineService.startTimeline($scope.timelineOptions, $scope.getTimelineContainer());
    $scope.timeline = TimelineService.loadTimeline($scope.timelineOptions);
  });
}]);
