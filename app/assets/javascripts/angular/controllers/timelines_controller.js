openprojectApp.controller('TimelinesController', ['$scope', '$window', 'Timeline', function($scope, $window, Timeline) {

  getInitialOutlineExpansion = function(timelineOptions) {
    initialOutlineExpansion = timelineOptions.initial_outline_expansion;
    if (initialOutlineExpansion && initialOutlineExpansion >= 0) {
      return initialOutlineExpansion;
    } else {
      return 0;
    }
  };

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // Setup

  // Get server-side stuff into scope
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelines = gon.timelines;
  $scope.timelineOptions = gon.timeline_options;

  // Get timelines stuff into scope and apply defaults
  $scope.slider = null;
  $scope.underConstruction = true;
  $scope.currentScaleName = 'monthly';

  // Create timeline
  $scope.timeline = Timeline.create($scope.timelineOptions);

  // Set initial expansion index
  $scope.timeline.expansionIndex = getInitialOutlineExpansion($scope.timelineOptions);

  // Provide id for timeline container
  $scope.timelineContainerNo = 1;
  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };

  $scope.$watch('currentScaleName', function(newScaleName, oldScaleName){
    if (newScaleName !== oldScaleName) {
      $scope.currentScale = Timeline.ZOOM_CONFIGURATIONS[$scope.currentScaleName].scale;
      $scope.timeline.scale = $scope.currentScale;

      $scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf($scope.currentScaleName);
      $scope.slider.slider('value', $scope.currentScaleIndex + 1);

      $scope.timeline.zoom($scope.currentScaleIndex); // TODO replace event-driven adaption by bindings
    }
  });

  $scope.$watch('currentOutlineLevel', function(outlineLevel, formerLevel) {
    if (outlineLevel !== formerLevel) {
      $scope.timeline.expansionIndex = Timeline.OUTLINE_LEVELS.indexOf(outlineLevel);
      $scope.timeline.expandToOutlineLevel(outlineLevel); // TODO replace event-driven adaption by bindings
    }
  });

  $scope.increaseZoom = function() {
    if($scope.currentScaleIndex < Object.keys(Timeline.ZOOM_CONFIGURATIONS).length - 1) {
      $scope.currentScaleIndex++;
    }
  };
  $scope.decreaseZoom = function() {
    if($scope.currentScaleIndex > 0) {
      $scope.currentScaleIndex--;
    }
  };

}]);
