timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  $scope.timelineContainerNo = 1; // formerly rand(10**75), TODO increment after each timeline startup

  $scope.timelines = gon.timelines;
  $scope.currentTimelineId = gon.current_timeline_id;

  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };

  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };

  angular.element(document).ready(function () {
    // aggregate timeline options
    $scope.timelineTranslations = gon.timeline_translations;
    $scope.timelineOptions = angular.extend(gon.timeline_options, {
      ui_root: $scope.getTimelineContainer(),
      i18n: $scope.timelineTranslations
    });

    // load timeline
    $scope.timeline = TimelineService.loadTimeline($scope.timelineOptions);
  });
}]);
