timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // Setup
  $scope.slider = null;
  $scope.timelineContainerNo = 1;
  $scope.currentOutlineLevel = 'level3';
  $scope.currentScale = 'monthly';

  // Get server-side stuff into scope
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelines = gon.timelines;
  $scope.timelineOptions = angular.extend(gon.timeline_options, { i18n: gon.timeline_translations });

  // Get timelines stuff into scope
  $scope.Timeline = Timeline;


  // Container for timeline rendering
  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };
  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };

  // Load timeline
  $scope.timeline = TimelineService.createTimeline($scope.timelineOptions);
  // $scope.timeline.load($scope.timelineOptions);

  angular.element(document).ready(function() {
    // start timeline
    // $scope.timeline.draw($scope.getTimelineContainer());
    $scope.timeline = TimelineService.startTimeline($scope.timelineOptions, $scope.getTimelineContainer());

  });
}]);
