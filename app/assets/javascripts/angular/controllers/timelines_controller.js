timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // Setup
  $scope.timelineContainerNo = 1; // formerly rand(10**75), TODO increment after each timeline startup
  $scope.currentOutlineLevel = 'level3';
  $scope.currentScale = 'monthly';

  // Get server-side stuff into scope
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelines = gon.timelines;
  $scope.timelineOptions = angular.extend(gon.timeline_options, { i18n: gon.timeline_translations });

  // Get timelines stuff into scope
  $scope.Timeline = Timeline;

  // Load timeline
  $scope.timeline = TimelineService.loadTimeline($scope.timelineOptions);

  // Slider
  // TODO integrate angular-ui-slider
  $scope.getCurrentScaleLevel = function() {
    return jQuery('#zoom-slider').slider('value');
  };
  $scope.setCurrentScaleLevel = function(value) {
    jQuery('#zoom-slider').slider('value', value);
  };

  // Container for timeline rendering
  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };
  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };

  angular.element(document).ready(function() {
    // start timeline
    TimelineService.startTimeline($scope.timelineOptions, $scope.getTimelineContainer());
  });
}]);
